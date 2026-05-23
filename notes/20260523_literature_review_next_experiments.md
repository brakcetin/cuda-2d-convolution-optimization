# 20260523 - Literature Review And Next Experiment Ideas

## Purpose

This note connects the seven local paper files to concrete next improvements for the CUDA 2D convolution project. The goal is to make the project stronger while staying realistic for CENG-479.

Update after scope decision:

- The earlier "do not add unless there is extra time" items are no longer excluded.
- We now have enough time and will add advanced comparisons step by step.
- The full expanded roadmap is recorded in `notes/20260523_full_expansion_roadmap.md`.

## Papers Read

- `An extended analysis of memory hierarchies for efficient implementations of image processing applications.md`
- `Communication-minimizing_2D_convolution_in_GPU_registers.md`
- `Concurrency and Computation - 2015 - Perrot - An optimized GPU-based 2D convolution implementation.md`
- `GpuCV a GPU-accelerated framework for image processing and computer vision.md`
- `Optimizing convolution operations on GPUs using adaptive tiling.md`
- `Optimizing_GPU_Memory_Transactions_for_Convolution_Operations.md`
- `Performance_Evaluation_of_cuDNN_Convolution_Algorithms_on_NVIDIA_Volta_GPUs.md`

## Main Lessons From The Papers

### Memory hierarchy matters most

The memory-hierarchy paper emphasizes that many image-processing workloads are memory-bound. This supports measuring not only kernel time, but also memory transfer and total GPU time.

Project implication:

- Keep reporting kernel-only and total GPU time separately.
- Add memory-copy timing breakdown if possible.
- Explain small-image total-time overhead clearly.

### Communication reduction is a serious optimization theme

The register-convolution paper and the memory-transaction paper both focus on reducing repeated memory traffic. They use ideas such as more work per thread, register prefetching, warp shuffle, and row/column reuse.

Project implication:

- Do not add warp-shuffle/register tiling as a required implementation unless time allows.
- Use these papers in the report to explain future work and why memory traffic dominates convolution.
- Add derived memory-traffic metrics or GFLOP/s first, because that is lower risk and supports analysis.

### Shared memory and constant memory are standard first optimizations

The adaptive tiling paper explicitly discusses constant memory for filters and shared memory for input tile reuse. This matches our implemented versions.

Project implication:

- Our implementation is aligned with the literature.
- Add a block-size/tile-size experiment because adaptive tiling shows that tile dimensions affect performance.

### Separable convolution is valid but conditional

The adaptive tiling and optimized-convolution papers discuss separable convolution as a major optimization when the filter can be represented as two 1D passes.

Project implication:

- Keep `cuda_separable`, but document that it applies only to separable filters.
- Add filter type experiments so the report can compare separable and non-separable cases honestly.

### Industrial/library studies compare many configurations

GpuCV and cuDNN evaluation papers show that serious performance studies compare across image sizes, filter sizes, implementation variants, and sometimes hardware/library choices.

Project implication:

- We already compare image sizes, filter sizes, and CUDA versions.
- To look stronger, add result summaries such as best-version-per-case and performance stability metrics.

## Recommended Additions Ranked By Value

### 1. Add timing statistics

Add columns:

- `cpu_min_ms`
- `cpu_max_ms`
- `cpu_stddev_ms`
- `gpu_kernel_min_ms`
- `gpu_kernel_max_ms`
- `gpu_kernel_stddev_ms`
- `gpu_total_min_ms`
- `gpu_total_max_ms`
- `gpu_total_stddev_ms`

Why:

This makes benchmark results more credible and less dependent on one run.

### 2. Add GFLOP/s

Add columns:

- `estimated_operations`
- `cpu_gflops`
- `gpu_kernel_gflops`

Direct convolution operation estimate:

```text
width * height * filter_size * filter_size * 2
```

Separable operation estimate:

```text
width * height * filter_size * 2 * 2
```

Why:

Papers often discuss throughput and arithmetic intensity. GFLOP/s makes our performance study more professional.

### 3. Add GPU time breakdown

Add timing fields:

- allocation time
- host-to-device copy time
- kernel time
- device-to-host copy time
- total time

Why:

This explains why kernel speedup can be high while total speedup is smaller.

### 4. Add filter type experiments

Current filter:

- normalized box filter, separable

Add:

- Gaussian-like separable filter
- sharpen filter, non-separable
- edge/Sobel-like filter, non-separable or special case

Why:

This prevents the project from overclaiming separable convolution. It proves that direct convolution variants remain necessary.

### 5. Add block-size sweep

Test:

- `8x8`
- `16x16`
- `32x8`
- `32x16` if resource usage allows

Why:

Adaptive tiling papers show that tile/block shape matters. This is a strong additional experiment without implementing a risky new algorithm.

### 6. Add best-version summary table

Generate:

- `results/summary_best_versions.csv`

Columns:

- image size
- filter size
- best kernel-time version
- best total-time version
- best speedup
- correctness status

Why:

This is immediately useful for the report and presentation.

## What Not To Add Unless There Is Extra Time

Avoid making these required:

- FFT convolution
- Winograd convolution
- cuDNN integration
- OpenCV/GpuCV integration
- warp-shuffle register tiling
- multi-GPU or RGB image support

Reason:

These are legitimate research/industry directions, but they would increase implementation risk. For this course project, benchmark rigor and clear analysis are more valuable.

## Best Next Milestone

The strongest next milestone is:

```text
Benchmark rigor and filter comparison
```

Implementation scope:

1. Add timing statistics.
2. Add GFLOP/s.
3. Add GPU total-time breakdown.
4. Add filter type CLI option.
5. Add best-version summary CSV.
6. Rerun GTX 1650 benchmarks.
7. Regenerate plots.
8. Update report notes.

Interpretation:

This improves the project in exactly the way the papers suggest: stronger measurement, stronger comparison, and more honest analysis of memory hierarchy and algorithm choice.
