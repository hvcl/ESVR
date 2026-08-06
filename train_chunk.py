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

import os
import torch
from utils.loss_utils import l1_loss, ssim
from gaussian_renderer import query
import sys
from scene import Scene, GaussianModel
from utils.general_utils import safe_state
from tqdm import tqdm
from argparse import ArgumentParser
from arguments import ModelParams, PipelineParams, OptimizationParams
from dataset_configs import DATASET_CONFIGS

from prune import prune_list, prune_zeros, compute_fa
from query import compute_psnr, compute_psnr_chunked, compute_ssim_3d
import math
from utils.train_utils import (
    configure_scan_schedule,
    load_volume_chunk,
    make_subvolume_centers,
    prepare_output_and_logger,
    write_training_parameters,
)

def training(dataset, opt, pipe, checkpoint, debug_from, chunk_idx, dataset_name, subvol_size):
    if dataset_name not in DATASET_CONFIGS:
        raise ValueError(f"Unknown dataset: {dataset_name}. Available: {list(DATASET_CONFIGS.keys())}")
    
    config = DATASET_CONFIGS[dataset_name]
    training_mode = config.get("training_mode")
    if training_mode not in {"full", "chunk_sequential"}:
        raise ValueError(
            f"train_chunk.py supports 'full' and 'chunk_sequential', "
            f"but {dataset_name!r} uses {training_mode!r}."
        )
    path = config["path"]
    x_voxel_size = config["x_voxel_size"]
    y_voxel_size = config["y_voxel_size"]
    z_voxel_size = config["z_voxel_size"]
    use_tif = config["use_tif"]
    if training_mode == "full":
        # Full-volume training is represented as exactly one chunk.
        chunk_size = (x_voxel_size, y_voxel_size, z_voxel_size)
        chunk_len = 2.0
    else:
        chunk_size = tuple(config["chunk_size"])
        chunk_len = config["chunk_len"]
    subvol_size = subvol_size
    
    print(f"\n{'='*60}")
    print(f"Dataset: {dataset_name}")
    print(f"Training mode: {training_mode}")
    print(f"Volume Path: {path}")
    print(f"Volume size: {x_voxel_size}x{y_voxel_size}x{z_voxel_size}")
    print(f"Chunk size: {chunk_size}")
    print(f"Format: {'TIF' if use_tif else 'RAW'}")
    print(f"{'='*60}\n")
    
    ##########################################################################


    original_output_dir = dataset.output_dir

    # ===(1) chunk 나누기 ===
    
    # 청크 좌표만 저장 (데이터는 나중에 로드) : OOM 방지 위해 필요한 gt chunk만 로드
    chunk_coords = []
    for x in range(0, x_voxel_size, chunk_size[0]):
        for y in range(0, y_voxel_size, chunk_size[1]):
            for z in range(0, z_voxel_size, chunk_size[2]):
                x_end = min(x + chunk_size[0], x_voxel_size)
                y_end = min(y + chunk_size[1], y_voxel_size)
                z_end = min(z + chunk_size[2], z_voxel_size)
                chunk_coords.append(((x, y, z), (x_end, y_end, z_end)))
    
    print(f"원본 볼륨 크기: {x_voxel_size}x{y_voxel_size}x{z_voxel_size}")
    print(f"각 chunk 크기: {chunk_size}")
    print(f"총 chunk 개수: {len(chunk_coords)}")
    
    # chunk_idx 검증
    if chunk_idx < 0 or chunk_idx >= len(chunk_coords):
        raise ValueError(f"chunk_idx {chunk_idx} is out of range [0, {len(chunk_coords)-1}]")
    # =======================

    (x_start, y_start, z_start), (x_end, y_end, z_end) = chunk_coords[chunk_idx]

    # Resolve the chunk output directory before creating any log files.
    suffix = f"chunk_{chunk_idx}"
    dataset.output_dir = f"{original_output_dir}_{suffix}"
    print(f"Modified output dir for chunk {chunk_idx}: {dataset.output_dir}")
    prepare_output_and_logger(dataset)

    scan_log_path = os.path.join(dataset.model_path, "scan_conversion_log.txt")
    print("scan conversion log path:", scan_log_path)

    # Convert scan(epoch)-based schedule to iteration units for this chunk volume.
    chunk_vx = x_end - x_start
    chunk_vy = y_end - y_start
    chunk_vz = z_end - z_start

    iters_per_scan = configure_scan_schedule(
        opt,
        args,
        subvol_size,
        (chunk_vx, chunk_vy, chunk_vz),
        scan_log_path,
    )

    start_time_total = time.time()  

    # load only current training chunk
    print(f"\n{'='*60}")
    print(f"Processing chunk {chunk_idx}/{len(chunk_coords)}")
    gt_vol_chunk = load_volume_chunk(config, chunk_coords[chunk_idx])
    x_chunk_size, y_chunk_size, z_chunk_size = gt_vol_chunk.shape
    # ==========================================


    subvol_centers = make_subvolume_centers(
        (x_chunk_size, y_chunk_size, z_chunk_size), subvol_size
    )
    num_subvols = len(subvol_centers)
    print("Total subvols:", num_subvols)

    subvol_ptr = 0
    # ================================================================

    # Chunk offset 계산 (3D chunking 지원)
    # 각 chunk의 시작 좌표를 [-1, 1] 정규화된 좌표계로 변환
    # 해상도 비율을 고려하여 offset 계산
    x_chunks = (x_voxel_size + chunk_size[0] - 1) // chunk_size[0]  # x축 chunk 개수
    y_chunks = (y_voxel_size + chunk_size[1] - 1) // chunk_size[1]  # y축 chunk 개수
    z_chunks = (z_voxel_size + chunk_size[2] - 1) // chunk_size[2]  # z축 chunk 개수
    
    # chunk_idx로부터 (ix, iy, iz) 인덱스 복원
    ix = chunk_idx // (y_chunks * z_chunks)
    iy = (chunk_idx % (y_chunks * z_chunks)) // z_chunks
    iz = chunk_idx % z_chunks
    
    # 각 chunk의 월드 좌표 시작점 (voxel 단위)
    chunk_start_x = ix * chunk_size[0]
    chunk_start_y = iy * chunk_size[1]
    chunk_start_z = iz * chunk_size[2]
    
    # 전체 볼륨의 최대 해상도를 기준으로 정규화
    # 좌표 범위: [-1, 1]을 최대 해상도 축에 맞춤
    max_voxel_size = max(x_voxel_size, y_voxel_size, z_voxel_size)
    
    # 각 축의 chunk 중심을 계산하고, 최대 해상도 기준으로 정규화 ([-1, 1] 범위)
    offset = torch.tensor([
        (chunk_start_x + x_chunk_size/2 - x_voxel_size/2) / max_voxel_size * 2.0,
        (chunk_start_y + y_chunk_size/2 - y_voxel_size/2) / max_voxel_size * 2.0,
        (chunk_start_z + z_chunk_size/2 - z_voxel_size/2) / max_voxel_size * 2.0
    ], dtype=torch.float32).cuda()
    
    print(f"Offset for chunk {chunk_idx} (ix={ix}, iy={iy}, iz={iz}): {offset.cpu().numpy()}")
    # ================================================================

    
    first_iter = 0
    gaussians = GaussianModel(x_chunk_size, y_chunk_size, z_chunk_size)
    scene = Scene(dataset, gaussians)
    if gaussians._xyz.shape[0] == 0 :
        gaussians.create_random_onthefly(opt.init_num, scene.spatial_lr_scale, chunk_len)

    gaussians.training_setup(opt)

    psnr_log_path = os.path.join(scene.model_path, "psnr_log.txt")
    print("training log path:", psnr_log_path)
    write_training_parameters(
        psnr_log_path,
        args,
        opt,
        chunk_idx,
        chunk_coords,
        chunk_size,
        offset,
    )
    with open(psnr_log_path, "a") as f:
        f.write(
            f"{'Iteration':>10} | "
            f"{'L1':>12} | "
            f"{'1-SSIM':>12} | "
            f"{'PSNR(dB)':>10} | "
            f"{'Num Primitives':>14} | "
            f"{'Time(ms)':>10}\n"
        )

    ######################################################################################################
    # Ghost cell: 이전 학습된 chunk들의 경계 가우시안 로드
    boundary_gaussians = None
    num_boundary = 0
    
    if chunk_idx > 0:
        # 현재 chunk와 인접한 이전 chunk들 찾기
        boundary_xyz_list = []
        boundary_opacity_list = []
        boundary_scaling_list = []
        boundary_rotation_list = []
        
        for prev_chunk_idx in range(chunk_idx):
            # 이전 chunk의 인덱스 계산
            prev_ix = prev_chunk_idx // (y_chunks * z_chunks)
            prev_iy = (prev_chunk_idx % (y_chunks * z_chunks)) // z_chunks
            prev_iz = prev_chunk_idx % z_chunks
            
            # 현재 chunk와 인접한지 확인 (면/모서리/꼭짓점 인접 체크)
            dx = abs(ix - prev_ix)
            dy = abs(iy - prev_iy)
            dz = abs(iz - prev_iz)
            
            # 인접 조건: 각 축에서 최대 1칸 차이 & 적어도 하나의 축에서 차이가 있어야 함
            is_adjacent = (dx <= 1 and dy <= 1 and dz <= 1) and (dx + dy + dz > 0)
            
            # 인접한 축들과 방향 결정 (리스트로 관리)
            boundary_axes = []
            
            if dx == 1:
                direction = 'max' if ix > prev_ix else 'min'
                boundary_axes.append(('x', direction))
            if dy == 1:
                direction = 'max' if iy > prev_iy else 'min'
                boundary_axes.append(('y', direction))
            if dz == 1:
                direction = 'max' if iz > prev_iz else 'min'
                boundary_axes.append(('z', direction))
            
            if is_adjacent and len(boundary_axes) > 0:
                # 이전 chunk의 PLY 파일 로드
                prev_ply_path = f'./output/{original_output_dir}_chunk_{prev_chunk_idx}/point_cloud/iteration_{opt.iterations}/point_cloud.ply'
                if os.path.exists(prev_ply_path):
                    adjacency_type = 'face' if len(boundary_axes) == 1 else ('edge' if len(boundary_axes) == 2 else 'vertex')
                    print(f'Loading boundary from chunk {prev_chunk_idx} ({adjacency_type} adjacency: {boundary_axes})')
                    
                    prev_gaussians = GaussianModel(x_voxel_size, y_voxel_size, z_voxel_size)
                    prev_gaussians.load_ply(prev_ply_path)
                    
                    # 이전 chunk의 offset 계산
                    prev_chunk_start_x = prev_ix * chunk_size[0]
                    prev_chunk_start_y = prev_iy * chunk_size[1]
                    prev_chunk_start_z = prev_iz * chunk_size[2]
                    
                    prev_x_size = min(chunk_size[0], x_voxel_size - prev_chunk_start_x)
                    prev_y_size = min(chunk_size[1], y_voxel_size - prev_chunk_start_y)
                    prev_z_size = min(chunk_size[2], z_voxel_size - prev_chunk_start_z)
                    
                    prev_offset = torch.tensor([
                        (prev_chunk_start_x + prev_x_size/2 - x_voxel_size/2) / max_voxel_size * 2.0,
                        (prev_chunk_start_y + prev_y_size/2 - y_voxel_size/2) / max_voxel_size * 2.0,
                        (prev_chunk_start_z + prev_z_size/2 - z_voxel_size/2) / max_voxel_size * 2.0
                    ], dtype=torch.float32).cuda()
                    
                    # 좌표를 현재 chunk의 로컬 좌표계로 변환
                    with torch.no_grad():
                        # 월드 좌표로 변환 (offset 제거)
                        prev_xyz_world = prev_gaussians._xyz - prev_offset.unsqueeze(0)
                        min_prev = prev_xyz_world.min(dim=0)[0]
                        max_prev = prev_xyz_world.max(dim=0)[0]
                        print(f'Prev chunk x min/max: {min_prev[0].item():.3f}/{max_prev[0].item():.3f}')
                        print(f'Prev chunk y min/max: {min_prev[1].item():.3f}/{max_prev[1].item():.3f}')
                        print(f'Prev chunk z min/max: {min_prev[2].item():.3f}/{max_prev[2].item():.3f}')

                        
                        # 경계 가우시안 필터링 (경계 두께: 0.1 단위)
                        # boundary_thickness = 0.1
                        boundary_thickness = chunk_len * 0.1
                        boundary_mask = torch.ones(prev_xyz_world.shape[0], dtype=torch.bool, device='cuda')
                        
                        # 각 축에 대해 경계 조건을 AND 연산으로 결합
                        for axis, direction in boundary_axes:
                            if axis == 'x':
                                if direction == 'max':
                                    x_max = 0.5 * chunk_len
                                    axis_mask = prev_xyz_world[:, 0] > (x_max - boundary_thickness)
                                    print(f'x_max: {x_max}')
                                else:  # min
                                    x_min = -0.5 * chunk_len
                                    axis_mask = prev_xyz_world[:, 0] < (x_min + boundary_thickness)
                                    print(f'x_min: {x_min}')
                            elif axis == 'y':
                                y_ratio = prev_y_size / prev_x_size
                                if direction == 'max':
                                    y_max = 0.5 * chunk_len * y_ratio
                                    axis_mask = prev_xyz_world[:, 1] > (y_max - boundary_thickness)
                                    print(f'y_max: {y_max}')
                                else:
                                    y_min = -0.5 * chunk_len * y_ratio
                                    axis_mask = prev_xyz_world[:, 1] < (y_min + boundary_thickness)
                                    print(f'y_min: {y_min}')
                            elif axis == 'z':
                                z_ratio = prev_z_size / prev_x_size
                                if direction == 'max':
                                    z_max = 0.5 * chunk_len * z_ratio
                                    axis_mask = prev_xyz_world[:, 2] > (z_max - boundary_thickness)
                                    print(f'z_max: {z_max}')
                                else:
                                    z_min = -0.5 * chunk_len * z_ratio
                                    axis_mask = prev_xyz_world[:, 2] < (z_min + boundary_thickness)
                                    print(f'z_min: {z_min}')
                            
                            # AND 연산으로 경계 마스크 결합
                            boundary_mask = boundary_mask & axis_mask

                        # 경계 가우시안만 추출
                        boundary_xyz = prev_xyz_world[boundary_mask]
                        
                        # 현재 chunk의 로컬 좌표계로 변환
                        offset_diff = prev_offset - offset
                        boundary_xyz = boundary_xyz + offset_diff.unsqueeze(0)
                        
                        print(f'  Found {boundary_xyz.shape[0]} boundary gaussians from chunk {prev_chunk_idx}')
                        
                        if boundary_xyz.shape[0] > 0:
                            # .clone()으로 복사하여 원본과 메모리 연결 끊기
                            boundary_xyz_list.append(boundary_xyz.clone())
                            boundary_opacity_list.append(prev_gaussians._opacity[boundary_mask].clone())
                            boundary_scaling_list.append(prev_gaussians._scaling[boundary_mask].clone())
                            boundary_rotation_list.append(prev_gaussians._rotation[boundary_mask].clone())
                    
                    # 이전 chunk의 gaussians 삭제 (메모리 절약)
                    del prev_gaussians
                    del prev_offset
                    torch.cuda.empty_cache()
        
        # collect all boundary (ghost) ellipsoids
        if len(boundary_xyz_list) > 0:
            boundary_gaussians = GaussianModel(x_chunk_size, y_chunk_size, z_chunk_size)
            boundary_gaussians._xyz = torch.cat(boundary_xyz_list, dim=0)
            boundary_gaussians._opacity = torch.cat(boundary_opacity_list, dim=0)
            boundary_gaussians._scaling = torch.cat(boundary_scaling_list, dim=0)
            boundary_gaussians._rotation = torch.cat(boundary_rotation_list, dim=0)
            num_boundary = boundary_gaussians._xyz.shape[0]
            
            # requires_grad = False 설정
            for attr in ['_xyz', '_opacity', '_scaling', '_rotation']:
                getattr(boundary_gaussians, attr).requires_grad = False
            
            print(f'Total boundary ellipsoids for chunk {chunk_idx}: {num_boundary}')
    
    # ######################################################################################################
    # 다음 chunk를 위해 원본 경로로 복원
    dataset.output_dir = original_output_dir

    if checkpoint:
        (model_params, first_iter) = torch.load(checkpoint)
        gaussians.restore(model_params, opt)

    bg_color = [1, 1, 1] if dataset.white_background else [0, 0, 0]
    background = torch.tensor(bg_color, dtype=torch.float32, device="cuda")

    iter_start = torch.cuda.Event(enable_timing = True)
    iter_end = torch.cuda.Event(enable_timing = True)

    print("\nTraining Start..\n")
    ema_loss_for_log = 0.0
    progress_bar = tqdm(range(first_iter, opt.iterations), desc="Training progress")
    first_iter += 1


    for iteration in range(first_iter, opt.iterations + 1):  
        iter_start.record()

        # Keep LR constant within a scan(epoch), then update at scan boundaries.
        scan_aligned_iter = (iteration // iters_per_scan) * iters_per_scan
        gaussians.update_learning_rate(scan_aligned_iter)

        if (iteration - 1) == debug_from:
            pipe.debug = True

        if iteration ==1:
            gaussians.prune_out_bbox(chunk_len)

        random_x_int, random_y_int, random_z_int = subvol_centers[subvol_ptr]
        
        subvol_size_half = subvol_size // 2

        # gt subvolume 추출
        gt_subvol = gt_vol_chunk[
            random_x_int-subvol_size_half:random_x_int+subvol_size_half, 
            random_y_int-subvol_size_half:random_y_int+subvol_size_half, 
            random_z_int-subvol_size_half:random_z_int+subvol_size_half
        ]
        x_normalized = torch.linspace(-chunk_len / 2, chunk_len / 2 -2/x_chunk_size, steps=x_chunk_size)
        y_normalized = x_normalized[(x_chunk_size-y_chunk_size)//2 : (x_chunk_size-y_chunk_size)//2+y_chunk_size]
        z_normalized = x_normalized[(x_chunk_size-z_chunk_size)//2 : (x_chunk_size-z_chunk_size)//2+z_chunk_size]

        random_x = x_normalized[random_x_int]
        random_y = y_normalized[random_y_int]
        random_z = z_normalized[random_z_int]

        if subvol_size >= z_chunk_size:
            tv_vol_nVoxel = torch.tensor([subvol_size, subvol_size, 70])
        else:
            tv_vol_nVoxel = torch.tensor([subvol_size, subvol_size, subvol_size])
        tv_vol_sVoxel = torch.tensor(chunk_len / x_chunk_size) * tv_vol_nVoxel
        tv_vol_center = (random_x, random_y, random_z)

        #xyz순
        query_pkg = query(
            gaussians,
            tv_vol_center,
            tv_vol_nVoxel,
            tv_vol_sVoxel,
            pipe,
            ghost_pc = boundary_gaussians 
        )
        vol_pred, viewspace_point_tensor, visibility_filter, radii = (query_pkg["vol"], query_pkg["3d_mean"], query_pkg["visibility_filter"], query_pkg["radii"])

        subvol_ptr = (subvol_ptr + 1) % num_subvols

        Ll1 = l1_loss(vol_pred, gt_subvol)
        Lssim = ssim(vol_pred, gt_subvol)
        loss = (1.0 - opt.lambda_dssim) * Ll1 + opt.lambda_dssim * (1.0 - Lssim) #+  opt.lambda_structure * Lstructure
        loss.backward()


        iter_end.record()

        with torch.no_grad():
            if iteration < opt.densify_until_iter:
                gaussians.max_radii2D[visibility_filter] = torch.max(gaussians.max_radii2D[visibility_filter], radii[visibility_filter])
                gaussians.add_densification_stats(viewspace_point_tensor, visibility_filter)

            if iteration % 100 == 0:
                torch.cuda.empty_cache()

            if iteration in opt.darkpruning_iter or iteration == opt.iterations:
                prune_zeros(gaussians, scene, pipe, background, x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)
                gaussians.prune_dark_gaussians()
                _, _, voxel_count = prune_list(gaussians, scene, pipe, background, x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)

            if iteration in opt.globalpruning_iter:
                print(f"\n[ITER {iteration}] Global pruning step")
                print(f"Before pruning: {gaussians.get_xyz.shape[0]}")
                
                prune_zeros(gaussians, scene, pipe, background, x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)
                gaussians.prune_dark_gaussians()

                print(f"After dark pruning: {gaussians.get_xyz.shape[0]}")
                _, imp_list, voxel_count = prune_list(gaussians, scene, pipe, background, x_chunk_size, y_chunk_size, z_chunk_size, chunk_len)
                
                # FA pruning
                FA = compute_fa(gaussians.get_scaling)
                gaussians.prune_gaussians(
                   opt.pruning_remainweight, imp_list * FA
                )
                print(f"After FA pruning: {gaussians.get_xyz.shape[0]}")

            # Progress bar
            ema_loss_for_log = 0.4 * loss.item() + 0.6 * ema_loss_for_log
            if iteration % 10 == 0:
                progress_bar.set_postfix({"Loss": f"{ema_loss_for_log:.{7}f}"})
                progress_bar.update(10)

            if (iteration in opt.saving_iterations or iteration == opt.iterations):
                # print(f"\n[ITER {iteration}] Saving Gaussians")
                # Store chunk Gaussians in the shared global coordinate system so
                # the latest PLYs can be concatenated directly after training.
                scene.save(iteration, offset)
                # print(f"[ITER {iteration}] Saving Checkpoint")
                torch.save((gaussians.capture(), iteration), scene.model_path + "/chkpnt" + str(iteration) + ".pth")

                with torch.no_grad():
                    recon_vol = query(
                        gaussians,
                        [0,0,0],
                        [x_chunk_size,y_chunk_size,z_chunk_size],
                        [chunk_len, y_chunk_size/x_chunk_size*2, z_chunk_size/x_chunk_size*2],
                        pipe)['vol']
                    recon_vol = torch.clip(recon_vol, min=0.0, max=1.0)

                psnr_vol = compute_psnr(recon_vol, gt_vol_chunk)
                if training_mode == "full":
                    ssim_val = ssim(recon_vol, gt_vol_chunk)
                    ssim3d_val = compute_ssim_3d(gt_vol_chunk, recon_vol)
                    print(f"[Iter {iteration} Eval] 3D PSNR is : {psnr_vol:.2f} dB | SSIM: {ssim_val:.4f} | 3D SSIM: {ssim3d_val:.4f}")
                else : 
                    print(f"[Iter {iteration} Eval] 3D PSNR is : {psnr_vol:.2f} dB")
                with open(psnr_log_path, "a") as f:
                    f.write(
                        f"{iteration:>10d} | "
                        f"{Ll1.item():>12.6f} | "
                        f"{1 - Lssim.item():>12.6f} | "
                        f"{psnr_vol:>10.2f} | "
                        f"{gaussians.get_xyz.shape[0]:>12d} | "
                        f"{iter_start.elapsed_time(iter_end):>10.2f}\n"
                    )



            if iteration % 1000 == 0:
                number = gaussians.get_xyz.shape[0]
                psnr_val = compute_psnr_chunked(
                    gaussians=gaussians,
                    gt_vol=gt_vol_chunk.detach().cpu(),
                    x_voxel_size=x_chunk_size,
                    y_voxel_size=y_chunk_size,
                    z_voxel_size=z_chunk_size,
                    pipe=pipe,
                    chunk_size=512, # inference chunk 단위
                    spatial_extent=chunk_len,
                    ghost_pc=boundary_gaussians
                )
                print(f"[ITER {iteration}]  L1: {Ll1.item():.4f} | LSSIM: {1-Lssim.item():.4f} | PSNR: {psnr_val:.2f} dB | Number: {number}")
                with open(psnr_log_path, "a") as f:
                    f.write(
                        f"{iteration:>10d} | "
                        f"{Ll1.item():>12.6f} | "
                        f"{1 - Lssim.item():>12.6f} | "
                        f"{psnr_val:>10.2f} | "
                        f"{number:>12d} | "
                        f"{iter_start.elapsed_time(iter_end):>10.2f}\n"
                    )


            if iteration >= opt.densify_from_iter  and iteration <= opt.densify_until_iter:
                if iteration % opt.densification_interval == 0:
                    size_threshold = 20 if iteration > opt.opacity_reset_interval else None
                    gaussians.densify_and_prune(
                        opt.densify_grad_threshold, # max_grad 
                        1/255,                      # min_opacity
                        chunk_len,                  # extent
                        size_threshold ,            # max_screen_size 
                        None,                       # bbox
                        iteration,
                        chunk_len
                        )

                if iteration % opt.opacity_reset_interval == 0 or (dataset.white_background and iteration == opt.densify_from_iter):
                    gaussians.reset_opacity()

            # Optimizer step
            if iteration < opt.iterations:
                gaussians.optimizer.step()
                gaussians.optimizer.zero_grad(set_to_none = True)

            if iteration == opt.iterations:
                progress_bar.close()
                total_time = time.time() - start_time_total
                with open(psnr_log_path, "a") as f:
                    f.write(f"\nTotal training time: {total_time/60:.2f} minutes ({total_time:.1f} seconds)\n")
                print(f"\n[Training finished] Total training time: {total_time/60:.2f} minutes ({total_time:.1f} seconds)")


    # Training 완료
    total_time = time.time() - start_time_total
    print(f"\n[Chunk {chunk_idx} Training Complete] Total time: {total_time/60:.2f} minutes ({total_time:.1f} seconds)")


if __name__ == "__main__":
    # Set up command line argument parser
    parser = ArgumentParser(description="Training script parameters")
    lp = ModelParams(parser)
    op = OptimizationParams(parser)
    pp = PipelineParams(parser)
    parser.add_argument('--debug_from', type=int, default=-1)
    parser.add_argument('--detect_anomaly', action='store_true', default=False)
    parser.add_argument("--test_iterations", nargs="+", type=int, default=[50_000, 60_000,100_000, 100_001, 120_000, 140_000, 170_000, 200_000])
    parser.add_argument("--save_iterations", nargs="+", type=int, default=[10_000, 50_000, 60_000, 100_000, 100_001, 120_000, 140_000, 170_000, 200_000, 200_001])
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--checkpoint_iterations", nargs="+", type=int, default=[40_000, 70_000, 100_000, 140_000, 170_000, 200_000])
    parser.add_argument("--start_checkpoint", type=str, default = None)
    parser.add_argument("--chunk_idx", type=int, required=True, help="Zero-based chunk index")
    supported_datasets = sorted(
        name
        for name, config in DATASET_CONFIGS.items()
        if config.get("training_mode") in {"full", "chunk_sequential"}
    )
    parser.add_argument(
        "--dataset_name",
        type=str,
        required=True,
        choices=supported_datasets,
        help="Dataset configured for full or sequential-chunk training",
    )
    parser.add_argument("--subvol_size", type=int, default=64, help="Size of the subvolume to use for training")
    parser.add_argument("--init_num", type=int, default=100_000, help="Number of Gaussians to initialize")
    parser.add_argument("--pruning_remainweight", type=float, default=0.66, help="Fraction of Gaussians to keep during global pruning")
    parser.add_argument("--darkpruning_iter", nargs="+", type=int, default=[1,2,3])
    parser.add_argument("--globalpruning_iter", nargs="+", type=int, default=[1,2,3])

    args = parser.parse_args(sys.argv[1:])
    args.save_iterations.append(args.iterations)

    print("Optimizing " + args.model_path + "\n")

    # Initialize system state (RNG)
    safe_state(args.quiet)

    torch.autograd.set_detect_anomaly(args.detect_anomaly)
    training(
        lp.extract(args),           # dataset
        op.extract(args),           # opt
        pp.extract(args),           # pipe
        args.start_checkpoint,      # checkpoint
        args.debug_from,            # debug_from
        args.chunk_idx,             # chunk_idx
        args.dataset_name,          # dataset_name
        args.subvol_size            # subvol_size
        )

    # All done
    print("\nTraining complete.")
