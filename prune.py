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

import os
import torch
from random import randint
from gaussian_renderer import count_query #render, count_query
import sys
from scene import Scene, GaussianModel
from utils.general_utils import safe_state
import uuid
from tqdm import tqdm
from argparse import ArgumentParser, Namespace
from arguments import ModelParams, PipelineParams, OptimizationParams
import random
import copy
import gc
import numpy as np
from collections import defaultdict
import math

import skimage


INT32_NUMEL_LIMIT = 2**31 - 1
DEFAULT_COUNT_QUERY_CHUNK = 1024

def compute_fa(eigenvalues: torch.Tensor) -> torch.Tensor:
    # Compute the mean diffusivity (MD)
    lambda_mean = eigenvalues.mean(dim=1, keepdim=True)  # (N, 1)
    
    # Compute the numerator: sqrt((λ1 - λ̄)² + (λ2 - λ̄)² + (λ3 - λ̄)²)
    numerator = torch.sqrt(((eigenvalues - lambda_mean) ** 2).sum(dim=1))  # (N,)
    
    # Compute the denominator: sqrt(λ1² + λ2² + λ3²)
    denominator = torch.sqrt((eigenvalues ** 2).sum(dim=1))  # (N,)
    
    # Compute FA
    FA = math.sqrt(1.5) * (numerator / (denominator + 1e-6))  # Add small epsilon for stability
    
    return FA

def calculate_v_imp_score(gaussians, imp_list, v_pow):
    """
    :param gaussians: A data structure containing Gaussian components with a get_scaling method.
    :param imp_list: The importance scores for each Gaussian component.
    :param v_pow: The power to which the volume ratios are raised.
    :return: A list of adjusted values (v_list) used for pruning.
    """
    # Calculate the volume of each Gaussian component
    volume = torch.prod(gaussians.get_scaling, dim=1)
    # Determine the kth_percent_largest value
    index = int(len(volume) * 0.9)
    sorted_volume, _ = torch.sort(volume, descending=False)
    kth_percent_largest = sorted_volume[index]
    #kth_percent_largest = sorted_volume[-1]
    # Calculate v_list
    v_list = torch.pow(torch.clip(volume / kth_percent_largest, 0 , 1) , 0.1)
    v_list = v_list * imp_list 
    return v_list


def _resolve_count_chunk_size(x_size, y_size, z_size, preferred_chunk=DEFAULT_COUNT_QUERY_CHUNK):
    if x_size * y_size * z_size <= INT32_NUMEL_LIMIT:
        return max(x_size, y_size, z_size)

    max_safe_chunk = int(INT32_NUMEL_LIMIT ** (1.0 / 3.0))
    return min(preferred_chunk, max_safe_chunk, x_size, y_size, z_size)


