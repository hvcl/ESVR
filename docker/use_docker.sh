#!/usr/bin/env bash
echo Running Docker container for ESVR...
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GPU="${1:-all}"
CONTAINER_NAME="${2:-esvr}"

if [[ "$GPU" == "all" ]]; then
    GPU_REQUEST="all"
else
    GPU_REQUEST="device=$GPU"
fi

docker run --rm -it \
    --gpus "$GPU_REQUEST" \
    --shm-size=16g \
    --name "$CONTAINER_NAME" \
    --volume /home:/home \
    --workdir "$PROJECT_ROOT" \
    -ti esvr:latest\
    /bin/bash
