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
import math
from gaussian_rasterization_voxelization import (
    GaussianVoxelizationSettings,
    GaussianVoxelizer,
    GaussianVoxelizer_Count,
)
from scene.gaussian_model import GaussianModel
from typing import Optional

def query(
    pc: GaussianModel,
    center,
    nVoxel,
    sVoxel,
    pipe,
    scaling_modifier=1.0,
    use_step_function=False,
    ghost_pc : Optional[GaussianModel] = None 
):
    """
    Query a volume with voxelization.
    """
    voxel_settings = GaussianVoxelizationSettings(
        scale_modifier=scaling_modifier,
        nVoxel_x=int(nVoxel[0]),
        nVoxel_y=int(nVoxel[1]),
        nVoxel_z=int(nVoxel[2]),
        sVoxel_x=float(sVoxel[0]),
        sVoxel_y=float(sVoxel[1]),
        sVoxel_z=float(sVoxel[2]),
        center_x=float(center[0]),
        center_y=float(center[1]),
        center_z=float(center[2]),
        prefiltered=False,
        debug=pipe.debug,
        use_step_function=use_step_function
    )
    voxelizer = GaussianVoxelizer(voxel_settings=voxel_settings)

    means3D = pc.get_xyz
    density = pc.get_opacity

    if ghost_pc is not None: 
        # print('ghost pc num:', ghost_pc.get_xyz.shape[0])
        means3D = torch.cat([ghost_pc.get_xyz.detach(), means3D], dim=0)
        density = torch.cat([ghost_pc.get_opacity.detach(), density], dim=0)

    scales = None
    rotations = None
    cov3D_precomp = None
    if pipe.compute_cov3D_python:
        cov3D_precomp = pc.get_covariance(scaling_modifier)
        if ghost_pc is not None: #
            ghost_cov3D = ghost_pc.get_covariance(scaling_modifier).detach()
            cov3D_precomp = torch.cat([ghost_cov3D, cov3D_precomp], dim=0)
    else:
        scales = pc.get_scaling
        rotations = pc.get_rotation
        if ghost_pc is not None: # 
            ghost_scales = ghost_pc.get_scaling.detach()
            ghost_rotations = ghost_pc.get_rotation.detach()
            scales = torch.cat([ghost_scales, scales], dim=0)
            rotations = torch.cat([ghost_rotations, rotations], dim=0)
            

    vol_pred, radii = voxelizer(
        means3D=means3D,
        opacities=density,
        scales=scales,
        rotations=rotations,
        cov3D_precomp=cov3D_precomp,
    )

    radii_max = torch.max(torch.stack((radii[0], radii[1], radii[2])), dim=0)[0]

    if ghost_pc is not None: # 
        num_ghost = ghost_pc.get_xyz.shape[0]
        radii_trainable = radii_max[num_ghost:]
    else:
        radii_trainable = radii_max

    return {
        "vol": vol_pred,
        "3d_mean": pc.get_xyz,                      # exclude ghost ellipsoids
        "visibility_filter" : radii_trainable > 0,  # exclude ghost ellipsoids
        "radii": radii_trainable,
    }

def count_query(
    pc: GaussianModel,
    center,
    nVoxel,
    sVoxel,
    pipe,
    scaling_modifier=1.0,
):
    """
    Query a volume with voxelization.
    """
    voxel_settings = GaussianVoxelizationSettings(
        scale_modifier=scaling_modifier,
        nVoxel_x=int(nVoxel[0]),
        nVoxel_y=int(nVoxel[1]),
        nVoxel_z=int(nVoxel[2]),
        sVoxel_x=float(sVoxel[0]),
        sVoxel_y=float(sVoxel[1]),
        sVoxel_z=float(sVoxel[2]),
        center_x=float(center[0]),
        center_y=float(center[1]),
        center_z=float(center[2]),
        prefiltered=False,
        debug=pipe.debug,
        use_step_function=False
    )
    voxelizer = GaussianVoxelizer_Count(voxel_settings=voxel_settings)

    means3D = pc.get_xyz
    density = pc.get_opacity

    scales = None
    rotations = None
    cov3D_precomp = None
    if pipe.compute_cov3D_python:
        cov3D_precomp = pc.get_covariance(scaling_modifier)
    else:
        scales = pc.get_scaling
        rotations = pc.get_rotation

    gaussians_count, important_score, vol_pred, radii = voxelizer(
        means3D=means3D,
        opacities=density,
        scales=scales,
        rotations=rotations,
        cov3D_precomp=cov3D_precomp,
    )

    ## Analyze the distribution of gaussians_count for debugging
    # counts = gaussians_count
    # active = counts[counts > 0]

    # if active.numel() > 0:
    #     print("active:", active.numel())
    #     print("mean:", active.mean())
    #     print("median:", active.median())
    #     print("p90:", torch.quantile(active, torch.tensor(0.90, device=active.device)))
    #     print("max:", active.max())
    #     print("min:", active.min())

    
    radii_max = torch.max(torch.stack((radii[0], radii[1], radii[2])), dim=0)[0]

    return {
        "vol": vol_pred,
        "3d_mean": means3D,
        "visibility_filter" : radii_max > 0,
        "radii": radii_max,
        "gaussians_count": gaussians_count,
        "important_score": important_score
    }