def _count_query_chunked(
    gaussians,
    pipe,
    x_size,
    y_size,
    z_size,
    chunk_size,
    extent,
    return_voxel_count=False,
):
    X, Y, Z = x_size, y_size, z_size

    nx = (X + chunk_size - 1) // chunk_size
    ny = (Y + chunk_size - 1) // chunk_size
    nz = (Z + chunk_size - 1) // chunk_size

    step = extent / X
    x_coords = torch.arange(X, dtype=torch.float32) * step - extent / 2 + step / 2
    y_coords = torch.arange(Y, dtype=torch.float32) * step - extent * (Y / X) / 2 + step / 2
    z_coords = torch.arange(Z, dtype=torch.float32) * step - extent * (Z / X) / 2 + step / 2

    if torch.cuda.is_available():
        x_coords = x_coords.cuda()
        y_coords = y_coords.cuda()
        z_coords = z_coords.cuda()

    gaussian_count_total = None
    important_score_total = None

    voxel_count_np = None
    if return_voxel_count:
        voxel_count_np = np.zeros((X, Y, Z), dtype=np.uint8)

    for ix in range(nx):
        xs = ix * chunk_size
        xe = min(xs + chunk_size, X)

        for iy in range(ny):
            ys = iy * chunk_size
            ye = min(ys + chunk_size, Y)

            for iz in range(nz):
                zs = iz * chunk_size
                ze = min(zs + chunk_size, Z)

                xc = x_coords[xs:xe]
                yc = y_coords[ys:ye]
                zc = z_coords[zs:ze]

                cx = (xc[0] + xc[-1]) / 2
                cy = (yc[0] + yc[-1]) / 2
                cz = (zc[0] + zc[-1]) / 2

                sx = (xc[-1] - xc[0]) + step
                sy = (yc[-1] - yc[0]) + step
                sz = (zc[-1] - zc[0]) + step

                render_pkg = count_query(
                    gaussians,
                    [cx.item(), cy.item(), cz.item()],
                    [xe - xs, ye - ys, ze - zs],
                    [sx.item(), sy.item(), sz.item()],
                    pipe,
                )

                curr_gaussian_count = render_pkg["gaussians_count"]
                curr_important_score = render_pkg["important_score"]

                if gaussian_count_total is None:
                    gaussian_count_total = torch.zeros_like(curr_gaussian_count)
                    important_score_total = torch.zeros_like(curr_important_score)

                if curr_gaussian_count.shape != gaussian_count_total.shape:
                    curr_gaussian_count = curr_gaussian_count.reshape(gaussian_count_total.shape)
                if curr_important_score.shape != important_score_total.shape:
                    curr_important_score = curr_important_score.reshape(important_score_total.shape)

                gaussian_count_total += curr_gaussian_count
                important_score_total += curr_important_score

                if voxel_count_np is not None:
                    voxel_count_float = render_pkg["vol"].detach().cpu().numpy()
                    voxel_count_np[xs:xe, ys:ye, zs:ze] = np.round(
                        voxel_count_float.squeeze()
                    ).astype(np.uint8)

                del render_pkg
                torch.cuda.empty_cache()

    if gaussian_count_total is None:
        gaussian_count_total = torch.zeros_like(gaussians.get_opacity)
        important_score_total = torch.zeros_like(gaussians.get_opacity)

    return gaussian_count_total, important_score_total, voxel_count_np


def prune_zeros(gaussians, scene, pipe, background, x_size, y_size, z_size, chunk_size=None):
    gaussian_list, imp_list = None, None

    x = x_size
    y = y_size
    z = z_size
    # print('x,y,z for prune_list:', x, y, z)

    if chunk_size is None:
        chunk_size = 2.0
    # print('chunk_size for prune_list:', chunk_size)

    count_chunk_size = _resolve_count_chunk_size(x, y, z)
    if x * y * z > INT32_NUMEL_LIMIT:
        print(f'Using chunked count_query for prune_zeros: {count_chunk_size}')

    gaussian_list, _, _ = _count_query_chunked(
        gaussians,
        pipe,
        x,
        y,
        z,
        count_chunk_size,
        chunk_size,
        return_voxel_count=False,
    )
    gaussians.prune_gaussians_zeros(gaussian_list)



def prune_list(gaussians, scene, pipe, background, x_size, y_size, z_size, chunk_size=None):
    gaussian_list, imp_list = None, None

    x = x_size
    y = y_size
    z = z_size

    if chunk_size is None:
        chunk_size = 2.0
    

    count_chunk_size = _resolve_count_chunk_size(x, y, z)
    if x * y * z > INT32_NUMEL_LIMIT:
        print(f'Using chunked count_query for prune_list: {count_chunk_size}')

    return_voxel_count = x * y * z <= INT32_NUMEL_LIMIT
    gaussian_list, imp_list, voxel_count_np = _count_query_chunked(
        gaussians,
        pipe,
        x,
        y,
        z,
        count_chunk_size,
        chunk_size,
        return_voxel_count=return_voxel_count,
    )

    if not return_voxel_count:
        voxel_count_np = None

    return gaussian_list, imp_list, voxel_count_np
