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

 #include "forward.h"
 #include "auxiliary.h"
 #include <cooperative_groups.h>
 #include <cooperative_groups/reduce.h>
 #include <cmath>
 namespace cg = cooperative_groups;
 

template <typename T>
__host__ __device__ T clamp(T value, T min, T max) {
	return (value < min) ? min : (value > max) ? max : value;
}
 
// Compute color from transfer function given alpha value
__device__ glm::vec4 computeColorFromTF(const float alpha, const float* TF)
{

	//glm::vec3* sh = ((glm::vec3*)shs) + idx * max_coeffs;
	float intensityFloat = clamp(alpha* 255.0f, 0.0f, 255.0f);
	int intensityBase = static_cast<int>(intensityFloat);
	float t = intensityFloat - intensityBase;

	// Clamp the upper lookup-table index.
	int nextIntensity = clamp(intensityBase + 1, 0, 255);

	// Fetch the neighboring transfer-function entries.
	glm::vec4 color1(
		TF[intensityBase * 4 + 0], 
		TF[intensityBase * 4 + 1], 
		TF[intensityBase * 4 + 2], 
		TF[intensityBase * 4 + 3]
	);

	glm::vec4 color2(
		TF[nextIntensity * 4 + 0], 
		TF[nextIntensity * 4 + 1], 
		TF[nextIntensity * 4 + 2], 
		TF[nextIntensity * 4 + 3]
	);

	// Linearly interpolate between the entries.
	glm::vec4 result = (1.0f - t) * color1 + t * color2;
	
	return glm::max(result, 0.0f);
}

// Forward method for converting scale and rotation properties of each
// Gaussian to a 3D covariance matrix in world space. Also takes care
// of quaternion normalization.
__device__ void computeCov3D(const glm::vec3 scale, float mod, const glm::vec4 rot, float* cov3D)
{
	// Create scaling matrix
	glm::mat3 S = glm::mat3(1.0f);
	S[0][0] = mod * scale.x;
	S[1][1] = mod * scale.y;
	S[2][2] = mod * scale.z;

	// Normalize quaternion to get valid rotation
	glm::vec4 q = rot;// / glm::length(rot);
	float r = q.x;
	float x = q.y;
	float y = q.z;
	float z = q.w;

	// Compute rotation matrix from quaternion
	glm::mat3 R = glm::mat3(
		1.f - 2.f * (y * y + z * z), 2.f * (x * y - r * z), 2.f * (x * z + r * y),
		2.f * (x * y + r * z), 1.f - 2.f * (x * x + z * z), 2.f * (y * z - r * x),
		2.f * (x * z - r * y), 2.f * (y * z + r * x), 1.f - 2.f * (x * x + y * y)
	);

	glm::mat3 M = S * R;

	// Compute 3D world covariance matrix Sigma
	glm::mat3 Sigma = glm::transpose(M) * M;

	// Covariance is symmetric, only store upper right
	cov3D[0] = Sigma[0][0];
	cov3D[1] = Sigma[0][1];
	cov3D[2] = Sigma[0][2];
	cov3D[3] = Sigma[1][1];
	cov3D[4] = Sigma[1][2];
	cov3D[5] = Sigma[2][2];
}


//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////


