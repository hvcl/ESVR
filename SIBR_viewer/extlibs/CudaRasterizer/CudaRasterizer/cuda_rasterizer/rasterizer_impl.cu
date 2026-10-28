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

#include "rasterizer_impl.h"
#include <cuda.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cub/cub.cuh>
#include <cub/device/device_radix_sort.cuh>
#define GLM_FORCE_CUDA
#include <glm/glm.hpp>

#include <cooperative_groups.h>
#include <cooperative_groups/reduce.h>
namespace cg = cooperative_groups;

#include "auxiliary.h"
#include "forward.h"
#include "backward.h"

// Helper function to find the next-highest bit of the MSB
// on the CPU.
uint32_t getHigherMsb(uint32_t n)
{
	uint32_t msb = sizeof(n) * 4;
	uint32_t step = msb;
	while (step > 1)
	{
		step /= 2;
		if (n >> msb)
			msb += step;
		else
			msb -= step;
	}
	if (n >> msb)
		msb++;
	return msb;
}

// Wrapper method to call auxiliary coarse frustum containment test.
// Mark all Gaussians that pass it.
__global__ void checkFrustum(int P,
	const float* orig_points,
	const float* viewmatrix,
	const float* projmatrix,
	bool* present)
{
	auto idx = cg::this_grid().thread_rank();
	if (idx >= P)
		return;

	float3 p_view;
	present[idx] = in_frustum(idx, orig_points, viewmatrix, projmatrix, false, p_view);
}


__global__ void duplicateWithKeys3D(
    int P,
    const float2* points_xy,
    const float* depths,
	const float* covzs,
    const uint32_t* offsets,
    uint64_t* gaussian_keys_unsorted,
    uint32_t* gaussian_values_unsorted,
    int* radii,
    dim3 tile_grid,
    int depth_bins,
    int2* rects)
{
    auto idx = cg::this_grid().thread_rank();
    if (idx >= P)
        return;

    if (radii[idx] > 0)
    {
        uint32_t off = (idx == 0) ? 0 : offsets[idx - 1];
        uint2 rect_min, rect_max;

        if (rects == nullptr)
            getRect(points_xy[idx], radii[idx], rect_min, rect_max, tile_grid);
        else
            getRect(points_xy[idx], rects[idx], rect_min, rect_max, tile_grid);

        float d = (depths[idx] - 8.26) * 400;
        float covz = covzs[idx];

	if (!isfinite(d)) {
		return; 
	} 

	// Step size unified to 1.0f (unit cube normalized)
	const float RAY_LENGTH = 1024;

	float z_start = max(0.0f, d - 1.42f * sqrtf(covz));
	float z_end = min(RAY_LENGTH -1, d + 1.42f * sqrtf(covz));

	float list_size = RAY_LENGTH / depth_bins;

	int bin_start = int((z_start) / list_size);
	int bin_end = int((z_end) / list_size);
	bin_start = min(depth_bins -1, max(0, bin_start));
	bin_end = max(0, min(depth_bins - 1, bin_end));

	for (int b = bin_start; b <= bin_end; ++b) {
		for (int y = rect_min.y; y < rect_max.y; y++) {
			for (int x = rect_min.x; x < rect_max.x; x++) {
				uint64_t key = b * tile_grid.y * tile_grid.x + y * tile_grid.x + x;

				if (key >= (uint32_t)tile_grid.x * tile_grid.y * depth_bins) {
					continue;
				}

				key <<= 32;
				key |= *((uint32_t*)&depths[idx]);
				gaussian_keys_unsorted[off] = key;
				gaussian_values_unsorted[off] = idx;
				off++; 
			}
		}	
	}


    }
}


// Check keys to see if it is at the start/end of one tile's range in 
// the full sorted list. If yes, write start/end of this tile. 
// Run once per instanced (duplicated) Gaussian ID.
__global__ void identifyTileRanges(int L, uint64_t* point_list_keys, uint2* ranges)
{
	auto idx = cg::this_grid().thread_rank();
	if (idx >= L)
		return;

	// Read tile ID from key. Update start/end of tile range if at limit.
	uint64_t key = point_list_keys[idx];
	uint32_t currtile = key >> 32;
	if (idx == 0)
		ranges[currtile].x = 0;
	else
	{
		uint32_t prevtile = point_list_keys[idx - 1] >> 32;
		if (currtile != prevtile)
		{
			ranges[prevtile].y = idx;
			ranges[currtile].x = idx;
		}
		if (idx == L - 1)
			ranges[currtile].y = L;
	}
}


// Mark Gaussians as visible/invisible, based on view frustum testing
void CudaRasterizer::Rasterizer::markVisible(
	int P,
	float* means3D,
	float* viewmatrix,
	float* projmatrix,
	bool* present)
{
	checkFrustum << <(P + 255) / 256, 256 >> > (
		P,
		means3D,
		viewmatrix, projmatrix,
		present);
}

