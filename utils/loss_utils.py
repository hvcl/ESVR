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

import torch
import torch.nn.functional as F
from torch.autograd import Variable
from math import exp



import torch
import torch.nn.functional as F
from typing import Literal, Optional



def _sobel_grad_3d(volume: torch.Tensor):
    """
    3D Sobel gradient via 3D conv.
    volume: (D,H,W)
    returns: dx, dy, dz each (D,H,W)
    """
    device, dtype = volume.device, volume.dtype

    # 1D kernels
    s = torch.tensor([1., 2., 1.], device=device, dtype=dtype)
    d = torch.tensor([-1., 0., 1.], device=device, dtype=dtype)

    # 3D kernels by outer products (separable)
    # For dx: derivative along X (W), smoothing along Z(D), Y(H)
    kx = torch.einsum('i,j,k->ijk', s, s, d)  # (D,H,W)
    ky = torch.einsum('i,j,k->ijk', s, d, s)
    kz = torch.einsum('i,j,k->ijk', d, s, s)

    # normalize like standard Sobel (sum of abs weights = 32); scaling not critical for loss
    kx = (kx / 8.0)[None, None, ...]  # (1,1,3,3,3)
    ky = (ky / 8.0)[None, None, ...]
    kz = (kz / 8.0)[None, None, ...]

    v = volume[None, None, ...]  # (1,1,D,H,W)
    pad = (1, 1, 1)  # each dim padding=1
    dx = F.conv3d(v, kx, padding=1).squeeze(0).squeeze(0)
    dy = F.conv3d(v, ky, padding=1).squeeze(0).squeeze(0)
    dz = F.conv3d(v, kz, padding=1).squeeze(0).squeeze(0)
    return dx, dy, dz




def _central_diff_3d(volume: torch.Tensor):
    """
    Central differences with same-shape padding.
    volume: (D,H,W)
    returns: dx, dy, dz each (D,H,W)
    """
    # dz (along depth D)
    dz = (volume[2:, :, :] - volume[:-2, :, :]) * 0.5
    dz = F.pad(dz, (0, 0, 0, 0, 1, 1))

    # dy (along H)
    dy = (volume[:, 2:, :] - volume[:, :-2, :]) * 0.5
    dy = F.pad(dy, (0, 0, 1, 1))

    # dx (along W)
    dx = (volume[:, :, 2:] - volume[:, :, :-2]) * 0.5
    dx = F.pad(dx, (1, 1))

    return dx, dy, dz


def _make_gaussian_kernel_1d(sigma: float, device, dtype):
    # kernel size: 2*ceil(3*sigma)+1  (≈ 3σ rule)
    ksize = int(2 * torch.ceil(torch.tensor(3*sigma)) + 1)
    if ksize < 3:  # 최소 크기 보호
        ksize = 3
    x = torch.arange(ksize, device=device, dtype=dtype) - (ksize - 1) / 2
    g = torch.exp(-(x**2) / (2 * sigma**2))
    g = g / g.sum()
    return g.view(1, 1, -1)  # (out_ch,in_ch,K)