// Perform initial steps for each Gaussian prior to rasterization.
__global__ void preprocessCUDA(int P,
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
	float3 boxmax)
{
	auto idx = cg::this_grid().thread_rank(); // One thread processes one Gaussian.
	if (idx >= P)
		return;

	// if (idx >= 10000)
	// 	return;

	// Initialize radius and touched tiles to 0. If this isn't changed,
	// this Gaussian will not be processed further.
	radii[idx] = 0;
	tiles_touched[idx] = 0;

	// Perform near culling, quit if outside.
	float3 p_view;
	if (!in_frustum(idx, orig_points, viewmatrix, projmatrix, false, p_view)){
		return;
	}

	// Transform point by projecting
	float3 p_orig = { orig_points[3 * idx], orig_points[3 * idx + 1], orig_points[3 * idx + 2] };

	if (p_orig.x < boxmin.x || p_orig.y < boxmin.y || p_orig.z < boxmin.z ||
		p_orig.x > boxmax.x || p_orig.y > boxmax.y || p_orig.z > boxmax.z)
		return;

	float4 p_hom = transformPoint4x4(p_orig, projmatrix);
	float p_w = 1.0f / (p_hom.w + 0.0000001f);
	float3 p_proj = { p_hom.x * p_w, p_hom.y * p_w, p_hom.z * p_w };

	computeCov3D(scales[idx], scale_modifier, rotations[idx], cov3Ds + idx * 6);
	const float* cov3D = cov3Ds + idx * 6;


	constexpr float renderWidth = 800.0f;
	float scale_x = renderWidth / (2.0f * orthoRight);
	glm::mat3 J = glm::mat3( 
		scale_x, 0.0f, 0.0f,
		0.0f, scale_x, 0.0f,
		0.0f, 0.0f, 400.0f); 

	glm::mat3 View = glm::mat3(
		viewmatrix[0], viewmatrix[4], viewmatrix[8],
		viewmatrix[1], viewmatrix[5], viewmatrix[9],
		viewmatrix[2], viewmatrix[6], viewmatrix[10]);

	glm::mat3 T = View * J;

	glm::mat3 Vrk = glm::mat3(
		cov3D[0], cov3D[1], cov3D[2],
		cov3D[1], cov3D[3], cov3D[4],
		cov3D[2], cov3D[4], cov3D[5]);

	glm::mat3 cov = glm::transpose(T) * glm::transpose(Vrk) * T;
	
	float hata = cov[0][0];
	float hatb = cov[0][1];
	float hatc = cov[0][2];
	float hatd = cov[1][1];
	float hate = cov[1][2];
	float hatf = cov[2][2];	
	
	float det = hata * hatd * hatf + 2 * hatb * hatc * hate - hata * hate * hate - hatf * hatb * hatb - hatd * hatc * hatc;
	float max_diag = fmaxf(fmaxf(fabsf(hata), fabsf(hatd)), fabsf(hatf));
	float det_eps = fmaxf(1e-12f * max_diag * max_diag * max_diag, 1e-20f);
	if (!isfinite(det) || det <= det_eps)
		return;
	if (det == 0.0f)
		return;
	float det_inv = 1.f / det;
	float inv_a = (hatd * hatf - hate * hate) * det_inv;
	float inv_b = (hatc * hate - hatb * hatf) * det_inv;
	float inv_c = (hatb * hate - hatc * hatd) * det_inv;
	float inv_d = (hata * hatf - hatc * hatc) * det_inv;
	float inv_e = (hatb * hatc - hata * hate) * det_inv;
	float inv_f = (hata * hatd - hatb * hatb) * det_inv;
	// Compute extent in screen space (by finding eigenvalues of
	// 2D covariance matrix). Use extent to compute a bounding rectangle
	// of screen-space tiles that this Gaussian overlaps with. Quit if
	// rectangle covers 0 tiles. 

	float my_radius = ceil(1.42f * sqrt(max(hata, hatd)));
	float2 point_image = { ndc2Pix(p_proj.x, W), ndc2Pix(p_proj.y, H) };
	uint2 rect_min, rect_max;

	if (rects == nullptr) 	// More conservative
	{
		getRect(point_image, my_radius, rect_min, rect_max, grid);
	}
	else // Slightly more aggressive, might need a math cleanup
	{
		const int2 my_rect = { (int)ceil(1.42f * sqrt(hata)), (int)ceil(1.42f * sqrt(hatd)) };
		rects[idx] = my_rect;
		getRect(point_image, my_rect, rect_min, rect_max, grid);
	}

	if ((rect_max.x - rect_min.x) * (rect_max.y - rect_min.y) == 0)
		return;
	
	
	// Store some useful helper data for the next steps.
	depths[idx] = p_view.z;
	radii[idx] = my_radius;
	points_xy_image[idx] = point_image;
	// Inverse 2D covariance and opacity neatly pack into one float4

	conic_opacity[idx * 7 + 0] = inv_a;
	conic_opacity[idx * 7 + 1] = inv_b;
	conic_opacity[idx * 7 + 2] = inv_c;
	conic_opacity[idx * 7 + 3] = inv_d;
	conic_opacity[idx * 7 + 4] = inv_e;
	conic_opacity[idx * 7 + 5] = inv_f;
	conic_opacity[idx * 7 + 6] = opacities[idx];		

	float d = ( p_view.z  - 8.26) * 400;
	float covz = hatf;
	const int depth_bins = DVR_DEPTH_BINS;
	const float RAY_LENGTH = (float)DVR_RAY_LENGTH_UNITS;

	float z_start = max(0.0f, d - 1.42f * sqrtf(covz));
	float z_end   = min(RAY_LENGTH - 1.0f, d + 1.42f * sqrtf(covz));
	float list_size = RAY_LENGTH / depth_bins;  // grid.z = depth_bins

	int bin_start = int(z_start / list_size);
	int bin_end   = int(z_end   / list_size);
	bin_start = min(depth_bins -1, max(0, bin_start));
	bin_end = max(0, min(depth_bins - 1, bin_end));

	int num_bins = bin_end - bin_start + 1;
	int num_tiles = (rect_max.y - rect_min.y) * (rect_max.x - rect_min.x);

	tiles_touched[idx] = num_bins * num_tiles;
	covzs[idx] = hatf;
 }
 

 template <uint32_t CHANNELS>