CudaRasterizer::GeometryState CudaRasterizer::GeometryState::fromChunk(char*& chunk, size_t P)
{
	GeometryState geom;
	obtain(chunk, geom.depths, P, 128);
	obtain(chunk, geom.clamped, P * 3, 128);
	obtain(chunk, geom.internal_radii, P, 128);
	obtain(chunk, geom.means2D, P, 128);
	obtain(chunk, geom.xyz, P, 128);
	obtain(chunk, geom.cov3D, P * 6, 128);
	obtain(chunk, geom.conic_opacity, P * 10, 128);
	obtain(chunk, geom.rgb, P * 3, 128);
	obtain(chunk, geom.covz, P, 128);
	obtain(chunk, geom.tiles_touched, P, 128);
	cub::DeviceScan::InclusiveSum(nullptr, geom.scan_size, geom.tiles_touched, geom.tiles_touched, P);
	obtain(chunk, geom.scanning_space, geom.scan_size, 128);
	obtain(chunk, geom.point_offsets, P, 128);
	return geom;
}

CudaRasterizer::ImageState CudaRasterizer::ImageState::fromChunk(char*& chunk, size_t N)
{
	ImageState img;
	obtain(chunk, img.accum_alpha, N, 128);
	obtain(chunk, img.n_contrib, N, 128);
	obtain(chunk, img.ranges, N, 128);
	return img;
}

CudaRasterizer::BinningState CudaRasterizer::BinningState::fromChunk(char*& chunk, size_t P)
{
	BinningState binning;
	obtain(chunk, binning.point_list, P, 128);
	obtain(chunk, binning.point_list_unsorted, P, 128);
	obtain(chunk, binning.point_list_keys, P, 128);
	obtain(chunk, binning.point_list_keys_unsorted, P, 128);
	cub::DeviceRadixSort::SortPairs(
		nullptr, binning.sorting_size,
		binning.point_list_keys_unsorted, binning.point_list_keys,
		binning.point_list_unsorted, binning.point_list, P);
	obtain(chunk, binning.list_sorting_space, binning.sorting_size, 128);
	return binning;
}

// Forward rendering procedure for differentiable rasterization
// of Gaussians.
int CudaRasterizer::Rasterizer::forward(
	std::function<char* (size_t)> geometryBuffer,
	std::function<char* (size_t)> binningBuffer,
	std::function<char* (size_t)> imageBuffer,
	const int P,
	const int width, int height,
	const float* means3D, 
	const float* opacities,

	const float* transferFunction,
	const float* scales,
	const float scale_modifier,
	const float* rotations,
	const float* viewmatrix,
	const float* projmatrix,
	const float orthoRight,
	const float step_size,
	float* out_color,
	float* partial_rgb_global,
	float* partial_T_global,
	int* rects,
	float* boxmin,
	float* boxmax)
{
	const int depth_bins = DVR_DEPTH_BINS;

	size_t chunk_size = required<GeometryState>(P);
	char* chunkptr = geometryBuffer(chunk_size);
	GeometryState geomState = GeometryState::fromChunk(chunkptr, P);

	int* radii = geomState.internal_radii;
	dim3 tile_grid((width + BLOCK_X - 1) / BLOCK_X, (height + BLOCK_Y - 1) / BLOCK_Y, depth_bins);
	dim3 block(BLOCK_X, BLOCK_Y, 1);

	// Dynamically resize image-based auxiliary buffers during training
	int img_chunk_size = required<ImageState>(width * height * depth_bins);
	char* img_chunkptr = imageBuffer(img_chunk_size);
	ImageState imgState = ImageState::fromChunk(img_chunkptr, width * height* depth_bins);

	float3 minn = { -FLT_MAX, -FLT_MAX, -FLT_MAX };
	float3 maxx = { FLT_MAX, FLT_MAX, FLT_MAX };
	if (boxmin != nullptr)
	{
		minn = *((float3*)boxmin);
		maxx = *((float3*)boxmax);
	}

	FORWARD::preprocess(
	// Transform, cull, and bound each Gaussian.
		P,
		means3D,
		(glm::vec3*)scales,
		scale_modifier,
		(glm::vec4*)rotations,
		opacities,
		viewmatrix, projmatrix,
		width, height,
		orthoRight,
		radii,
		geomState.means2D,
		geomState.depths,
		geomState.cov3D,
		geomState.conic_opacity,
		geomState.covz,
		tile_grid,
		geomState.tiles_touched,
		(int2*)rects,
		minn,
		maxx
	);


	// Compute prefix sum over full list of touched tile counts by Gaussians
	// E.g., [2, 3, 0, 2, 1] -> [2, 5, 5, 7, 8]
	cub::DeviceScan::InclusiveSum(geomState.scanning_space, geomState.scan_size,
		geomState.tiles_touched, geomState.point_offsets, P);

	// Retrieve total number of Gaussian instances to launch and resize aux buffers
	int num_rendered;
	cudaMemcpy(&num_rendered, geomState.point_offsets + P - 1, sizeof(int), cudaMemcpyDeviceToHost);

	if (num_rendered == 0)
		return 0;

	int binning_chunk_size = required<BinningState>(num_rendered);
	char* binning_chunkptr = binningBuffer(binning_chunk_size);
	BinningState binningState = BinningState::fromChunk(binning_chunkptr, num_rendered);


	duplicateWithKeys3D<<<(P + 255) / 256, 256>>>(
        P,
        geomState.means2D,
        geomState.depths,
		geomState.covz,
        geomState.point_offsets,
        binningState.point_list_keys_unsorted,
        binningState.point_list_unsorted,
        radii,
        tile_grid,
        depth_bins,
        (int2*)rects);

	int bit = getHigherMsb(tile_grid.x * tile_grid.y * depth_bins);


	cub::DeviceRadixSort::SortPairs(
	binningState.list_sorting_space,
	binningState.sorting_size,
	binningState.point_list_keys_unsorted, binningState.point_list_keys,
	binningState.point_list_unsorted, binningState.point_list,
	num_rendered, 32, 32+bit);

	cudaMemset(imgState.ranges, 0, tile_grid.x * tile_grid.y * depth_bins * sizeof(uint2));

	// Identify start and end of per-tile workloads in sorted list
	
	identifyTileRanges << <(num_rendered + 255) / 256, 256 >> > (
		num_rendered,
		binningState.point_list_keys,
		imgState.ranges
		);

	// Let each tile blend its range of Gaussians independently in parallel
	FORWARD::render(
		tile_grid, block,
		imgState.ranges,
		binningState.point_list,
		width, height, 
		step_size,
		geomState.means2D,
		transferFunction,
		partial_rgb_global,
		partial_T_global,
		geomState.conic_opacity,
		geomState.depths,
		geomState.covz);

	dim3 tile_grid1((width + BLOCK_X - 1) / BLOCK_X, (height + BLOCK_Y - 1) / BLOCK_Y, 1);
	dim3 block1(BLOCK_X, BLOCK_Y, 1);

	FORWARD::blendZBins(
	tile_grid1, block1,
	partial_rgb_global,
	partial_T_global,
	out_color,
	width, height, depth_bins
	);

	return num_rendered;
}

