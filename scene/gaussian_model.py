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
import numpy as np
from utils.general_utils import inverse_sigmoid, get_expon_lr_func, build_rotation, inverse_sigmoid_10
from torch import nn
import os
from utils.system_utils import mkdir_p
from plyfile import PlyData, PlyElement
from simple_knn._C import distCUDA2
from utils.general_utils import strip_symmetric, build_scaling_rotation
import math

class GaussianModel:

    def setup_functions(self):
        def build_covariance_from_scaling_rotation(scaling, scaling_modifier, rotation):
            L = build_scaling_rotation(scaling_modifier * scaling, rotation)
            actual_covariance = L @ L.transpose(1, 2)
            symm = strip_symmetric(actual_covariance)
            return symm

        self.scaling_activation = torch.exp
        self.scaling_inverse_activation = torch.log

        self.covariance_activation = build_covariance_from_scaling_rotation

        self.opacity_activation = torch.sigmoid
        self.inverse_opacity_activation = inverse_sigmoid

        self.rotation_activation = torch.nn.functional.normalize

    def __init__(self, x_resol: int, y_resol: int, z_resol: int):
        self._xyz = torch.empty(0)
        self._scaling = torch.empty(0)
        self._rotation = torch.empty(0)
        self._opacity = torch.empty(0)
        self.max_radii2D = torch.empty(0)
        self.xyz_gradient_accum = torch.empty(0)
        self.denom = torch.empty(0)
        self.optimizer = None
        self.percent_dense = 0
        self.spatial_lr_scale = 0
        self.x_resol = x_resol 
        self.y_resol = y_resol 
        self.z_resol = z_resol 
        self.setup_functions()
        self.mu_factor = 400*math.sqrt(2 * 3.14159265358979323846)

    def capture(self):
        return (
            self._xyz,
            self._scaling,
            self._rotation,
            self._opacity,
            self.max_radii2D,
            self.xyz_gradient_accum,
            self.denom,
            self.optimizer.state_dict(),
            self.spatial_lr_scale,
        )
    
    def restore(self, model_args, training_args):
        (self._xyz, 
        self._scaling, 
        self._rotation, 
        self._opacity,
        self.max_radii2D, 
        xyz_gradient_accum, 
        denom,
        opt_dict, 
        self.spatial_lr_scale) = model_args
        self.training_setup(training_args)
        self.xyz_gradient_accum = xyz_gradient_accum
        self.denom = denom
        self.optimizer.load_state_dict(opt_dict)

    @property
    def get_scaling(self):
        return self.scaling_activation(self._scaling)
    
    @property
    def get_rotation(self):
        return self.rotation_activation(self._rotation)
    
    @property
    def get_xyz(self):
        return self._xyz
    
    @property
    def get_opacity(self):
        return self.opacity_activation(self._opacity)
    
    def get_covariance(self, scaling_modifier = 1):
        return self.covariance_activation(self.get_scaling, scaling_modifier, self._rotation)

    def training_setup(self, training_args):
        self.percent_dense = training_args.percent_dense
        self.xyz_gradient_accum = torch.zeros((self.get_xyz.shape[0], 1), device="cuda")
        self.denom = torch.zeros((self.get_xyz.shape[0], 1), device="cuda")

        l = [
            {'params': [self._xyz], 'lr': training_args.position_lr_init * self.spatial_lr_scale, "name": "xyz"},
            {'params': [self._opacity], 'lr': training_args.opacity_lr_init * self.spatial_lr_scale, "name": "opacity"},
            {'params': [self._scaling], 'lr': training_args.scaling_lr_init * self.spatial_lr_scale, "name": "scaling"},
            {'params': [self._rotation], 'lr': training_args.rotation_lr_init * self.spatial_lr_scale, "name": "rotation"}
        ]

        self.optimizer = torch.optim.Adam(l, lr=0.0, eps=1e-15)
        self.xyz_scheduler_args = get_expon_lr_func(
            lr_init=training_args.position_lr_init * self.spatial_lr_scale,
            lr_final=training_args.position_lr_final * self.spatial_lr_scale,
            lr_delay_mult=training_args.position_lr_delay_mult,
            max_steps=training_args.position_lr_max_steps,
        )
        self.opacity_scheduler_args = get_expon_lr_func(
            lr_init=training_args.opacity_lr_init * self.spatial_lr_scale,
            lr_final=training_args.opacity_lr_final * self.spatial_lr_scale,
            max_steps=training_args.opacity_lr_max_steps,
        )
        self.scaling_scheduler_args = get_expon_lr_func(
            lr_init=training_args.scaling_lr_init * self.spatial_lr_scale,
            lr_final=training_args.scaling_lr_final * self.spatial_lr_scale,
            max_steps=training_args.scaling_lr_max_steps,
        )
        self.rotation_scheduler_args = get_expon_lr_func(
            lr_init=training_args.rotation_lr_init * self.spatial_lr_scale,
            lr_final=training_args.rotation_lr_final * self.spatial_lr_scale,
            max_steps=training_args.rotation_lr_max_steps,
        )

    def update_learning_rate(self, iteration):
        ''' Learning rate scheduling per step '''
        for param_group in self.optimizer.param_groups:
            if param_group["name"] == "xyz":
                lr = self.xyz_scheduler_args(iteration)
                param_group["lr"] = lr
            if param_group["name"] == "opacity":
                lr = self.opacity_scheduler_args(iteration)
                param_group["lr"] = lr
            if param_group["name"] == "scaling":
                lr = self.scaling_scheduler_args(iteration)
                param_group["lr"] = lr
            if param_group["name"] == "rotation":
                lr = self.rotation_scheduler_args(iteration)
                param_group["lr"] = lr
                

    def construct_list_of_attributes(self):
        l = ['x', 'y', 'z']
        l.append('opacity')
        for i in range(self._scaling.shape[1]):
            l.append('scale_{}'.format(i))
        for i in range(self._rotation.shape[1]):
            l.append('rot_{}'.format(i))
        return l

    def save_ply(self, path, offset=None):
        mkdir_p(os.path.dirname(path))

        xyz = self._xyz.detach().cpu().numpy()

        if offset is not None: # offset for chunks
            # ensure offset is a numpy array
            if isinstance(offset, torch.Tensor):
                offset = offset.detach().cpu().numpy()
            # ensure it's shape (3,)
            offset = np.asarray(offset).reshape(1, 3)
            # apply offset by broadcasting
            xyz += offset

        opacities = self._opacity.detach().cpu().numpy()
        scale = self._scaling.detach().cpu().numpy()

        rotation = self._rotation.detach().cpu().numpy()

        dtype_full = [(attribute, 'f4') for attribute in self.construct_list_of_attributes()]

        elements = np.empty(xyz.shape[0], dtype=dtype_full)
        
        attributes = np.concatenate((xyz, opacities, scale, rotation), axis=1)
        elements[:] = list(map(tuple, attributes))
        el = PlyElement.describe(elements, 'vertex')
        PlyData([el]).write(path)

    def reset_opacity(self):
        opacities_new = inverse_sigmoid(torch.min(self.get_opacity, torch.ones_like(self.get_opacity)*2/255))
        optimizable_tensors = self.replace_tensor_to_optimizer(opacities_new, "opacity")
        self._opacity = optimizable_tensors["opacity"]
        
    def load_ply(self, path):
        plydata = PlyData.read(path)

        xyz = np.stack((np.asarray(plydata.elements[0]["x"]),
                        np.asarray(plydata.elements[0]["y"]),
                        np.asarray(plydata.elements[0]["z"])),  axis=1)
        opacities = np.asarray(plydata.elements[0]["opacity"])[..., np.newaxis]

        scale_names = [p.name for p in plydata.elements[0].properties if p.name.startswith("scale_")]
        scale_names = sorted(scale_names, key = lambda x: int(x.split('_')[-1]))
        scales = np.zeros((xyz.shape[0], len(scale_names)))
        for idx, attr_name in enumerate(scale_names):
            scales[:, idx] = np.asarray(plydata.elements[0][attr_name])

        rot_names = [p.name for p in plydata.elements[0].properties if p.name.startswith("rot")]
        rot_names = sorted(rot_names, key = lambda x: int(x.split('_')[-1]))
        rots = np.zeros((xyz.shape[0], len(rot_names)))
        for idx, attr_name in enumerate(rot_names):
            rots[:, idx] = np.asarray(plydata.elements[0][attr_name])
        
        self._xyz = nn.Parameter(torch.tensor(xyz, dtype=torch.float, device="cuda").requires_grad_(True))
        self._opacity = nn.Parameter(torch.tensor(opacities, dtype=torch.float, device="cuda").requires_grad_(True))
        self._scaling = nn.Parameter(torch.tensor(scales, dtype=torch.float, device="cuda").requires_grad_(True))
        self._rotation = nn.Parameter(torch.tensor(rots, dtype=torch.float, device="cuda").requires_grad_(True))
        
        self.max_radii2D = torch.zeros((xyz.shape[0]), device="cuda")
        self.xyz_gradient_accum = torch.zeros((xyz.shape[0], 1), device="cuda")
        self.denom = torch.zeros((xyz.shape[0], 1), device="cuda")


    def replace_tensor_to_optimizer(self, tensor, name):
        optimizable_tensors = {}
        for group in self.optimizer.param_groups:
            if group["name"] == name:
                stored_state = self.optimizer.state.get(group['params'][0], None)
                stored_state["exp_avg"] = torch.zeros_like(tensor)
                stored_state["exp_avg_sq"] = torch.zeros_like(tensor)

                del self.optimizer.state[group['params'][0]]
                group["params"][0] = nn.Parameter(tensor.requires_grad_(True))
                self.optimizer.state[group['params'][0]] = stored_state

                optimizable_tensors[group["name"]] = group["params"][0]
        return optimizable_tensors

    def _prune_optimizer(self, mask):
        optimizable_tensors = {}
        for group in self.optimizer.param_groups:
            stored_state = self.optimizer.state.get(group['params'][0], None)
            if stored_state is not None:
                stored_state["exp_avg"] = stored_state["exp_avg"][mask]
                stored_state["exp_avg_sq"] = stored_state["exp_avg_sq"][mask]

                del self.optimizer.state[group['params'][0]]
                group["params"][0] = nn.Parameter((group["params"][0][mask].requires_grad_(True)))
                self.optimizer.state[group['params'][0]] = stored_state

                optimizable_tensors[group["name"]] = group["params"][0]
            else:
                group["params"][0] = nn.Parameter(group["params"][0][mask].requires_grad_(True))
                optimizable_tensors[group["name"]] = group["params"][0]
        return optimizable_tensors

    def prune_points(self, mask):
        valid_points_mask = ~mask
        optimizable_tensors = self._prune_optimizer(valid_points_mask)

        self._xyz = optimizable_tensors["xyz"]
        self._opacity = optimizable_tensors["opacity"]
        self._scaling = optimizable_tensors["scaling"]
        self._rotation = optimizable_tensors["rotation"]

        self.xyz_gradient_accum = self.xyz_gradient_accum[valid_points_mask]

        self.denom = self.denom[valid_points_mask]
        self.max_radii2D = self.max_radii2D[valid_points_mask]

    def cat_tensors_to_optimizer(self, tensors_dict):
        optimizable_tensors = {}
        for group in self.optimizer.param_groups:
            assert len(group["params"]) == 1
            extension_tensor = tensors_dict[group["name"]]
            stored_state = self.optimizer.state.get(group['params'][0], None)
            if stored_state is not None:

                stored_state["exp_avg"] = torch.cat((stored_state["exp_avg"], torch.zeros_like(extension_tensor)), dim=0)
                stored_state["exp_avg_sq"] = torch.cat((stored_state["exp_avg_sq"], torch.zeros_like(extension_tensor)), dim=0)

                del self.optimizer.state[group['params'][0]]
                group["params"][0] = nn.Parameter(torch.cat((group["params"][0], extension_tensor), dim=0).requires_grad_(True))
                self.optimizer.state[group['params'][0]] = stored_state

                optimizable_tensors[group["name"]] = group["params"][0]
            else:
                group["params"][0] = nn.Parameter(torch.cat((group["params"][0], extension_tensor), dim=0).requires_grad_(True))
                optimizable_tensors[group["name"]] = group["params"][0]

        return optimizable_tensors

    def densification_postfix(self, new_xyz, new_opacities, new_scaling, new_rotation):
        d = {"xyz": new_xyz,
        "opacity": new_opacities,
        "scaling" : new_scaling,
        "rotation" : new_rotation}

        optimizable_tensors = self.cat_tensors_to_optimizer(d)
        self._xyz = optimizable_tensors["xyz"]
        self._opacity = optimizable_tensors["opacity"]
        self._scaling = optimizable_tensors["scaling"]
        self._rotation = optimizable_tensors["rotation"]

        self.xyz_gradient_accum = torch.zeros((self.get_xyz.shape[0], 1), device="cuda")
        self.denom = torch.zeros((self.get_xyz.shape[0], 1), device="cuda")
        self.max_radii2D = torch.zeros((self.get_xyz.shape[0]), device="cuda")

    def densify_and_split(self, grads, grad_threshold, scene_extent, N=2):
        n_init_points = self.get_xyz.shape[0]
        # Extract points that satisfy the gradient condition
        
        padded_grad = torch.zeros((n_init_points), device="cuda")
        padded_grad[:grads.shape[0]] = grads.squeeze()
        
        selected_pts_mask = torch.where(padded_grad >= grad_threshold, True, False)
        selected_pts_mask = torch.logical_and(selected_pts_mask,
                                              torch.max(self.get_scaling, dim=1).values > self.percent_dense*scene_extent)

        stds = self.get_scaling[selected_pts_mask].repeat(N,1)
        means =torch.zeros((stds.size(0), 3),device="cuda")

        max_scale_idx = stds.argmax(dim=1)  # (1000,) 각 샘플에서 가장 큰 축 인덱스
        stds_zeroed = torch.zeros_like(stds)  
        stds_zeroed[torch.arange(stds.size(0)), max_scale_idx] = stds[torch.arange(stds.size(0)), max_scale_idx]
        
        samples = torch.normal(mean=means, std=stds_zeroed)
        rots = build_rotation(self._rotation[selected_pts_mask]).repeat(N,1,1)

        new_xyz = torch.bmm(rots, samples.unsqueeze(-1)).squeeze(-1) + self.get_xyz[selected_pts_mask].repeat(N, 1)
        new_scaling = self.scaling_inverse_activation(self.get_scaling[selected_pts_mask].repeat(N,1) / (0.8*N))
        new_rotation = self._rotation[selected_pts_mask].repeat(N,1)
        new_opacity = self._opacity[selected_pts_mask].repeat(N,1)

        self.densification_postfix(new_xyz, new_opacity, new_scaling, new_rotation)

        prune_filter = torch.cat((selected_pts_mask, torch.zeros(N * selected_pts_mask.sum(), device="cuda", dtype=bool)))
        self.prune_points(prune_filter)

    def densify_and_clone(self, grads, grad_threshold, scene_extent):
        # Extract points that satisfy the gradient condition
        selected_pts_mask = torch.where(torch.norm(grads, dim=-1) >= grad_threshold, True, False) 
        selected_pts_mask = torch.logical_and(selected_pts_mask,
                                              torch.max(self.get_scaling, dim=1).values <= self.percent_dense*scene_extent)
        
        #print("# of clone",selected_pts_mask.sum().item())

        stds = self.get_scaling[selected_pts_mask].repeat(1,1)
        means =torch.zeros((stds.size(0), 3),device="cuda")

        max_scale_idx = stds.argmax(dim=1)  # (1000,) 각 샘플에서 가장 큰 축 인덱스
        stds_zeroed = torch.zeros_like(stds)  
        stds_zeroed[torch.arange(stds.size(0)), max_scale_idx] = stds[torch.arange(stds.size(0)), max_scale_idx]
        samples = torch.normal(mean=means, std=stds_zeroed)
        #samples = torch.normal(mean=means, std=stds)
        rots = build_rotation(self._rotation[selected_pts_mask]).repeat(1,1,1)


        new_xyz = torch.bmm(rots, samples.unsqueeze(-1)).squeeze(-1) + self.get_xyz[selected_pts_mask].repeat(1, 1)
        new_opacities = self._opacity[selected_pts_mask]
        new_scaling = self._scaling[selected_pts_mask]
        new_rotation = self._rotation[selected_pts_mask]

        self.densification_postfix(new_xyz, new_opacities, new_scaling, new_rotation)

    def densify_and_prune(self, max_grad, min_opacity, extent, max_screen_size, bbox, iter, chunk_size=None):
        grads = self.xyz_gradient_accum / self.denom
        grads[grads.isnan()] = 0.0
        
        # print('Before densification, # of points:', self.get_xyz.shape[0])
        self.densify_and_clone(grads, max_grad, extent)
        self.densify_and_split(grads, max_grad, extent)
        # print('After densification, # of points:', self.get_xyz.shape[0])

        prune_mask = (self.get_opacity < min_opacity).squeeze()

        xyz = self.get_xyz

        if chunk_size is None:
            chunk_size = 2.0 # default (no chunking)
        half = chunk_size / 2.0

        # chunk / full 학습 일반화
        prune_mask_bbox = ( 
            (xyz[:, 0] <  half*-1.0)
            | (xyz[:, 0] >  half*1.0)
            | (xyz[:, 1] <  half*-self.y_resol/self.x_resol)
            | (xyz[:, 1] >  half*self.y_resol/self.x_resol)
            | (xyz[:, 2] <  half*-self.z_resol/self.y_resol)
            | (xyz[:, 2] >  half*self.z_resol/self.y_resol)               
        )

        prune_mask = prune_mask | prune_mask_bbox


        if max_screen_size:
            # print('max screen size :')
            # print(self.get_scaling.max(dim=1).values)
            # big_points_ws = self.get_scaling.max(dim=1).values > 0.05 * extent  # neuron은 0.05
            big_points_ws = self.get_scaling.max(dim=1).values > 0.1 * extent 
            prune_mask = torch.logical_or(prune_mask, big_points_ws)

        # print('Before prune, # of points:', self.get_xyz.shape[0])
        self.prune_points(prune_mask)
        # print('After prune, # of points:', self.get_xyz.shape[0])
        #print(torch.max(self.max_radii2D))
        #print(max(self.get_scaling.max(dim=1).values))
        torch.cuda.empty_cache()

    def add_densification_stats(self, viewspace_point_tensor, update_filter):
        #self.xyz_gradient_accum[update_filter] += torch.norm(viewspace_point_tensor.grad[update_filter,:2], dim=-1, keepdim=True)
        self.xyz_gradient_accum[update_filter] += torch.norm(viewspace_point_tensor.grad[update_filter,:3], dim=-1, keepdim=True)
        self.denom[update_filter] += 1

    def prune_gaussians(self, percent, import_score: list):
        sorted_tensor, _ = torch.sort(import_score, dim=0)
        index_nth_percentile = int(percent * (sorted_tensor.shape[0] - 1))
        value_nth_percentile = sorted_tensor[index_nth_percentile]
        prune_mask = (import_score <= value_nth_percentile).squeeze()
        self.prune_points(prune_mask)

    def prune_out_bbox(self, chunk_size=None):
        xyz = self.get_xyz

        if chunk_size is None:
            chunk_size = 2.0 # default
        half = chunk_size / 2.0
        half = half + chunk_size * 0.1  # add some overlap

        # chunk / full 학습 일반화
        prune_mask_bbox = ( 
            (xyz[:, 0] <  half*-1.0)
            | (xyz[:, 0] >  half*1.0)
            | (xyz[:, 1] <  half*-self.y_resol/self.x_resol)
            | (xyz[:, 1] >  half*self.y_resol/self.x_resol)
            | (xyz[:, 2] <  half*-self.z_resol/self.y_resol)
            | (xyz[:, 2] >  half*self.z_resol/self.y_resol)               
        )

        self.prune_points(prune_mask_bbox)
        torch.cuda.empty_cache()
        print('Number of primitives after pruning out bbox:',self.get_xyz.shape[0])

    def prune_gaussians_zeros(self, gaussian_counts: list):
        # print('before prune zeros:', self.get_xyz.shape[0])
        prune_mask = (gaussian_counts.int() == 0).squeeze()
        self.prune_points(prune_mask)
        # print('after prune zeros:', self.get_xyz.shape[0])

    def prune_dark_gaussians(self):
        # print('before prune dark:', self.get_xyz.shape[0])
        opacity = self.get_opacity
        prune_mask_bbox = (opacity < 1/255).squeeze()
        

        self.prune_points(prune_mask_bbox)
        torch.cuda.empty_cache()
        # print('get_xyz.shape[0]',self.get_xyz.shape[0])
        # print('after prune dark:',' self.get_xyz.shape[0])

    def prune_FA_gaussians(self):
        FA = compute_fa(self.get_scaling)
        prune_mask_bbox = (FA < 0.75).squeeze()
        

        self.prune_points(prune_mask_bbox)
        torch.cuda.empty_cache()
        print('get_xyz.shape[0]',self.get_xyz.shape[0])

    def create_random_onthefly(self, num_start : int, spatial_lr_scale : float, chunk_len : float):
            self.spatial_lr_scale = spatial_lr_scale
            print(spatial_lr_scale)
            num_pts = num_start
            print(f"Generating random point cloud ({num_pts})...")

            rng = np.random.default_rng(seed=42)

            xyz = rng.random((num_pts, 3)) * 2.0 - 1.0
            if chunk_len != 2.0: # for chunked training, scale to chunk size
                half = chunk_len / 2
                xyz *= half

            fused_point_cloud = torch.tensor(xyz).float().cuda()

            scale = torch.tensor([
                1.0,
                self.y_resol / self.x_resol,
                self.z_resol / self.x_resol
            ], device=fused_point_cloud.device)

            fused_point_cloud = fused_point_cloud * scale
            
            print("Number of points at initialisation : ", fused_point_cloud.shape[0])
            print("Initialized xyz range: ", fused_point_cloud.min(dim=0)[0], fused_point_cloud.max(dim=0)[0])

            dist2 = torch.clamp_min(distCUDA2(torch.from_numpy(xyz).float().cuda()), 0.0000001)
            scales = torch.log(torch.sqrt(dist2))[...,None].repeat(1, 3)
            rots = torch.zeros((fused_point_cloud.shape[0], 4), device="cuda")
            rots[:, 0] = 1

            opacities = inverse_sigmoid(0.1 * torch.ones((fused_point_cloud.shape[0], 1), dtype=torch.float, device="cuda"))

            self._xyz = nn.Parameter((fused_point_cloud).requires_grad_(True))
            self._scaling = nn.Parameter(scales.requires_grad_(True))
            self._rotation = nn.Parameter(rots.requires_grad_(True))
            self._opacity = nn.Parameter(opacities.requires_grad_(True))
            self.max_radii2D = torch.zeros((self.get_xyz.shape[0]), device="cuda")