__global__ void __launch_bounds__(BLOCK_X * BLOCK_Y) renderCUDA(
	const uint2* __restrict__ ranges,
	const uint32_t* __restrict__ point_list,
	int W, int H,
	const float step_size,
	const float2* __restrict__ points_xy_image,
	const float* __restrict__ transferFunction,
	float* partial_rgb_global,
	float* partial_T_global,	
	const float* __restrict__ conic_opacity,
	const float* __restrict__ depths,
	const float* __restrict__ covzs
)
{
	// Identify current tile and associated min/max pixel range.
	auto block = cg::this_thread_block();
	uint3 tile_id = block.group_index();
	uint3 local_id = block.thread_index();
	uint2 pix_min = { tile_id.x * BLOCK_X, tile_id.y * BLOCK_Y };
	uint2 pix = { pix_min.x + local_id.x, pix_min.y + local_id.y };
	int z_bin = tile_id.z;
	float2 pixf = { (float)pix.x, (float)pix.y };

	// Check if this thread is associated with a valid pixel or outside.
	bool inside = pix.x < W && pix.y < H;
	// Done threads can help with fetching, but don't rasterize
	bool done = !inside;
	
	int pixel_id = W * pix.y + pix.x;
	int tile_linear_id = z_bin * gridDim.y * gridDim.x + tile_id.y * gridDim.x + tile_id.x;
	uint2 range = ranges[tile_linear_id];

	int rounds = (range.y - range.x + BLOCK_SIZE - 1) / BLOCK_SIZE;
	int toDo = range.y - range.x;


	const int depth_bins = DVR_DEPTH_BINS;

	int base_rgb = pixel_id * depth_bins * CHANNELS + z_bin * CHANNELS;
	int base_T   = pixel_id * depth_bins + z_bin;
	if (toDo==0 || !inside)
	{
		for (int ch = 0; ch < CHANNELS; ch++) {
			partial_rgb_global[base_rgb + ch] = 0;
		}
		partial_T_global[base_T] = 1.0f;  // make it 1 (for "multiplication")
		return;
	}

	// Unified step size = 1.0f (unit cube normalized)
	const float RAY_LENGTH = (float)DVR_RAY_LENGTH_UNITS;
	const float STEP_SIZE = fmaxf(step_size, 0.01f);
	const int THREAD_BIN_COUNT = DVR_THREAD_BIN_COUNT;
	const int THREAD_OFFSET = z_bin * THREAD_BIN_COUNT;

	float hit_list[THREAD_BIN_COUNT] = { 0 };

	// Allocate storage for batches of collectively fetched data.
	__shared__ float2 collected_xy[BLOCK_SIZE];
	__shared__ float collected_conic_a[BLOCK_SIZE];
	__shared__ float collected_conic_b[BLOCK_SIZE];
	__shared__ float collected_conic_c[BLOCK_SIZE];
	__shared__ float collected_conic_d[BLOCK_SIZE];
	__shared__ float collected_conic_e[BLOCK_SIZE];
	__shared__ float collected_conic_f[BLOCK_SIZE];
	__shared__ float collected_o[BLOCK_SIZE];
	__shared__ float collected_depth[BLOCK_SIZE];
	__shared__ float collected_covz[BLOCK_SIZE];

	// Initialize helper variables
	float T = 1.0f;
	for (int i = 0; i < rounds; i++, toDo -= BLOCK_SIZE)
	{
	int num_done = __syncthreads_count(done);
	if (num_done == BLOCK_SIZE)
	break;
	int index = i * BLOCK_SIZE + block.thread_rank();
	if (range.x + index < range.y)
	{
		int gauss_id = point_list[range.x + index];
		collected_xy[block.thread_rank()] = points_xy_image[gauss_id];
		collected_conic_a[block.thread_rank()] = conic_opacity[gauss_id * 7 + 0];
		collected_conic_b[block.thread_rank()] = conic_opacity[gauss_id * 7 + 1];
		collected_conic_c[block.thread_rank()] = conic_opacity[gauss_id * 7 + 2];
		collected_conic_d[block.thread_rank()] = conic_opacity[gauss_id * 7 + 3];
		collected_conic_e[block.thread_rank()] = conic_opacity[gauss_id * 7 + 4];
		collected_conic_f[block.thread_rank()] = conic_opacity[gauss_id * 7 + 5];
		collected_o[block.thread_rank()] = conic_opacity[gauss_id * 7 + 6];
		collected_depth[block.thread_rank()] = depths[gauss_id];
		collected_covz[block.thread_rank()] = covzs[gauss_id];
	}
	block.sync();
	for (int j = 0; !done && j < min(BLOCK_SIZE, toDo); j++) { 
	float depth = (collected_depth[j]- 8.26)*400;
	
	float2 xy = collected_xy[j];

	float covz = collected_covz[j];
	float conic_a = collected_conic_a[j];
	float conic_b = collected_conic_b[j];
	float conic_c = collected_conic_c[j];
	float conic_d = collected_conic_d[j];
	float conic_e = collected_conic_e[j];
	float conic_f = collected_conic_f[j];
	float opa = collected_o[j];


	// Compute the Gaussian's support along the ray.
	float z_start = depth - 1.42f * sqrtf(covz);
	float z_end = depth + 1.42f * sqrtf(covz);

	const int total_sample_count = (int)ceilf(RAY_LENGTH / STEP_SIZE);

	const int support_start = max(0, (int)ceilf(z_start / STEP_SIZE));
	const int support_end = min(total_sample_count, (int)floorf(z_end / STEP_SIZE) + 1); 

	const int bin_sample_start = max(0, (int)ceilf((float)THREAD_OFFSET / STEP_SIZE));
	const int bin_sample_end = min(total_sample_count, (int)ceilf((float)(THREAD_OFFSET + THREAD_BIN_COUNT) / STEP_SIZE));

	// Sample only the intersection of the Gaussian support and this depth bin.
	const int sample_start = max(support_start, bin_sample_start);
	const int sample_end = min(support_end, bin_sample_end);

	for (int sample_idx = sample_start; sample_idx < sample_end; ++sample_idx) {
		const float sample_z = sample_idx * STEP_SIZE;
		const int local_bin = static_cast<int>(floorf(sample_z)) - THREAD_OFFSET;
		if (local_bin < 0 || local_bin >= THREAD_BIN_COUNT)
			continue;

		// sample_z is the global depth; local_bin indexes this thread's depth segment.

		float3 d = { xy.x - pixf.x, xy.y - pixf.y, depth - sample_z };
		//float power = - 0.5 * (conic_a * d.x * d.x + conic_d * d.y * d.y + conic_f * d.z * d.z) - conic_b * d.x * d.y - conic_c * d.x * d.z - conic_e * d.y * d.z;
		float power =  (conic_a * d.x * d.x + conic_d * d.y * d.y + conic_f * d.z * d.z) + 2 * (conic_b * d.x * d.y + conic_c * d.x * d.z + conic_e * d.y * d.z); // new evaluation for (x-d).T A (x-d) 
		if (power > 2.0f)
		continue;

		float k = 5;
		float input = k * (1.0f - power);
		float sigmoid = 1.0f / (1.0f + expf(-1 * input));  // σ(k(1-Ad))
		float alpha = opa * sigmoid;

		if (alpha < 1.0f / 255.0f)
		continue;

		hit_list[local_bin] += alpha;
	}	
	}
	}



	float local_rgb[CHANNELS] = {0};
	for (int i = 0; i < THREAD_BIN_COUNT; ++i) {
		float a = hit_list[i];
		if (a < 1.0f / 255.0f) 
		continue;
		glm::vec4 col = computeColorFromTF(a, transferFunction);
		float alpha = min(0.99f, col.a);
		if (alpha < 1.0f / 255.0f)
		continue;

		float testT = T * (1 - alpha);

		for (int c = 0; c < CHANNELS; ++c)
		local_rgb[c] += col[c] * alpha * T;

		if (testT < 0.001f) 
		break;

		T = testT;
	}


	for (int c = 0; c < CHANNELS; ++c) {
		partial_rgb_global[base_rgb + c] = local_rgb[c];
	}
	partial_T_global[base_T] = T;

}




