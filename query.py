import numpy as np
import random
import matplotlib.pyplot as plt
import torch.nn.functional as F
import torch
from utils.loss_utils import l1_loss, ssim, l2_loss, compute_normals, compute_structure_tensor, subvolume_structure_loss, subvolume_structure_loss_voxelwise, subvolume_structure_loss_voxelwise_cosine, subvolume_structure_loss_voxelwise_eigenvector
from gaussian_renderer import query
import sys
from scene import Scene, GaussianModel
from utils.general_utils import safe_state
import uuid
from tqdm import tqdm
try:
    from torch.utils.tensorboard import SummaryWriter
    TENSORBOARD_FOUND = True
except ImportError:
    TENSORBOARD_FOUND = False

import math


def compute_psnr(vol1: torch.Tensor, vol2: torch.Tensor, data_range=1.0):
    """
    Compute PSNR between two 3D volumes.
    Args:
        vol1: torch.Tensor of shape (D, H, W), normalized [0, 1]
        vol2: torch.Tensor of shape (D, H, W), normalized [0, 1]
        data_range: maximum value of data range (1.0 if normalized)

    Returns:
        PSNR value (float)
    """
    mse = torch.mean((vol1 - vol2) ** 2)
    if mse == 0:
        return float('inf')
    psnr = 20 * torch.log10(torch.tensor(data_range) / torch.sqrt(mse))
    return psnr.item()

def compute_psnr_chunked(
    gaussians,
    gt_vol,
    x_voxel_size,
    y_voxel_size,
    z_voxel_size,
    pipe,
    data_range=1.0,
    chunk_size=512,
    spatial_extent=1.0,
    ghost_pc=None,
):
    X, Y, Z = x_voxel_size, y_voxel_size, z_voxel_size

    nx = (X + chunk_size - 1) // chunk_size
    ny = (Y + chunk_size - 1) // chunk_size
    nz = (Z + chunk_size - 1) // chunk_size
    total_chunks = nx * ny * nz

    # =========================================================
    # full query와 정확히 같은 GLOBAL GRID 생성
    # full query:
    # center = [0,0,0]
    # sVoxel = [spatial_extent, spatial_extent*Y/X, spatial_extent*Z/X]
    # =========================================================
    step = spatial_extent / X

    x_coords = torch.arange(X, dtype=torch.float32) * step - spatial_extent / 2 + step / 2
    y_coords = torch.arange(Y, dtype=torch.float32) * step - spatial_extent * (Y / X) / 2 + step / 2
    z_coords = torch.arange(Z, dtype=torch.float32) * step - spatial_extent * (Z / X) / 2 + step / 2

    if torch.cuda.is_available():
        x_coords = x_coords.cuda()
        y_coords = y_coords.cuda()
        z_coords = z_coords.cuda()

    SSE = 0.0
    total_voxels = 0
    chunk_idx = 0

    for ix in range(nx):
        xs = ix * chunk_size
        xe = min(xs + chunk_size, X)

        for iy in range(ny):
            ys = iy * chunk_size
            ye = min(ys + chunk_size, Y)

            for iz in range(nz):
                zs = iz * chunk_size
                ze = min(zs + chunk_size, Z)

                chunk_idx += 1

                xc = x_coords[xs:xe]
                yc = y_coords[ys:ye]
                zc = z_coords[zs:ze]

                # chunk center
                cx = (xc[0] + xc[-1]) / 2
                cy = (yc[0] + yc[-1]) / 2
                cz = (zc[0] + zc[-1]) / 2

                # chunk physical size
                sx = (xc[-1] - xc[0]) + step
                sy = (yc[-1] - yc[0]) + step
                sz = (zc[-1] - zc[0]) + step

                chunk_pred = query(
                    gaussians,
                    [cx.item(), cy.item(), cz.item()],
                    [xe - xs, ye - ys, ze - zs],
                    [sx.item(), sy.item(), sz.item()],
                    pipe,
                    use_step_function=True,
                    ghost_pc=ghost_pc,
                )["vol"]

                chunk_pred = torch.clamp(chunk_pred, 0, 1)

                chunk_gt = gt_vol[xs:xe, ys:ye, zs:ze]
                if not chunk_gt.is_cuda:
                    chunk_gt = chunk_gt.cuda()

                diff = chunk_pred - chunk_gt
                SSE += (diff ** 2).sum().item()
                total_voxels += diff.numel()

                del chunk_pred, chunk_gt, diff
                torch.cuda.empty_cache()

    # print(f"\nCompleted all {total_chunks} chunks")
    # print(f"Total voxels: {total_voxels}")
    # print(f"Total SSE: {SSE:.6f}")

    MSE = SSE / total_voxels
    if MSE == 0:
        return float("inf")
    return 20 * np.log10(data_range / np.sqrt(MSE))

