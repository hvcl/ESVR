#!/bin/bash

# Train either one full volume or all chunks sequentially.
# The execution mode and number of chunks come from dataset_configs.py.

# Usage: ./train_chunk.sh [dataset_name]
DATASET_NAME="${1:-breast}"

SUBVOL_SIZE=128

# Read the mode and calculate the chunk count from the same config used by
# train_chunk.py. A full-volume dataset is always one chunk.
CONFIG_VALUES=$(python -c '
import math
import sys
from dataset_configs import DATASET_CONFIGS

name = sys.argv[1]
if name not in DATASET_CONFIGS:
    raise SystemExit(f"Unknown dataset: {name}")

config = DATASET_CONFIGS[name]
mode = config.get("training_mode")
if mode == "full":
    total = 1
elif mode == "chunk_sequential":
    volume_size = (
        config["x_voxel_size"],
        config["y_voxel_size"],
        config["z_voxel_size"],
    )
    chunk_size = config["chunk_size"]
    total = math.prod(math.ceil(v / c) for v, c in zip(volume_size, chunk_size))
else:
    raise SystemExit(
        f"train_chunk.sh supports full and chunk_sequential, not {mode!r}"
    )

print(mode, total)
' "${DATASET_NAME}") || exit 1

read -r TRAINING_MODE TOTAL_CHUNKS <<< "${CONFIG_VALUES}"

echo "Training mode: ${TRAINING_MODE}"
echo "Total chunks: ${TOTAL_CHUNKS}"

# ============================================================
# Hyperparameters (scan-based, matching finalparam_Aneurysm)
# ============================================================

# Schedule (scan units)
ITERATIONS_SCAN=2800
DENSIFY_FROM_SCAN=16
DENSIFY_UNTIL_SCAN=400
DENSIFICATION_INTERVAL_SCAN=4
OPACITY_RESET_INTERVAL_SCAN=64
DARKPRUNING_SCANS="16 200 400 1200 1800 2100 2700"
GLOBALPRUNING_SCANS="1200"

SAVING_SCANS="4 40 80 120 160"

# LR max steps (scan units)
POSITION_LR_MAX_SCANS=1200
OPACITY_LR_MAX_SCANS=16
SCALING_LR_MAX_SCANS=1200
ROTATION_LR_MAX_SCANS=1200

# LR values
POSITION_LR_INIT=0.000008
POSITION_LR_FINAL=0.000001
OPACITY_LR_INIT=0.0075
OPACITY_LR_FINAL=0.0005
SCALING_LR_INIT=0.00005
SCALING_LR_FINAL=0.00005
ROTATION_LR_INIT=0.00001
ROTATION_LR_FINAL=0.00001
POSITION_LR_DELAY_MULT=0.01
# Loss
LAMBDA_DSSIM=0.2

# Densification
DENSIFY_GRAD_THRESHOLD=0.0000000025
PERCENT_DENSE=0.01

# Initialization & pruning
INIT_NUM=100000
PRUNING_REMAINWEIGHT=0.66

OUTPUT_DIR="${DATASET_NAME}/s_${ITERATIONS_SCAN}_${DENSIFY_GRAD_THRESHOLD}_${PERCENT_DENSE}_${SCALING_LR_INIT}_${SUBVOL_SIZE}/${DATASET_NAME}"

for chunk_idx in $(seq 0 $((TOTAL_CHUNKS-1))); do
    echo ""
    echo "=========================================="
    echo "Dataset: ${DATASET_NAME}"
    echo "Training mode: ${TRAINING_MODE}"
    echo "Starting training for chunk ${chunk_idx}/$((TOTAL_CHUNKS-1))"
    echo "Parameters: iterations_scan=${ITERATIONS_SCAN}, densify_grad=${DENSIFY_GRAD_THRESHOLD}, scaling_lr=${SCALING_LR_INIT}, percent_dense=${PERCENT_DENSE}"
    echo "=========================================="
    
    python train_chunk.py \
        --chunk_idx ${chunk_idx} \
        --dataset_name ${DATASET_NAME} \
        --output_dir ${OUTPUT_DIR} \
        --subvol_size ${SUBVOL_SIZE} \
        --iterations ${ITERATIONS_SCAN} \
        --densify_from_iter ${DENSIFY_FROM_SCAN} \
        --densify_until_iter ${DENSIFY_UNTIL_SCAN} \
        --densification_interval ${DENSIFICATION_INTERVAL_SCAN} \
        --opacity_reset_interval ${OPACITY_RESET_INTERVAL_SCAN} \
        --darkpruning_iter ${DARKPRUNING_SCANS} \
        --save_iterations ${SAVING_SCANS} \
        --globalpruning_iter ${GLOBALPRUNING_SCANS} \
        --position_lr_max_steps ${POSITION_LR_MAX_SCANS} \
        --opacity_lr_max_steps ${OPACITY_LR_MAX_SCANS} \
        --scaling_lr_max_steps ${SCALING_LR_MAX_SCANS} \
        --rotation_lr_max_steps ${ROTATION_LR_MAX_SCANS} \
        --position_lr_init ${POSITION_LR_INIT} \
        --position_lr_final ${POSITION_LR_FINAL} \
        --opacity_lr_init ${OPACITY_LR_INIT} \
        --opacity_lr_final ${OPACITY_LR_FINAL} \
        --scaling_lr_init ${SCALING_LR_INIT} \
        --scaling_lr_final ${SCALING_LR_FINAL} \
        --rotation_lr_init ${ROTATION_LR_INIT} \
        --rotation_lr_final ${ROTATION_LR_FINAL} \
        --position_lr_delay_mult ${POSITION_LR_DELAY_MULT} \
        --lambda_dssim ${LAMBDA_DSSIM} \
        --densify_grad_threshold ${DENSIFY_GRAD_THRESHOLD} \
        --percent_dense ${PERCENT_DENSE} \
        --init_num ${INIT_NUM} \
        --pruning_remainweight ${PRUNING_REMAINWEIGHT}
    
    if [ $? -ne 0 ]; then
        echo "Error: Training failed for chunk ${chunk_idx}"
        exit 1
    fi
    
    echo ""
    echo "Chunk ${chunk_idx} completed successfully!"
    echo ""
done

echo ""
echo "=========================================="
echo "Training completed (${TRAINING_MODE}, ${TOTAL_CHUNKS} chunk(s))!"
echo "=========================================="


if [ "${TRAINING_MODE}" = "chunk_sequential" ]; then
    echo "Merging the latest PLY from ${TOTAL_CHUNKS} chunks..."
    python merge_ply.py \
        --chunk_prefix "./output/${OUTPUT_DIR}" \
        --num_chunks "${TOTAL_CHUNKS}" \
        --output "./output/$(dirname "${OUTPUT_DIR}")/merged/point_cloud.ply"

    if [ $? -ne 0 ]; then
        echo "Error: PLY merge failed"
        exit 1
    fi
    echo "Merged PLY: ./output/$(dirname "${OUTPUT_DIR}")/merged/point_cloud.ply"
fi