template <uint32_t CHANNELS>
__global__ void blendZBinsCUDA(
    const float* __restrict__ partial_rgb_global,  // [W*H * depth_bins * CHANNELS]
    const float* __restrict__ partial_T_global,    // [W*H * depth_bins]
	float* __restrict__ out_color,                 // [3 * W * H] RGB
    int W, int H, int depth_bins
) {

	auto block = cg::this_thread_block();
	uint3 tile_id = block.group_index();
	uint3 local_id = block.thread_index();
	uint2 pix_min = { tile_id.x * BLOCK_X, tile_id.y * BLOCK_Y };
	uint2 pix = { pix_min.x + local_id.x, pix_min.y + local_id.y };

	uint32_t pix_id = W * pix.y + pix.x;

    if (pix.x >= W || pix.y >= H) return;

    float T = 1.0f;

    // Initialize output color to 0
    for (int c = 0; c < CHANNELS; ++c)
        out_color[c * W * H + pix_id] = 0.0f;

	for (int zb = 0; zb < depth_bins; ++zb) {
		int base_rgb = pix_id * depth_bins * CHANNELS + zb * CHANNELS;
		int base_T   = pix_id * depth_bins + zb;

		float zb_T = partial_T_global[base_T];
		for (int c = 0; c < CHANNELS; ++c) {
			float val = partial_rgb_global[base_rgb + c];
			out_color[c * W * H + pix_id] += val * T;
			}
		if (T < 0.001f) break;
		T *= zb_T;
    }

	// white background
	const float bg = 1.0f; // white
	for (int c = 0; c < CHANNELS; ++c) {
		out_color[c * W * H + pix_id] += T * bg;
	}

}