def compute_ssim(vol1: torch.Tensor, vol2: torch.Tensor, data_range=1.0, window_size=7):
    """
    Compute SSIM between two 3D volumes (D, H, W).
    Both inputs should be normalized to [0, 1].

    Args:
        vol1, vol2: torch.Tensor of shape (D, H, W)
        data_range: dynamic range of values (1.0 if normalized)
        window_size: size of the sliding window (odd number)

    Returns:
        Mean SSIM value (float)
    """
    assert vol1.shape == vol2.shape, "Input volumes must have the same shape"
    vol1 = vol1.unsqueeze(0).unsqueeze(0)  # (1,1,D,H,W)
    vol2 = vol2.unsqueeze(0).unsqueeze(0)

    # 3D Gaussian window
    gauss = torch.tensor([torch.exp(-(x - window_size//2)**2/float(2*1.5**2)) 
                          for x in range(window_size)], dtype=torch.float32)
    gauss = gauss / gauss.sum()
    window = gauss[:,None,None] * gauss[None,:,None] * gauss[None,None,:]
    window = window.unsqueeze(0).unsqueeze(0).to(vol1.device)

    # Convolution for local statistics
    mu1 = F.conv3d(vol1, window, padding=window_size//2)
    mu2 = F.conv3d(vol2, window, padding=window_size//2)

    mu1_sq = mu1.pow(2)
    mu2_sq = mu2.pow(2)
    mu1_mu2 = mu1 * mu2

    sigma1_sq = F.conv3d(vol1*vol1, window, padding=window_size//2) - mu1_sq
    sigma2_sq = F.conv3d(vol2*vol2, window, padding=window_size//2) - mu2_sq
    sigma12   = F.conv3d(vol1*vol2, window, padding=window_size//2) - mu1_mu2

    C1 = (0.01 * data_range) ** 2
    C2 = (0.03 * data_range) ** 2

    ssim_map = ((2*mu1_mu2 + C1) * (2*sigma12 + C2)) / ((mu1_sq+mu2_sq + C1) * (sigma1_sq+sigma2_sq + C2))
    return ssim_map.mean().item()


def compute_ssim_3d(vol1: torch.Tensor, vol2: torch.Tensor, data_range=1.0, window_size=7):
    assert vol1.shape == vol2.shape, "Input volumes must have the same shape"
    vol1 = vol1.unsqueeze(0).unsqueeze(0)  # (1,1,D,H,W)
    vol2 = vol2.unsqueeze(0).unsqueeze(0)

    # 3D Gaussian window
    coords = torch.arange(window_size, dtype=torch.float32, device=vol1.device)
    gauss = torch.exp(-((coords - window_size//2) ** 2) / (2 * 1.5 ** 2))
    gauss = gauss / gauss.sum()
    window = gauss[:,None,None] * gauss[None,:,None] * gauss[None,None,:]
    window = window.unsqueeze(0).unsqueeze(0)

    mu1 = F.conv3d(vol1, window, padding=window_size//2)
    mu2 = F.conv3d(vol2, window, padding=window_size//2)

    mu1_sq = mu1.pow(2)
    mu2_sq = mu2.pow(2)
    mu1_mu2 = mu1 * mu2

    sigma1_sq = F.conv3d(vol1*vol1, window, padding=window_size//2) - mu1_sq
    sigma2_sq = F.conv3d(vol2*vol2, window, padding=window_size//2) - mu2_sq
    sigma12   = F.conv3d(vol1*vol2, window, padding=window_size//2) - mu1_mu2

    C1 = (0.01 * data_range) ** 2
    C2 = (0.03 * data_range) ** 2

    ssim_map = ((2*mu1_mu2 + C1) * (2*sigma12 + C2)) / ((mu1_sq+mu2_sq + C1) * (sigma1_sq+sigma2_sq + C2))
    return ssim_map.mean().item()