import argparse
import os
import sys

import numpy as np
import skimage.io
import torch

from arguments import ModelParams, PipelineParams
from dataset_configs import DATASET_CONFIGS
from gaussian_renderer import query
from query import compute_psnr
from scene import GaussianModel


def load_ground_truth(config):
    """Load a dataset in the logical XYZ order declared by dataset_configs.py."""
    path = config["path"]
    volume_shape = tuple(
        config[key] for key in ("x_voxel_size", "y_voxel_size", "z_voxel_size")
    )

    if config["use_tif"]:
        volume = skimage.io.imread(path)
        if config.get("transpose", False):
            volume = volume.transpose(2, 1, 0)
    else:
        dtype = np.uint16 if "uint16" in path.lower() else np.uint8
        default_raw_shape = (
            volume_shape[::-1] if config.get("transpose", False) else volume_shape
        )
        raw_shape = tuple(config.get("raw_shape", default_raw_shape))
        volume = np.memmap(path, dtype=dtype, mode="r", shape=raw_shape)
        if config.get("transpose", False):
            if "axis_order" in config:
                axis_order = tuple(config["axis_order"])
            else:
                axis_order = (2,1,0)
            volume = volume.transpose(*axis_order)

    if tuple(volume.shape) != volume_shape:
        raise ValueError(
            f"Configured shape {volume_shape} does not match loaded shape {volume.shape} "
            f"for {path}"
        )
    return volume


def normalized_tensor(volume):
    divisor = 65535.0 if volume.dtype == np.uint16 else 255.0
    return torch.from_numpy(np.asarray(volume).astype(np.float32) / divisor)


def make_global_grid(shape, device="cpu"):
    """Create the same aspect-ratio-preserving world grid used during training."""
    max_size = max(shape)
    step = 2.0 / max_size
    coords = [
        torch.arange(size, dtype=torch.float32, device=device) * step
        - size / max_size
        + step / 2
        for size in shape
    ]
    return coords, step


def query_region(gaussians, pipe, coords, step, bounds):
    starts, ends = bounds
    slices = [coords[axis][starts[axis] : ends[axis]] for axis in range(3)]
    center = [((axis[0] + axis[-1]) / 2).item() for axis in slices]
    size = [((axis[-1] - axis[0]) + step).item() for axis in slices]
    resolution = [ends[axis] - starts[axis] for axis in range(3)]
    return query(
        gaussians,
        center,
        resolution,
        size,
        pipe,
        # use_step_function=True,
    )["vol"]


def save_volume(path, volume):
    output_dir = os.path.dirname(os.path.abspath(path))
    os.makedirs(output_dir, exist_ok=True)
    skimage.io.imsave(path, volume, check_contrast=False, imagej=True)
    print(f"Saved volume: {path} ({volume.shape}, {volume.dtype})")


def main():
    parser = argparse.ArgumentParser(description="Query a PLY as a configured 3D volume")
    ModelParams(parser)
    pp = PipelineParams(parser)
    parser.add_argument(
        "--dataset_name",
        required=True,
        choices=sorted(DATASET_CONFIGS),
        help="Dataset key from dataset_configs.py",
    )
    parser.add_argument("--input_ply", default="./output/point_cloud.ply")
    parser.add_argument("--output_tif", default="./output/volume_merged.tif")
    parser.add_argument("--chunk_size", type=int, default=1024, help="Batch size for inference along each axis")
    parser.add_argument("--full", action="store_true", help="Query the entire volume at once")
    parser.add_argument("--save_tif", action="store_true")
    parser.add_argument(
        "--output_dtype", choices=("uint8", "uint16"), default="uint8"
    )
    args = parser.parse_args(sys.argv[1:])
    if args.chunk_size <= 0:
        parser.error("--chunk_size must be positive")

    config = DATASET_CONFIGS[args.dataset_name]
    shape = tuple(
        config[key] for key in ("x_voxel_size", "y_voxel_size", "z_voxel_size")
    )
    print(f"Dataset: {args.dataset_name}")
    print(f"GT path: {config['path']}")
    print(f"Volume shape (XYZ): {shape}")

    gt_volume = load_ground_truth(config)
    divisor = 65535.0 if gt_volume.dtype == np.uint16 else 255.0
    data_range = (float(np.max(gt_volume)) - float(np.min(gt_volume))) / divisor
    print("data_range:", data_range)
    if data_range == 0:
        raise ValueError("Ground-truth volume has zero data range")
    data_range = 1.0

    pipe = pp.extract(args)
    gaussians = GaussianModel(*shape)
    print(f"Loading PLY: {args.input_ply}")
    gaussians.load_ply(args.input_ply)
    print(f"Loaded {gaussians.get_xyz.shape[0]} Gaussians")

    output_dtype = np.uint8 if args.output_dtype == "uint8" else np.uint16
    output_scale = np.iinfo(output_dtype).max

    with torch.no_grad():
        if args.full:
            coords, step = make_global_grid(shape)
            pred = query_region(gaussians, pipe, coords, step, ((0, 0, 0), shape))
            pred = torch.clip(pred, 0, 1).detach().cpu()
            gt = normalized_tensor(gt_volume)
            psnr = compute_psnr(pred, gt, data_range=data_range)
            print(f"Full-volume PSNR: {psnr:.6f}")
            if args.save_tif:
                result = np.round(pred.numpy() * output_scale).astype(output_dtype)
                save_volume(args.output_tif, result)
            return

        coords, step = make_global_grid(shape, device="cuda")
        result = np.zeros(shape, dtype=output_dtype) if args.save_tif else None
        squared_error = 0.0
        voxel_count = 0
        chunk_counts = [
            (size + args.chunk_size - 1) // args.chunk_size for size in shape
        ]
        total_chunks = int(np.prod(chunk_counts))
        chunk_index = 0

        for xs in range(0, shape[0], args.chunk_size):
            for ys in range(0, shape[1], args.chunk_size):
                for zs in range(0, shape[2], args.chunk_size):
                    starts = (xs, ys, zs)
                    ends = tuple(
                        min(starts[axis] + args.chunk_size, shape[axis])
                        for axis in range(3)
                    )
                    chunk_index += 1
                    print(f"[{chunk_index}/{total_chunks}] {starts} -> {ends}")

                    pred = query_region(gaussians, pipe, coords, step, (starts, ends))
                    pred = torch.clip(pred, 0, 1)
                    gt_np = gt_volume[
                        xs : ends[0], ys : ends[1], zs : ends[2]
                    ]
                    gt = normalized_tensor(gt_np).cuda()
                    diff = pred - gt
                    squared_error += torch.sum(diff * diff).item()
                    voxel_count += diff.numel()

                    if result is not None:
                        result[xs : ends[0], ys : ends[1], zs : ends[2]] = (
                            pred.detach().cpu().numpy() * output_scale
                        ).round().astype(output_dtype)

                    del pred, gt, diff
                    torch.cuda.empty_cache()

        mse = squared_error / voxel_count
        psnr = float("inf") if mse == 0 else 20 * np.log10(data_range / np.sqrt(mse))
        print(f"Chunked full-volume PSNR: {psnr:.6f}")
        if result is not None:
            save_volume(args.output_tif, result)


if __name__ == "__main__":
    main()
