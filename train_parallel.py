#
# Copyright (C) 2023, Inria
# GRAPHDECO research group, https://team.inria.fr/graphdeco
# All rights reserved.
#
# This software is free for non-commercial, research and evaluation use 
# under the terms of the LICENSE.md file.
#
# For inquiries contact  george.drettakis@inria.fr
#
import time
import numpy as np
import random
import torch.nn.functional as F

import os
import torch
import torch.multiprocessing as mp
from utils.loss_utils import l1_loss, ssim, l2_loss, compute_normals, compute_structure_tensor, subvolume_structure_loss, subvolume_structure_loss_voxelwise, subvolume_structure_loss_voxelwise_cosine, subvolume_structure_loss_voxelwise_eigenvector
from gaussian_renderer import query#, render, network_gui
import sys
from scene import Scene, GaussianModel
from utils.general_utils import safe_state
from tqdm import tqdm
# from utils.image_utils import psnr
from argparse import ArgumentParser, Namespace
from arguments import ModelParams, PipelineParams, OptimizationParams
from dataset_configs import DATASET_CONFIGS
from utils.train_utils import (
    configure_scan_schedule,
    make_subvolume_centers,
    prepare_output_and_logger,
    write_training_parameters,
)

from prune import prune_list, calculate_v_imp_score, prune_zeros, compute_fa
from query import compute_psnr, compute_psnr_chunked, compute_ssim
import math