def _separable_gaussian_blur_3d(x: torch.Tensor, sigma: float):
    """
    x: (N,C,D,H,W)
    returns: (N,C,D,H,W)
    """
    N, C, D, H, W = x.shape
    device, dtype = x.device, x.dtype
    g = _make_gaussian_kernel_1d(sigma, device, dtype)

    # depth
    x = F.conv3d(x, g.view(1,1,-1,1,1).expand(C,1,-1,1,1), padding=(g.shape[2]//2,0,0), groups=C)
    # height
    x = F.conv3d(x, g.view(1,1,1,-1,1).expand(C,1,1,-1,1), padding=(0,g.shape[2]//2,0), groups=C)
    # width
    x = F.conv3d(x, g.view(1,1,1,1,-1).expand(C,1,1,1,-1), padding=(0,0,g.shape[2]//2), groups=C)
    return x


def compute_structure_tensor_voxelwise(
    volume: torch.Tensor,
    sigma: float = 1.0,
    normalize: bool = True,
    eps: float = 1e-6,
    gradient: str = "central"
) -> torch.Tensor:
    """
    각 voxel의 구조 텐서 J = ∇I ∇I^T 를 계산.
    Args:
        volume: (D,H,W) torch tensor (float, requires_grad 가능)
        smoothing:
            - "gaussian": 가우시안 스무딩으로 로컬 집계 (σ 사용)
            - "box": 박스 평균으로 로컬 집계 (box_radius 사용)
            - None: 스무딩 없이 원시 outer-product
        sigma: 가우시안 σ
        normalize:
            - "voxel": 각 voxel 텐서를 Frobenius norm으로 정규화
            - "none": 정규화 안 함
        eps: 안정성용 작은 값
    Returns:
        J: (D,H,W,3,3) voxel-wise structure tensor
    """
    assert volume.dim() == 3, "volume must be (D,H,W)"
    if gradient == "centeral":
        dx, dy, dz = _central_diff_3d(volume)
    else:
        dx, dy, dz = _sobel_grad_3d(volume)

    # 6개의 독립 성분(대칭) 계산
    Ixx = dx*dx
    Iyy = dy*dy
    Izz = dz*dz
    Ixy = dx*dy
    Ixz = dx*dz
    Iyz = dy*dz

    comp = torch.stack([Ixx,Iyy,Izz,Ixy,Ixz,Iyz], dim=0).unsqueeze(0)  # (1,6,D,H,W)
    comp = _separable_gaussian_blur_3d(comp, sigma)
    Ixx, Iyy, Izz, Ixy, Ixz, Iyz = comp.squeeze(0).unbind(dim=0)

    # (D,H,W,3,3) 조립
    D,H,W = volume.shape
    J = torch.empty((D,H,W,3,3), dtype=volume.dtype, device=volume.device)
    J[...,0,0] = Ixx
    J[...,1,1] = Iyy
    J[...,2,2] = Izz
    J[...,0,1] = J[...,1,0] = Ixy
    J[...,0,2] = J[...,2,0] = Ixz
    J[...,1,2] = J[...,2,1] = Iyz

    if normalize:
        # Frobenius norm per voxel
        frob = torch.linalg.norm(J.reshape(D,H,W,9), dim=-1, ord=2)
        J = J / (frob[...,None,None] + eps)

    return J


def subvolume_structure_loss_voxelwise_eigenvector(
    gt_subvol: torch.Tensor,
    pred_subvol: torch.Tensor,
    sigma: float = 1.0,
    normalize: bool = True,   # 보통 normalize=True
    eps: float = 1e-6,
) -> torch.Tensor:
    st_gt = compute_structure_tensor_voxelwise(
        gt_subvol, sigma=sigma, normalize=normalize, eps=eps
    )
    st_pred = compute_structure_tensor_voxelwise(
        pred_subvol, sigma=sigma, normalize=normalize, eps=eps
    )

    D,H,W = st_gt.shape[:3]
    # reshape for batch eigendecomposition: (N,3,3)
    st_gt_flat = st_gt.reshape(-1,3,3)
    st_pred_flat = st_pred.reshape(-1,3,3)

    # torch.linalg.eigh gives eigenvalues (ascending) + eigenvectors
    evals_gt, evecs_gt = torch.linalg.eigh(st_gt_flat)   # (N,3), (N,3,3)
    evals_pred, evecs_pred = torch.linalg.eigh(st_pred_flat)

    # take principal eigenvector (largest eigenvalue -> last column)
    v_gt = evecs_gt[:,:, -1]
    v_pred = evecs_pred[:,:, -1]

    # normalize vectors
    v_gt = v_gt / (torch.norm(v_gt, dim=-1, keepdim=True)+eps)
    v_pred = v_pred / (torch.norm(v_pred, dim=-1, keepdim=True)+eps)

    # cosine similarity of principal eigenvectors
    cos_sim = torch.abs((v_gt * v_pred).sum(dim=-1))  # abs → 방향 반전 고려
    loss = 1 - cos_sim

    return loss.mean()




def subvolume_structure_loss_voxelwise_cosine(
    gt_subvol: torch.Tensor,
    pred_subvol: torch.Tensor,
    sigma: float = 1.0,
    normalize: bool = True,   # 보통 normalize=True와 같이 쓰는게 안정적
    eps: float = 1e-6,
    gradient: str = "central",
) -> torch.Tensor:
    st_gt = compute_structure_tensor_voxelwise(
        gt_subvol, sigma=sigma, normalize=normalize, eps=eps, gradient =gradient
    )
    st_pred = compute_structure_tensor_voxelwise(
        pred_subvol, sigma=sigma, normalize=normalize, eps=eps, gradient =gradient
    )

    # flatten (D,H,W,9)
    D,H,W,_,_ = st_gt.shape
    gt_flat = st_gt.reshape(D,H,W,9)
    pred_flat = st_pred.reshape(D,H,W,9)

    # cosine similarity per voxel
    dot = (gt_flat * pred_flat).sum(dim=-1)
    norm_gt = torch.linalg.norm(gt_flat, dim=-1)
    norm_pred = torch.linalg.norm(pred_flat, dim=-1)
    cos_sim = dot / (norm_gt*norm_pred + eps)

    loss = 1 - cos_sim  # similarity -> loss
    return loss.mean()


def subvolume_structure_loss_voxelwise(
    gt_subvol: torch.Tensor,
    pred_subvol: torch.Tensor,
    sigma: float = 1.0,
    normalize: bool = True,
    eps: float = 1e-6,
) -> torch.Tensor:
    """
    각 voxel의 구조 텐서를 비교하는 손실.
    Args:
        gt_subvol, pred_subvol: (D,H,W)
    Returns:
        scalar (reduction에 따라)
    """
    st_gt = compute_structure_tensor_voxelwise(
        gt_subvol, sigma=sigma,
        normalize=normalize, eps=eps
    )
    st_pred = compute_structure_tensor_voxelwise(
        pred_subvol, sigma=sigma,
        normalize=normalize, eps=eps
    )

    loss = (st_gt - st_pred).pow(2).mean(dim=(-1,-2))  # 각 voxel에서 3x3 MSE -> (D,H,W)

    return loss.mean()
    # if reduction == "mean":
    #     return loss.mean()
    # elif reduction == "sum":
    #     return loss.sum()
    # else:
    #     return loss  # (D,H,W)



### voxel structure tensor


def l1_loss(network_output, gt):
    return torch.abs((network_output - gt)).mean()

def compute_structure_tensor(volume: torch.Tensor) -> torch.Tensor:
    """
    Compute the 3x3 structure tensor for a 3D subvolume.
    Args:
        volume: (D, H, W) torch tensor
    Returns:
        structure_tensor: (3, 3) tensor
    """
    # Compute gradients
    dz = F.pad(volume[2:, :, :] - volume[:-2, :, :], (0, 0, 0, 0, 1, 1))
    dy = F.pad(volume[:, 2:, :] - volume[:, :-2, :], (0, 0, 1, 1))
    dx = F.pad(volume[:, :, 2:] - volume[:, :, :-2], (1, 1))

    # Flatten and normalize
    dx = dx.reshape(-1)
    dy = dy.reshape(-1)
    dz = dz.reshape(-1)

    # Structure tensor components
    J = torch.stack([dx, dy, dz], dim=1)  # (N, 3)
    structure_tensor = J.T @ J  # (3, 3)

    return structure_tensor / J.shape[0]


def subvolume_structure_loss(gt_subvol: torch.Tensor, pred_subvol: torch.Tensor) -> torch.Tensor:
    """
    Compare structure tensors of GT and predicted subvolumes.
    Args:
        gt_subvol, pred_subvol: (D, H, W)
    Returns:
        Scalar loss
    """
    st_gt = compute_structure_tensor(gt_subvol)
    st_pred = compute_structure_tensor(pred_subvol)

    # Normalize for stability
    st_gt = st_gt / (torch.norm(st_gt) + 1e-6)
    st_pred = st_pred / (torch.norm(st_pred) + 1e-6)

    return F.mse_loss(st_gt, st_pred)


def subvolume_anisotropy_loss(struct_tensor: torch.Tensor, gaussian_covs: torch.Tensor) -> torch.Tensor:
    """
    Align Gaussians' covariances with the subvolume's structure tensor.
    Args:
        struct_tensor: (3, 3) structure tensor of the subvolume
        gaussian_covs: (N, 3, 3) covariance matrices of Gaussians
    Returns:
        Scalar loss measuring misalignment
    """
    # Normalize structure tensor
    struct_tensor = struct_tensor / (torch.norm(struct_tensor) + 1e-6)
    loss = 0

    for cov in gaussian_covs:
        cov = cov / (torch.norm(cov) + 1e-6)
        # Compute Frobenius norm difference
        loss += F.mse_loss(cov, struct_tensor)

    return loss / len(gaussian_covs)


def compute_normals(volume):
    # volume: [D, H, W] (single subvolume)
    # Gradient (central difference, replicate padding)
    dz = F.pad(volume[2:, :, :] - volume[:-2, :, :], (0,0,0,0,1,1))
    dy = F.pad(volume[:, 2:, :] - volume[:, :-2, :], (0,0,1,1,0,0))
    dx = F.pad(volume[:, :, 2:] - volume[:, :, :-2], (1,1,0,0,0,0))
    normals = torch.stack([dx, dy, dz], dim=0)  # [3, D, H, W]
    norm = torch.norm(normals, dim=0, keepdim=True) + 1e-8
    normals = normals / norm
    return normals  # [3, D, H, W]

def l2_loss(network_output, gt):
    return ((network_output - gt) ** 2).mean()

def gaussian(window_size, sigma):
    gauss = torch.Tensor([exp(-(x - window_size // 2) ** 2 / float(2 * sigma ** 2)) for x in range(window_size)])
    return gauss / gauss.sum()

def create_window(window_size, channel):
    _1D_window = gaussian(window_size, 1.5).unsqueeze(1)
    _2D_window = _1D_window.mm(_1D_window.t()).float().unsqueeze(0).unsqueeze(0)
    window = Variable(_2D_window.expand(channel, 1, window_size, window_size).contiguous())
    return window

def ssim(img1, img2, window_size=11, size_average=True):
    channel = img1.size(-3)
    window = create_window(window_size, channel)

    if img1.is_cuda:
        window = window.cuda(img1.get_device())
    window = window.type_as(img1)

    return _ssim(img1, img2, window, window_size, channel, size_average)

def _ssim(img1, img2, window, window_size, channel, size_average=True):
    mu1 = F.conv2d(img1, window, padding=window_size // 2, groups=channel)
    mu2 = F.conv2d(img2, window, padding=window_size // 2, groups=channel)

    mu1_sq = mu1.pow(2)
    mu2_sq = mu2.pow(2)
    mu1_mu2 = mu1 * mu2

    sigma1_sq = F.conv2d(img1 * img1, window, padding=window_size // 2, groups=channel) - mu1_sq
    sigma2_sq = F.conv2d(img2 * img2, window, padding=window_size // 2, groups=channel) - mu2_sq
    sigma12 = F.conv2d(img1 * img2, window, padding=window_size // 2, groups=channel) - mu1_mu2

    C1 = 0.01 ** 2
    C2 = 0.03 ** 2

    ssim_map = ((2 * mu1_mu2 + C1) * (2 * sigma12 + C2)) / ((mu1_sq + mu2_sq + C1) * (sigma1_sq + sigma2_sq + C2))

    if size_average:
        return ssim_map.mean()
    else:
        return ssim_map.mean(1).mean(1).mean(1)

