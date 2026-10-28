/*
 * Copyright (C) 2023, Inria
 * GRAPHDECO research group, https://team.inria.fr/graphdeco
 * All rights reserved.
 *
 * This software is free for non-commercial, research and evaluation use 
 * under the terms of the LICENSE.md file.
 *
 * For inquiries contact  george.drettakis@inria.fr
 */

#ifndef CUDA_RASTERIZER_FORWARD_H_INCLUDED
#define CUDA_RASTERIZER_FORWARD_H_INCLUDED

#include <cuda.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#define GLM_FORCE_CUDA
#include <glm/glm.hpp>

namespace FORWARD
{
	// Perform initial steps for each Gaussian prior to rasterization.
	void preprocess(int P,
		const float* orig_points,
		const glm::vec3* scales,
		const float scale_modifier,
		const glm::vec4* rotations,
		const float* opacities,
		const float* viewmatrix,
		const float* projmatrix,
		const int W, int H,
		const float orthoRight,
		int* radii,
		float2* points_xy_image,
		float* depths,
		float* cov3Ds,
		float* conic_opacity,
		float* covzs,
		const dim3 grid,
		uint32_t* tiles_touched,
		int2* rects,
		float3 boxmin,
		float3 boxmax);

	// Main rasterization method.
	void render(
		const dim3 grid, dim3 block,
		const uint2* ranges,
		const uint32_t* point_list,
		int W, int H,
		const float step_size,
		const float2* points_xy_image,
		const float* transferFunction,
		float* partial_rgb_global,
		float* partial_T_global,
		const float* conic_opacity,
		const float* depths,
		const float* covzs);

	void blendZBins(
		const dim3 grid, dim3 block,
		const float* partial_rgb_global,
		const float* partial_T_global,
		float* out_color,
		int W, int H, int depth_bins
	);

}


#endif