def convertscantoiter(opt, args, vx, vy, vz):
    s = opt.subvol_size

    nx = math.ceil(vx / s)
    ny = math.ceil(vy / s)
    nz = math.ceil(vz / s)

    iters_per_scan = nx * ny * nz

    saving_iterations = set()

    log_path = os.path.join(args.model_path, "scan_conversion_log.txt")

    def log_and_print(message):
        print(message)
        with open(log_path, 'a') as f:
            f.write(message + "\n")

    with open(log_path, 'w') as f:
        f.write("===== Scan -> Iter Conversion =====\n")

    log_and_print(f"volume shape : {(vx, vy, vz)}")
    log_and_print(f"subvol size  : {s}")
    log_and_print(f"nx, ny, nz   : {nx}, {ny}, {nz}")
    log_and_print(f"iters/scan   : {iters_per_scan}\n")

    def conv(name, x):
        new_val = int(round(x * iters_per_scan))
        log_and_print(f"{name:25s} : {x} scans -> {new_val} iters")
        return new_val

    opt.iterations = conv("iterations", opt.iterations)
    opt.position_lr_max_steps = conv("position_lr_max_steps", opt.position_lr_max_steps)
    opt.opacity_lr_max_steps = conv("opacity_lr_max_steps", opt.opacity_lr_max_steps)
    opt.scaling_lr_max_steps = conv("scaling_lr_max_steps", opt.scaling_lr_max_steps)
    opt.rotation_lr_max_steps = conv("rotation_lr_max_steps", opt.rotation_lr_max_steps)

    opt.densify_from_iter = conv("densify_from_iter", opt.densify_from_iter)
    opt.densify_until_iter = conv("densify_until_iter", opt.densify_until_iter)
    opt.densification_interval = conv("densification_interval", opt.densification_interval)
    opt.opacity_reset_interval = conv("opacity_reset_interval", opt.opacity_reset_interval)

    saving_iterations.update([
        opt.densify_from_iter,
        (opt.densify_from_iter + opt.densify_until_iter) // 2,
        opt.densify_until_iter,
    ])

    log_and_print("darkpruning_iter:")
    opt.darkpruning_iter = [conv("  darkprune", x) for x in opt.darkpruning_iter]
    saving_iterations.update(opt.darkpruning_iter)

    log_and_print("globalpruning_iter:")
    new_global_iters = []
    for x in opt.globalpruning_iter:
        val = conv("  globalprune", x) + 1
        new_global_iters.append(val)
        saving_iterations.add(val)
        saving_iterations.add(val - 1)
    opt.globalpruning_iter = new_global_iters

    warmup_end = opt.densify_from_iter
    saving_iterations.update([0, warmup_end // 2])

    opt.saving_iterations = sorted([
        i for i in saving_iterations if 0 <= i <= opt.iterations
    ])

    log_and_print(f"\n[Generated Saving Iterations]:\n{opt.saving_iterations}")
    log_and_print("==================================")

    return iters_per_scan


def load_boundary_gaussians(chunk_idx, ix, iy, iz, x_chunks, y_chunks, z_chunks, 
                            chunk_size, x_voxel_size, y_voxel_size, z_voxel_size,
                            x_chunk_size, y_chunk_size, z_chunk_size,
                            max_voxel_size, offset, original_output_dir, dataset, chunk_len):
    """
    인접한 chunk들의 boundary 가우시안을 로드하는 함수
    """
    boundary_xyz_list = []
    boundary_opacity_list = []
    boundary_scaling_list = []
    boundary_rotation_list = []
    
    # 모든 다른 chunk 검사 (자기 자신 제외)
    total_chunks = x_chunks * y_chunks * z_chunks
    for other_chunk_idx in range(total_chunks):
        if other_chunk_idx == chunk_idx:
            continue
            
        # 다른 chunk의 인덱스 계산
        other_ix = other_chunk_idx // (y_chunks * z_chunks)
        other_iy = (other_chunk_idx % (y_chunks * z_chunks)) // z_chunks
        other_iz = other_chunk_idx % z_chunks
        
        # 인접성 확인
        dx = abs(ix - other_ix)
        dy = abs(iy - other_iy)
        dz = abs(iz - other_iz)
        
        is_adjacent = (dx <= 1 and dy <= 1 and dz <= 1) and (dx + dy + dz > 0)
        
        if not is_adjacent:
            continue
            
        # 인접한 축들 결정
        boundary_axes = []
        if dx == 1:
            direction = 'max' if ix > other_ix else 'min'
            boundary_axes.append(('x', direction))
        if dy == 1:
            direction = 'max' if iy > other_iy else 'min'
            boundary_axes.append(('y', direction))
        if dz == 1:
            direction = 'max' if iz > other_iz else 'min'
            boundary_axes.append(('z', direction))
        
        if len(boundary_axes) == 0:
            continue
        
        # PLY 파일 경로 (최신 iteration의 PLY 찾기)
        other_chunk_dir = f'./output/{original_output_dir}_chunk_{other_chunk_idx}/point_cloud'
        if not os.path.exists(other_chunk_dir):
            continue
        
        # 가장 최신 iteration 폴더 찾기
        iter_dirs = [d for d in os.listdir(other_chunk_dir) if d.startswith('iteration_')]
        if len(iter_dirs) == 0:
            continue
        
        latest_iter = max([int(d.split('_')[1]) for d in iter_dirs])
        other_ply_path = f'{other_chunk_dir}/iteration_{latest_iter}/point_cloud.ply'
        
        if not os.path.exists(other_ply_path):
            continue
        
        adjacency_type = 'face' if len(boundary_axes) == 1 else ('edge' if len(boundary_axes) == 2 else 'vertex')
        print(f'  Loading boundary from chunk {other_chunk_idx} (iter {latest_iter}, {adjacency_type} adjacency: {boundary_axes})')
        
        # 가우시안 로드
        other_gaussians = GaussianModel(x_voxel_size, y_voxel_size, z_voxel_size)
        other_gaussians.load_ply(other_ply_path)
        
        if other_gaussians._xyz.shape[0] == 0:
            continue
        
        # 다른 chunk의 offset 계산
        other_chunk_start_x = other_ix * chunk_size[0]
        other_chunk_start_y = other_iy * chunk_size[1]
        other_chunk_start_z = other_iz * chunk_size[2]
        
        other_x_size = min(chunk_size[0], x_voxel_size - other_chunk_start_x)
        other_y_size = min(chunk_size[1], y_voxel_size - other_chunk_start_y)
        other_z_size = min(chunk_size[2], z_voxel_size - other_chunk_start_z)
        
        other_offset = torch.tensor([
            (other_chunk_start_x + other_x_size/2 - x_voxel_size/2) / max_voxel_size * 2.0,
            (other_chunk_start_y + other_y_size/2 - y_voxel_size/2) / max_voxel_size * 2.0,
            (other_chunk_start_z + other_z_size/2 - z_voxel_size/2) / max_voxel_size * 2.0
        ], dtype=torch.float32).cuda()
        
        # 월드 좌표로 변환
        with torch.no_grad():
            other_xyz_world = other_gaussians._xyz - other_offset.unsqueeze(0)
            
            # 경계 가우시안 필터링
            boundary_mask = torch.ones(other_xyz_world.shape[0], dtype=torch.bool, device='cuda')
            boundary_thickness = chunk_len * 0.1
            for axis, direction in boundary_axes:
                if axis == 'x':
                    if direction == 'max':
                        x_max = chunk_len / 2
                        axis_mask = other_xyz_world[:, 0] > (x_max - boundary_thickness)
                    else:
                        x_min = -chunk_len / 2
                        axis_mask = other_xyz_world[:, 0] < (x_min + boundary_thickness)
                elif axis == 'y':
                    y_ratio = other_y_size / other_x_size
                    if direction == 'max':
                        y_max = chunk_len / 2 * y_ratio
                        axis_mask = other_xyz_world[:, 1] > (y_max - boundary_thickness)
                    else:
                        y_min = -chunk_len / 2 * y_ratio
                        axis_mask = other_xyz_world[:, 1] < (y_min + boundary_thickness)
                elif axis == 'z':
                    z_ratio = other_z_size / other_x_size
                    if direction == 'max':
                        z_max = chunk_len / 2 * z_ratio
                        axis_mask = other_xyz_world[:, 2] > (z_max - boundary_thickness)
                    else:
                        z_min = -chunk_len / 2 * z_ratio
                        axis_mask = other_xyz_world[:, 2] < (z_min + boundary_thickness)
                
                boundary_mask = boundary_mask & axis_mask
            
            boundary_xyz = other_xyz_world[boundary_mask]
            
            # 현재 chunk의 로컬 좌표계로 변환
            offset_diff = other_offset - offset
            boundary_xyz = boundary_xyz + offset_diff.unsqueeze(0)
            
            if boundary_xyz.shape[0] > 0:
                boundary_xyz_list.append(boundary_xyz)
                boundary_opacity_list.append(other_gaussians._opacity[boundary_mask])
                boundary_scaling_list.append(other_gaussians._scaling[boundary_mask])
                boundary_rotation_list.append(other_gaussians._rotation[boundary_mask])
    
    # 모든 경계 가우시안 결합
    if len(boundary_xyz_list) > 0:
        boundary_gaussians = GaussianModel(x_chunk_size, y_chunk_size, z_chunk_size)
        boundary_gaussians._xyz = torch.cat(boundary_xyz_list, dim=0)
        boundary_gaussians._opacity = torch.cat(boundary_opacity_list, dim=0)
        boundary_gaussians._scaling = torch.cat(boundary_scaling_list, dim=0)
        boundary_gaussians._rotation = torch.cat(boundary_rotation_list, dim=0)
        
        # requires_grad = False 설정
        for attr in ['_xyz', '_opacity', '_scaling', '_rotation']:
            getattr(boundary_gaussians, attr).requires_grad = False
        
        print(f'  Total boundary gaussians loaded: {boundary_gaussians._xyz.shape[0]}')
        return boundary_gaussians
    
    return None



def train_chunk_worker(gpu_id, chunk_idx, chunk_info, dataset_args, opt_args, pipe_args,
                       cli_args, saving_epochs, checkpoint_epochs, barrier,
                       sync_interval_epochs):
    """
    개별 chunk를 학습하는 워커 프로세스
    
    Args:
        gpu_id: 사용할 GPU ID
        chunk_idx: chunk 인덱스
        chunk_info: chunk 정보 딕셔너리 (gt_vol_chunk, offset, ix, iy, iz 등)
        dataset_args: dataset 파라미터
        opt_args: optimization 파라미터
        pipe_args: pipeline 파라미터
        barrier: 프로세스 간 동기화용 Barrier
        sync_interval_epochs: 동기화 주기 (epoch 단위)
    """
    torch.cuda.set_device(gpu_id)
    
    opt = type('Opt', (), opt_args)()
    pipe = type('Pipe', (), pipe_args)()

    # chunk 정보 추출
    offset = chunk_info['offset'].cuda()
    ix, iy, iz = chunk_info['ix'], chunk_info['iy'], chunk_info['iz']
    
    x_chunks = chunk_info['x_chunks']
    y_chunks = chunk_info['y_chunks']
    z_chunks = chunk_info['z_chunks']
    chunk_size = chunk_info['chunk_size']
    x_voxel_size = chunk_info['x_voxel_size']
    y_voxel_size = chunk_info['y_voxel_size']
    z_voxel_size = chunk_info['z_voxel_size']
    max_voxel_size = chunk_info['max_voxel_size']
    original_output_dir = chunk_info['original_output_dir']
    chunk_len = chunk_info['chunk_len']

    # 각 worker가 필요한 RAW chunk만 memmap에서 직접 읽는다.
    raw_path = chunk_info['raw_path']
    raw_shape = tuple(chunk_info['raw_shape'])
    xs, ys, zs = chunk_info['chunk_start']
    xe, ye, ze = chunk_info['chunk_end']
    dtype = np.uint16 if "uint16" in raw_path else np.uint8
    divisor = 65535.0 if dtype == np.uint16 else 255.0
    gt_vol_mem = np.memmap(raw_path, dtype=dtype, mode='r', shape=raw_shape)
    gt_vol_np = np.asarray(gt_vol_mem[xs:xe, ys:ye, zs:ze], dtype=np.float32) / divisor
    gt_vol_chunk_cpu = torch.from_numpy(gt_vol_np.copy())

    gt_vol_chunk = gt_vol_chunk_cpu.cuda(non_blocking=True)
    x_chunk_size, y_chunk_size, z_chunk_size = gt_vol_chunk.shape
    
    # 데이터셋 설정
    dataset = type('Dataset', (), dataset_args)()
    suffix = f"chunk_{chunk_idx}"
    dataset.output_dir = f"{original_output_dir}_{suffix}"
    
    # train_chunk.py와 동일하게 CLI 값을 opt에 주입하고 scan schedule을
    # iteration 단위로 변환한 뒤 Gaussian을 초기화한다.
    prepare_output_and_logger(dataset)
    args = Namespace(**cli_args)
    subvol_size = args.subvol_size
    scan_log_path = os.path.join(dataset.model_path, "scan_conversion_log.txt")
    itersperscan = configure_scan_schedule(
        opt, args, subvol_size,
        (x_chunk_size, y_chunk_size, z_chunk_size), scan_log_path,
    )

    # Scene 및 Gaussian 초기화
    gaussians = GaussianModel(x_chunk_size, y_chunk_size, z_chunk_size)
    scene = Scene(dataset, gaussians)

    if gaussians._xyz.shape[0] == 0 :
        gaussians.create_random_onthefly(opt.init_num, scene.spatial_lr_scale, chunk_len)
    
    # 로그 파일 설정
    log_path = os.path.join(scene.model_path, "training_log.txt")
    def log(msg):
        with open(log_path, 'a') as f:
            f.write(msg + '\n')
        print(f"[Chunk {chunk_idx}] {msg}")
    
    log(f"Starting on GPU {gpu_id}")
    
    
    gaussians.training_setup(opt)
    
    subvol_centers = make_subvolume_centers(
        (x_chunk_size, y_chunk_size, z_chunk_size), subvol_size
    )
    num_subvols = len(subvol_centers)
    subvol_ptr = 0

    # CLI 입력 스케줄(epochs)도 iteration으로 변환해 병합
    converted_cli_saving = [int(round(float(v) * itersperscan)) for v in saving_epochs]
    converted_cli_checkpoint = [int(round(float(v) * itersperscan)) for v in checkpoint_epochs]

    saving_iterations = set(opt.saving_iterations)
    saving_iterations.update(i for i in converted_cli_saving if 0 <= i <= opt.iterations)
    checkpoint_iterations = set(i for i in converted_cli_checkpoint if 0 <= i <= opt.iterations)
    darkpruning_iterations = set(opt.darkpruning_iter)
    globalpruning_iterations = set(opt.globalpruning_iter)
    sync_interval = max(1, int(round(float(sync_interval_epochs) * itersperscan)))

    log(f"iters per scan: {itersperscan}")
    log(f"total scans: {opt_args.get('iterations')} -> total iters: {opt.iterations}")
    log(f"saving iterations (merged): {sorted(saving_iterations)}")
    log(f"sync interval: {sync_interval_epochs} scans -> {sync_interval} iters")
    
    bg_color = [1, 1, 1] if dataset.white_background else [0, 0, 0]
    background = torch.tensor(bg_color, dtype=torch.float32, device="cuda")
    
    ema_loss_for_log = 0.0
    psnr_log_path = os.path.join(scene.model_path, "psnr_log.txt")
    chunk_coords = [
        (tuple(info[:3]), tuple(info[3:])) for info in chunk_info['all_chunk_ranges']
    ]
    write_training_parameters(
        psnr_log_path, args, opt, chunk_idx, chunk_coords, chunk_size, offset
    )
    with open(psnr_log_path, "a") as f:
        f.write(
            f"{'Iteration':>10} | {'L1':>12} | {'1-SSIM':>12} | "
            f"{'PSNR(dB)':>10} | {'Num Primitives':>14} | {'Time(ms)':>10}\n"
        )
    
    # 초기 boundary 로드 (실패해도 None으로 진행)
    try:
        boundary_gaussians = load_boundary_gaussians(
            chunk_idx, ix, iy, iz, x_chunks, y_chunks, z_chunks,
            chunk_size, x_voxel_size, y_voxel_size, z_voxel_size,
            x_chunk_size, y_chunk_size, z_chunk_size, 
            max_voxel_size, offset, original_output_dir, dataset, chunk_len
        )
    except Exception as e:
        log(f"Warning: Failed to load initial boundary gaussians: {e}")
        boundary_gaussians = None
    
    progress_bar = tqdm(range(1, opt.iterations + 1), desc=f"Chunk {chunk_idx}")
    
    for iteration in range(1, opt.iterations + 1):
        iteration_start = time.time()
        gaussians.update_learning_rate((iteration // itersperscan) * itersperscan)
        
        if iteration == 1:
            gaussians.prune_out_bbox(chunk_len)
        
        # Subvolume 렌더링
        random_x_int, random_y_int, random_z_int = subvol_centers[subvol_ptr]
        subvol_size_half = subvol_size // 2
        
        gt_subvol = gt_vol_chunk[
            random_x_int-subvol_size_half:random_x_int+subvol_size_half,
            random_y_int-subvol_size_half:random_y_int+subvol_size_half,
            random_z_int-subvol_size_half:random_z_int+subvol_size_half
        ]
        
        x_normalized = torch.linspace(
            -chunk_len / 2,
            chunk_len / 2 - 2 / x_chunk_size,
            steps=x_chunk_size,
        )
        y_normalized = x_normalized[(x_chunk_size-y_chunk_size)//2 : (x_chunk_size-y_chunk_size)//2+y_chunk_size]
        z_normalized = x_normalized[(x_chunk_size-z_chunk_size)//2 : (x_chunk_size-z_chunk_size)//2+z_chunk_size]
        
        random_x = x_normalized[random_x_int]
        random_y = y_normalized[random_y_int]
        random_z = z_normalized[random_z_int]
        
        if subvol_size >= z_chunk_size:
            tv_vol_nVoxel = torch.tensor([subvol_size, subvol_size, 70])
        else:
            tv_vol_nVoxel = torch.tensor([subvol_size, subvol_size, subvol_size])
        tv_vol_sVoxel = torch.tensor(chunk_len/x_chunk_size) * tv_vol_nVoxel
        tv_vol_center = (random_x, random_y, random_z)
        
        query_pkg = query(
            gaussians,
            tv_vol_center,
            tv_vol_nVoxel,
            tv_vol_sVoxel,
            pipe,
            ghost_pc=boundary_gaussians
        )
        vol_pred, viewspace_point_tensor, visibility_filter, radii = (
            query_pkg["vol"], query_pkg["3d_mean"], 
            query_pkg["visibility_filter"], query_pkg["radii"]
        )
        
        subvol_ptr = (subvol_ptr + 1) % num_subvols
        
        Ll1 = l1_loss(vol_pred, gt_subvol)
        Lssim = ssim(vol_pred, gt_subvol)
        loss = (1.0 - opt.lambda_dssim) * Ll1 + opt.lambda_dssim * (1.0 - Lssim)
        loss.backward()
        
        with torch.no_grad():
            if iteration < opt.densify_until_iter:
                gaussians.max_radii2D[visibility_filter] = torch.max(gaussians.max_radii2D[visibility_filter], radii[visibility_filter])
                gaussians.add_densification_stats(viewspace_point_tensor, visibility_filter)
                

            if iteration % 100 == 0:
                torch.cuda.empty_cache()
            
            # Pruning
            if iteration in darkpruning_iterations:
                prune_zeros(gaussians, scene, pipe, background, x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)
                gaussians.prune_dark_gaussians()

            if iteration in globalpruning_iterations:
                prune_zeros(gaussians, scene, pipe, background, x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)
                gaussians.prune_dark_gaussians()
                _, imp_list, voxel_count = prune_list(gaussians, scene, pipe, background, 
                                                      x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)
                FA = compute_fa(gaussians.get_scaling)
                gaussians.prune_gaussians(opt.pruning_remainweight, imp_list * FA)
            
            # Progress bar
            ema_loss_for_log = 0.4 * loss.item() + 0.6 * ema_loss_for_log
            if iteration % 1000 == 0:
                progress_bar.set_postfix({"Loss": f"{ema_loss_for_log:.{7}f}"})
                progress_bar.update(1000)
            
            # 동기화 포인트: sync_interval마다 PLY 저장 후 대기
            if iteration % sync_interval == 0:
                log(f"Iter {iteration}: Saving PLY and syncing...")
                scene.save(iteration, offset)
                
                # 모든 프로세스 대기 (timeout 30초)
                try:
                    barrier.wait(timeout=30)
                    log(f"Iter {iteration}: Sync complete, reloading boundaries...")
                    
                    # 최신 boundary 재로드 (실패해도 None으로 진행)
                    try:
                        boundary_gaussians = load_boundary_gaussians(
                            chunk_idx, ix, iy, iz, x_chunks, y_chunks, z_chunks,
                            chunk_size, x_voxel_size, y_voxel_size, z_voxel_size,
                            x_chunk_size, y_chunk_size, z_chunk_size,
                            max_voxel_size, offset, original_output_dir, dataset, chunk_len
                        )
                    except Exception as e:
                        log(f"Warning: Failed to reload boundary gaussians: {e}")
                        boundary_gaussians = None
                    
                    # 2차 barrier: 모든 프로세스가 boundary 로드 완료할 때까지 대기
                    barrier.wait(timeout=30)
                except Exception as e:
                    log(f"Warning: Barrier timeout or error at iter {iteration}: {e}")
                    log(f"Continuing without boundary sync...")
                    boundary_gaussians = None
            
            # 저장
            if iteration in saving_iterations:
                log(f"Saving at iteration {iteration}")
                scene.save(iteration, offset)

                torch.save((gaussians.capture(), iteration), 
                          scene.model_path + f"/chkpnt{iteration}.pth")
                
                # Full volume 렌더링 및 PSNR 계산
                try:
                    # 메모리 확보: 캐시만 비우기 (gradient는 유지)
                    torch.cuda.empty_cache()
                    
                    # full_vol = query(
                    #     gaussians,
                    #     [0, 0, 0],
                    #     [x_chunk_size, y_chunk_size, z_chunk_size],
                    #     [0.5, y_chunk_size/x_chunk_size * 0.5, z_chunk_size/x_chunk_size * 0.5],
                    #     pipe,
                    #     use_step_function=True,
                    #     ghost_pc=boundary_gaussians
                    # )['vol']
                    
                    # full_vol = torch.clip(full_vol, min=0.0, max=1.0)
                    # psnr_vol = compute_psnr(full_vol, gt_vol_chunk)
                    
                    psnr_vol = compute_psnr_chunked(
                        gaussians=gaussians,
                        gt_vol=gt_vol_chunk.detach().cpu(),
                        x_voxel_size=x_chunk_size,  # 현재 chunk 크기
                        y_voxel_size=y_chunk_size,  # 현재 chunk 크기
                        z_voxel_size=z_chunk_size,  # 현재 chunk 크기
                        pipe=pipe,
                        chunk_size=512,
                        spatial_extent=chunk_len,
                        ghost_pc=boundary_gaussians
                    )

                    log(f"PSNR: {psnr_vol:.4f}, Num Gaussians: {gaussians.get_xyz.shape[0]}")
                    
                    with open(psnr_log_path, "a") as f:
                        elapsed_ms = (time.time() - iteration_start) * 1000.0
                        f.write(
                            f"{iteration:>10d} | {Ll1.item():>12.6f} | "
                            f"{1 - Lssim.item():>12.6f} | {psnr_vol:>10.2f} | "
                            f"{gaussians.get_xyz.shape[0]:>14d} | {elapsed_ms:>10.2f}\n"
                        )
                    
                    # del full_vol
                    torch.cuda.empty_cache()
                    
                except Exception as e:
                    log(f"Warning: Failed to compute PSNR at iter {iteration}: {e}")
            
            # Densification (gradient 사용 - zero_grad 전에 실행)

            if iteration >= opt.densify_from_iter and iteration % opt.densification_interval == 0:
                size_threshold = 20 if iteration > opt.opacity_reset_interval else None
                gaussians.densify_and_prune(
                    opt.densify_grad_threshold, 1/255, chunk_len, 
                    size_threshold, None, iteration, chunk_len
                )
                
                if iteration % opt.opacity_reset_interval == 0 or \
                   (dataset.white_background and iteration == opt.densify_from_iter):
                    gaussians.reset_opacity()
            
            # Optimizer step (gradient 사용 후 zero_grad)
            if iteration < opt.iterations:
                gaussians.optimizer.step()
                gaussians.optimizer.zero_grad(set_to_none=True)
            
            if iteration in checkpoint_iterations:
                torch.save((gaussians.capture(), iteration), 
                          scene.model_path + f"/chkpnt{iteration}.pth")
    
    progress_bar.close()
    log(f"Training complete! Total gaussians: {gaussians.get_xyz.shape[0]}")
    



def training(dataset, opt, pipe, saving_iterations, checkpoint_iterations,
             dataset_name, batch_size, sync_interval, cli_args):
    """
    병렬 학습 메인 함수: 4개 chunk씩 배치로 병렬 학습
    """
    start_time_total = time.time()
    
    if dataset_name not in DATASET_CONFIGS:
        raise ValueError(f"Unknown dataset: {dataset_name}")
    config = DATASET_CONFIGS[dataset_name]
    if config.get("training_mode") != "chunk_parallel":
        raise ValueError(
            f"train_parallel.py requires training_mode='chunk_parallel', "
            f"but {dataset_name!r} uses {config.get('training_mode')!r}."
        )
    if config.get("use_tif"):
        raise ValueError("Parallel on-demand loading currently supports RAW datasets only.")

    path = config["path"]
    raw_shape = tuple(config.get("raw_shape", (
        config["x_voxel_size"], config["y_voxel_size"], config["z_voxel_size"]
    )))
    if config.get("transpose"):
        raise ValueError("Parallel RAW datasets must be configured in final XYZ order.")
    x_voxel_size = config["x_voxel_size"]
    y_voxel_size = config["y_voxel_size"]
    z_voxel_size = config["z_voxel_size"]
    chunk_size = tuple(config["chunk_size"])
    chunk_len = config["chunk_len"]
    original_output_dir = dataset.output_dir

    print(f"\n{'='*60}")
    print(f"Dataset: {dataset_name}")
    print("Training mode: chunk_parallel")
    print(f"Volume Path: {path}")
    print(f"Volume size: {x_voxel_size}x{y_voxel_size}x{z_voxel_size}")
    print(f"Chunk size: {chunk_size}")
    print(f"GPU batch size: {batch_size}")
    print(f"{'='*60}\n")

    # 전체 볼륨을 메모리에 올리지 않고 memmap으로 접근
    # path = './data/hemibrain_body_em_id1701947337_bbox_4096x4096x4096.raw'
    # d = np.fromfile(path, dtype=np.uint8)
    # gt_vol_full = d.reshape((4096, 4096, 4096)).transpose(2, 1, 0)
    # gt_vol_full = torch.from_numpy(gt_vol_full.astype(np.float32) / 255.0)  # CPU 텐서로 유지

    # path = './data/hemibrain_label_em_vDeltaH_n17_mip2_3614x4233x3564.raw'
    # d = np.fromfile(path, dtype=np.uint8)
    # # 원본: (3614, 4233, 3564) → transpose(1, 0, 2) → (4233, 3614, 3564)
    # # 가장 큰 차원 4233이 x축에 오도록 y와 x를 swap
    # gt_vol_full = d.reshape((3564, 4233, 3614)).transpose(2,1,0) # (3614, 4233, 3564) -> (4233, 3614, 3564)
    # gt_vol_full = gt_vol_full.transpose(1, 0, 2)
    # gt_vol_full = torch.from_numpy(gt_vol_full.astype(np.float32) / 255.0)  # CPU 텐서로 유지
    

    # path = './data/vis/hemibrain_vDeltaA_n85_mip2_4072x4372x4171.raw' # 4372 4072 4171
    # d = np.fromfile(path, dtype=np.uint8)
    # # 가장 큰 차원 4372이 x축에 오도록 y와 x를 swap
    # gt_vol_full = d.reshape((4171, 4372, 4072)).transpose(2,1,0) 
    # gt_vol_full = gt_vol_full.transpose(1, 0, 2)# (4072, 4372, 4171) -> (4372 4072 4171)
    # gt_vol_full = torch.from_numpy(gt_vol_full.astype(np.float32) / 255.0)  # CPU 텐서로 유지


    print("\n=== Training Parameters ===")
    print(f"densify_grad_threshold: {opt.densify_grad_threshold:.10f}" if hasattr(opt, 'densify_grad_threshold') else 'N/A')
    print(f"scaling_lr_init: {opt.scaling_lr_init:.10f}")
    print(f"scaling_lr_final: {opt.scaling_lr_final:.10f}")
    print(f"percent_dense: {opt.percent_dense:.6f}")
    print(f"iterations: {opt.iterations}")
    print("===========================\n")
    
    # Chunk 나누기
    # chunk_size = (1024, 1024, 1024)
    # chunks = []
    # chunk_len = 0.5
    # chunk_size = (1059, 904, 891) # hemibrain vDeltaH mip2
    # chunk_size = (1093, 1018, 1043) # hemibrain vDeltaA mip2
    # chunk_size = (1532, 1194, 1279) # hemibrain lLN2P chunk len 0.5
    chunk_ranges = []
    
    for x in range(0, x_voxel_size, chunk_size[0]):
        for y in range(0, y_voxel_size, chunk_size[1]):
            for z in range(0, z_voxel_size, chunk_size[2]):
                x_end = min(x + chunk_size[0], x_voxel_size)
                y_end = min(y + chunk_size[1], y_voxel_size)
                z_end = min(z + chunk_size[2], z_voxel_size)
                
                chunk_ranges.append((x, y, z, x_end, y_end, z_end))
    
    print(f"원본 볼륨 크기: {raw_shape}")
    print(f"각 chunk 크기: {chunk_size}")
    print(f"총 chunk 개수: {len(chunk_ranges)}")
    print("데이터 로드 방식: np.memmap (worker별 청크 on-demand 로드)")
    
    x_chunks = (x_voxel_size + chunk_size[0] - 1) // chunk_size[0]
    y_chunks = (y_voxel_size + chunk_size[1] - 1) // chunk_size[1]
    z_chunks = (z_voxel_size + chunk_size[2] - 1) // chunk_size[2]
    max_voxel_size = max(x_voxel_size, y_voxel_size, z_voxel_size)
    
    # Dataset, opt, pipe를 딕셔너리로 변환
    dataset_args = vars(dataset)
    opt_args = vars(opt)
    pipe_args = vars(pipe)
    
    # 멀티프로세싱 설정 (한 번만 실행)
    try:
        mp.set_start_method('spawn')
    except RuntimeError:
        pass  # 이미 설정된 경우 무시
    
    # 병렬 학습: 기본은 GPU 수만큼 (대형 청크에서 GPU 과구독 방지)
    num_gpus = torch.cuda.device_count()
    if num_gpus == 0:
        raise RuntimeError("No CUDA GPU is available for parallel training.")
    batch_size = min(batch_size, num_gpus)
    print(f"\n사용 가능한 GPU: {num_gpus}개")
    print(f"배치 크기: {batch_size}")
    
    for batch_start in range(0, len(chunk_ranges), batch_size):
        batch_end = min(batch_start + batch_size, len(chunk_ranges))
        batch_chunks = list(range(batch_start, batch_end))
        
        print(f"\n{'='*60}")
        print(f"배치 학습: Chunks {batch_start} ~ {batch_end-1} ({len(batch_chunks)}개)")
        print(f"{'='*60}\n")
        
        # Barrier 생성 (배치 내 프로세스 개수에 맞춤)
        barrier = mp.Barrier(len(batch_chunks))
        
        processes = []
        
        for i, chunk_idx in enumerate(batch_chunks):
            x, y, z, x_end, y_end, z_end = chunk_ranges[chunk_idx]
            
            # Chunk 인덱스 계산
            ix = chunk_idx // (y_chunks * z_chunks)
            iy = (chunk_idx % (y_chunks * z_chunks)) // z_chunks
            iz = chunk_idx % z_chunks
            
            # Chunk 크기 및 offset 계산
            x_chunk_size = x_end - x
            y_chunk_size = y_end - y
            z_chunk_size = z_end - z
            
            chunk_start_x = ix * chunk_size[0]
            chunk_start_y = iy * chunk_size[1]
            chunk_start_z = iz * chunk_size[2]
            
            offset = torch.tensor([
                (chunk_start_x + x_chunk_size/2 - x_voxel_size/2) / max_voxel_size * 2.0,
                (chunk_start_y + y_chunk_size/2 - y_voxel_size/2) / max_voxel_size * 2.0,
                (chunk_start_z + z_chunk_size/2 - z_voxel_size/2) / max_voxel_size * 2.0
            ], dtype=torch.float32)
            
            # Chunk 정보 패키징
            chunk_info = {
                'raw_path': path,
                'raw_shape': raw_shape,
                'chunk_start': (x, y, z),
                'chunk_end': (x_end, y_end, z_end),
                'offset': offset,
                'ix': ix, 'iy': iy, 'iz': iz,
                'x_chunks': x_chunks,
                'y_chunks': y_chunks,
                'z_chunks': z_chunks,
                'chunk_size': chunk_size,
                'x_voxel_size': x_voxel_size,
                'y_voxel_size': y_voxel_size,
                'z_voxel_size': z_voxel_size,
                'max_voxel_size': max_voxel_size,
                'original_output_dir': original_output_dir,
                'chunk_len': chunk_len
                ,'all_chunk_ranges': chunk_ranges
            }
            
            # GPU 할당 (순환)
            gpu_id = i % num_gpus
            
            # 프로세스 생성
            p = mp.Process(
                    target=train_chunk_worker,
                    args=(gpu_id, chunk_idx, chunk_info, dataset_args, opt_args, pipe_args,
                        cli_args, saving_iterations, checkpoint_iterations, barrier,
                        sync_interval)
            )
            p.start()
            processes.append(p)
        
        # 모든 프로세스 완료 대기
        for p in processes:
            p.join()
        failed = [p.exitcode for p in processes if p.exitcode != 0]
        if failed:
            raise RuntimeError(f"Parallel batch {batch_start}-{batch_end-1} failed: {failed}")
        
        print(f"\n배치 {batch_start}~{batch_end-1} 완료!\n")
    
    total_time = time.time() - start_time_total
    print(f"\n{'='*60}")
    print(f"전체 학습 완료!")
    print(f"총 소요 시간: {total_time/60:.2f}분 ({total_time:.1f}초)")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    parser = ArgumentParser(description="Training script parameters")
    lp = ModelParams(parser)
    op = OptimizationParams(parser)
    pp = PipelineParams(parser)
    parser.add_argument('--debug_from', type=int, default=-1)
    parser.add_argument('--detect_anomaly', action='store_true', default=False)
    parser.add_argument("--save_iterations", nargs="+", type=int, default=[])
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--checkpoint_iterations", nargs="+", type=int, default=[])
    parser.add_argument("--start_checkpoint", type=str, default = None)
    supported_datasets = sorted(
        name for name, config in DATASET_CONFIGS.items()
        if config.get("training_mode") == "chunk_parallel"
    )
    parser.add_argument("--dataset_name", required=True, choices=supported_datasets)
    parser.add_argument("--subvol_size", type=int, default=64)
    parser.add_argument("--init_num", type=int, default=100_000)
    parser.add_argument("--pruning_remainweight", type=float, default=0.66)
    parser.add_argument("--darkpruning_iter", nargs="+", type=int, default=[1, 2, 3])
    parser.add_argument("--globalpruning_iter", nargs="+", type=int, default=[1, 2, 3])
    parser.add_argument("--batch_size", type=int, default=None,
                        help="Concurrent chunks (default: number of GPUs)")
    parser.add_argument("--sync_interval", type=float, default=100,
                        help="Boundary synchronization interval in scans")

    args = parser.parse_args(sys.argv[1:])
    args.training_script = "train_parallel.sh"
    args.save_iterations.append(args.iterations)
    if args.batch_size is None:
        args.batch_size = max(1, torch.cuda.device_count())
    print("Optimizing " + args.model_path + "\n")
    safe_state(args.quiet)
    torch.autograd.set_detect_anomaly(args.detect_anomaly)
    training(
        lp.extract(args), op.extract(args), pp.extract(args),
        args.save_iterations, args.checkpoint_iterations,
        args.dataset_name, args.batch_size, args.sync_interval, vars(args),
    )
    print("\nTraining complete.")
