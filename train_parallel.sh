#!/bin/bash

# Train all chunks of a chunk_parallel dataset across the available GPUs.
# Usage: ./train/train_parallel.sh [dataset_name] [batch_size]

set -o pipefail

DATASET_NAME="${1:-hemibrain_lLN2P}"
BATCH_SIZE="${2:-$(python3 -c 'import torch; print(torch.cuda.device_count())')}"

# Hyperparameters are scan-based, matching train/train_chunk.sh.
ITERATIONS_SCAN=160
DENSIFY_FROM_SCAN=4
DENSIFY_UNTIL_SCAN=40
DENSIFICATION_INTERVAL_SCAN=4
OPACITY_RESET_INTERVAL_SCAN=10
DARKPRUNING_SCANS="16 32 64 128 150"
GLOBALPRUNING_SCANS="80"
SAVING_SCANS="4 40 80 120 160"

# LR max steps (scan units)
POSITION_LR_MAX_SCANS=80
OPACITY_LR_MAX_SCANS=8
SCALING_LR_MAX_SCANS=80
ROTATION_LR_MAX_SCANS=80

POSITION_LR_INIT=0.000016
POSITION_LR_FINAL=0.0000016
OPACITY_LR_INIT=0.0075
OPACITY_LR_FINAL=0.0005
SCALING_LR_INIT=0.00005
SCALING_LR_FINAL=0.00005
ROTATION_LR_INIT=0.00001
ROTATION_LR_FINAL=0.00001
POSITION_LR_DELAY_MULT=0.01

LAMBDA_DSSIM=0.2
DENSIFY_GRAD_THRESHOLD=0.0000000025
PERCENT_DENSE=0.005
SUBVOL_SIZE=614
INIT_NUM=100000
PRUNING_REMAINWEIGHT=0.66
SYNC_INTERVAL_SCANS=100
OUTPUT_DIR="${DATASET_NAME}/exp1/${DATASET_NAME}"
BATCH_SIZE=2

TOTAL_CHUNKS=$(python3 -c '
import math
import sys
from dataset_configs import DATASET_CONFIGS

config = DATASET_CONFIGS[sys.argv[1]]
if config.get("training_mode") != "chunk_parallel":
    raise SystemExit(f"Not a chunk_parallel dataset: {sys.argv[1]}")
volume_size = (
    config["x_voxel_size"],
    config["y_voxel_size"],
    config["z_voxel_size"],
)
print(math.prod(math.ceil(v / c) for v, c in zip(volume_size, config["chunk_size"])))
' "${DATASET_NAME}") || exit 1

echo ""
echo "=========================================="
echo "Dataset: ${DATASET_NAME}"
echo "Training mode: chunk_parallel"
echo "Concurrent chunks: ${BATCH_SIZE}"
echo "=========================================="

python3 train_parallel.py \
    --dataset_name "${DATASET_NAME}" \
    --batch_size "${BATCH_SIZE}" \
    --sync_interval "${SYNC_INTERVAL_SCANS}" \
    --output_dir "${OUTPUT_DIR}" \
    --subvol_size "${SUBVOL_SIZE}" \
    --iterations "${ITERATIONS_SCAN}" \
    --densify_from_iter "${DENSIFY_FROM_SCAN}" \
    --densify_until_iter "${DENSIFY_UNTIL_SCAN}" \
    --densification_interval "${DENSIFICATION_INTERVAL_SCAN}" \
    --opacity_reset_interval "${OPACITY_RESET_INTERVAL_SCAN}" \
    --darkpruning_iter ${DARKPRUNING_SCANS} \
    --globalpruning_iter ${GLOBALPRUNING_SCANS} \
    --save_iterations ${SAVING_SCANS} \
    --position_lr_max_steps "${POSITION_LR_MAX_SCANS}" \
    --opacity_lr_max_steps "${OPACITY_LR_MAX_SCANS}" \
    --scaling_lr_max_steps "${SCALING_LR_MAX_SCANS}" \
    --rotation_lr_max_steps "${ROTATION_LR_MAX_SCANS}" \
    --position_lr_init "${POSITION_LR_INIT}" \
    --position_lr_final "${POSITION_LR_FINAL}" \
    --opacity_lr_init "${OPACITY_LR_INIT}" \
    --opacity_lr_final "${OPACITY_LR_FINAL}" \
    --scaling_lr_init "${SCALING_LR_INIT}" \
    --scaling_lr_final "${SCALING_LR_FINAL}" \
    --rotation_lr_init "${ROTATION_LR_INIT}" \
    --rotation_lr_final "${ROTATION_LR_FINAL}" \
    --position_lr_delay_mult "${POSITION_LR_DELAY_MULT}" \
    --lambda_dssim "${LAMBDA_DSSIM}" \
    --densify_grad_threshold "${DENSIFY_GRAD_THRESHOLD}" \
    --percent_dense "${PERCENT_DENSE}" \
    --init_num "${INIT_NUM}" \
    --pruning_remainweight "${PRUNING_REMAINWEIGHT}"

status=$?
if [ ${status} -ne 0 ]; then
    echo "Error: parallel training failed"
    exit ${status}
fi

echo "Parallel training completed successfully."

echo "Merging the latest PLY from ${TOTAL_CHUNKS} chunks..."
python3 merge_ply.py \
    --chunk_prefix "./output/${OUTPUT_DIR}" \
    --num_chunks "${TOTAL_CHUNKS}" \
    --output "./output/$(dirname "${OUTPUT_DIR}")/merged/point_cloud.ply"

status=$?
if [ ${status} -ne 0 ]; then
    echo "Error: PLY merge failed"
    exit ${status}
fi

echo "Merged PLY: ./output/$(dirname "${OUTPUT_DIR}")/merged/point_cloud.ply"
