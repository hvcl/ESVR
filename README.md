# ESVR: 3D Ellipsoid-based Sparse Volume Rendering via Structure-aware Primitive Learning and Per-primitive Ray Sampling
3D Ellipsoid-based Sparse Volume Rendering via Structure-aware Primitive Learning and Per-primitive Ray Sampling

Suemin Jeon*, Youjin Kim*, Jungwoo Park, Kyungryun Lee, Won-Ki Jeong (*indicates equal contribution)

# Description
This is the implementation for ESVR: 3D Ellipsoid-based Sparse Volume Rendering via Structure-aware Primitive Learning and Per-primitive Ray Sampling.

# Setup

# Dataset
Dataset paths, volume sizes, chunk sizes, and training modes are defined in
`dataset_configs.py`.

# Training and Evaluation
## Single Volume Training / Sequential Chunk Training
Use `train_chunk.py` for datasets configured with `training_mode: "full"` or
`training_mode: "chunk_sequential"`. The provided script trains every chunk in
sequence:

```bash
./train_chunk.sh
```

## Parallel Chunk Training
Use `train_parallel.py` for datasets configured with
`training_mode: "chunk_parallel"`. The provided script trains multiple chunks
on separate GPUs:

```bash
./train_parallel.sh
```

Set `BATCH_SIZE` in `train_parallel.sh` to control the number of chunks trained
at the same time. It should not exceed the number of available GPUs.

# Viewer