//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

void FORWARD::blendZBins(
	const dim3 grid, dim3 block,
	const float* partial_rgb_global,
	const float* partial_T_global,
	float* out_color,
	int W, int H, int depth_bins
)
{


	blendZBinsCUDA<NUM_CHANNELS><<<grid, block>>>(
		partial_rgb_global,
		partial_T_global,
		out_color,
		W, H, depth_bins
	);
}

 
void FORWARD::render(
	const dim3 grid, dim3 block,
	const uint2* ranges,
	const uint32_t* point_list,
	int W, int H,
	const float step_size,
	const float2* means2D,
	const float* transferFunction,
	float* partial_rgb_global,
	float* partial_T_global,
	const float* conic_opacity,
	const float* depths,
	const float* covzs)
{
	renderCUDA<NUM_CHANNELS> << <grid, block >> > (
		ranges,
		point_list,
		W, H,
		step_size,
		means2D,
		transferFunction,
		partial_rgb_global,
		partial_T_global,
		conic_opacity,
		depths,
		covzs);
}
 
void FORWARD::preprocess(int P,
	const float* means3D,
	const glm::vec3* scales,
	const float scale_modifier,
	const glm::vec4* rotations,
	const float* opacities,
	const float* viewmatrix,
	const float* projmatrix,
	const int W, int H,
	const float orthoRight,
	int* radii,
	float2* means2D,
	float* depths,
	float* cov3Ds,
	float* conic_opacity,
	float* covzs,
	const dim3 grid,
	uint32_t* tiles_touched,
	int2* rects,
	float3 boxmin,
	float3 boxmax)
{
	preprocessCUDA << <(P + 255) / 256, 256 >> > (
		P,
		means3D,
		scales,
		scale_modifier,
		rotations,
		opacities,
		viewmatrix, 
		projmatrix,
		W, H,
		orthoRight,
		radii,
		means2D,
		depths,
		cov3Ds,
		conic_opacity,
		covzs,
		grid,
		tiles_touched,
		rects,
		boxmin,
		boxmax
		);
}
