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

#ifndef CUDA_RASTERIZER_CONFIG_H_INCLUDED
#define CUDA_RASTERIZER_CONFIG_H_INCLUDED

#define NUM_CHANNELS 3 // Default 3, RGB
#define BLOCK_X 16
#define BLOCK_Y 16
#define BLOCK3D_X 8
#define BLOCK3D_Y 8
#define BLOCK3D_Z 8

// Depth bin experiment settings for intra-ray parallel volume rendering.
// Keep GaussianView.cpp partial buffer allocation in sync with DVR_DEPTH_BINS.
#define DVR_DEPTH_BINS 8
#define DVR_RAY_LENGTH_UNITS 1024
#define DVR_THREAD_BIN_COUNT (DVR_RAY_LENGTH_UNITS / DVR_DEPTH_BINS)
#endif
