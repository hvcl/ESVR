#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

docker build \
    --file "$SCRIPT_DIR/Dockerfile" \
    --tag esvr:latest \
    "$PROJECT_ROOT"