// Produce necessary gradients for optimization, corresponding
// to forward render pass
void CudaRasterizer::Rasterizer::backward(
	const int P, int D, int M, int R,
	const float* background,
	const int width, int height,
	const float* means3D,
	const float* shs,
	const float* colors_precomp,
	const float* scales,
	const float scale_modifier,
	const float* rotations,
	const float* cov3D_precomp,
	const float* viewmatrix,
	const float* projmatrix,
	const float* campos,
	const float tan_fovx, float tan_fovy,
	const int* radii,
	char* geom_buffer,
	char* binning_buffer,
	char* img_buffer,
	const float* dL_dpix,
	float* dL_dmean2D,
	float* dL_dconic,
	float* dL_dopacity,
	float* dL_dcolor,
	float* dL_dmean3D,
	float* dL_dcov3D,
	float* dL_dsh,
	float* dL_dscale,
	float* dL_drot)
{
	GeometryState geomState = GeometryState::fromChunk(geom_buffer, P);
	BinningState binningState = BinningState::fromChunk(binning_buffer, R);
	ImageState imgState = ImageState::fromChunk(img_buffer, width * height);

	if (radii == nullptr)
	{
		radii = geomState.internal_radii;
	}

	const float focal_y = height / (2.0f * tan_fovy);
	const float focal_x = width / (2.0f * tan_fovx);

	const dim3 tile_grid((width + BLOCK_X - 1) / BLOCK_X, (height + BLOCK_Y - 1) / BLOCK_Y, 1);
	const dim3 block(BLOCK_X, BLOCK_Y, 1);

	// Compute loss gradients w.r.t. 2D mean position, conic matrix,
	// opacity and RGB of Gaussians from per-pixel loss gradients.
	// If we were given precomputed colors and not SHs, use them.
	const float* color_ptr = (colors_precomp != nullptr) ? colors_precomp : geomState.rgb;


	// Take care of the rest of preprocessing. Was the precomputed covariance
	// given to us or a scales/rot pair? If precomputed, pass that. If not,
	// use the one we computed ourselves.
	const float* cov3D_ptr = (cov3D_precomp != nullptr) ? cov3D_precomp : geomState.cov3D;
	BACKWARD::preprocess(P, D, M,
		(float3*)means3D,
		radii,
		shs,
		geomState.clamped,
		(glm::vec3*)scales,
		(glm::vec4*)rotations,
		scale_modifier,
		cov3D_ptr,
		viewmatrix,
		projmatrix,
		focal_x, focal_y,
		tan_fovx, tan_fovy,
		(glm::vec3*)campos,
		(float3*)dL_dmean2D,
		dL_dconic,
		(glm::vec3*)dL_dmean3D,
		dL_dcolor,
		dL_dcov3D,
		dL_dsh,
		(glm::vec3*)dL_dscale,
		(glm::vec4*)dL_drot);
}
