# Result Interpretation

This document explains how to read the official GTX 1650 benchmark results and the secondary RTX 4070 comparison results for the final report and presentation.

## Official Result Source

Official files:

- `results/timing_results.csv`
- `results/correctness_results.csv`
- `results/summary_best_versions.csv`
- `results/timing_results_gtx1650_official.csv`
- `results/correctness_results_gtx1650_official.csv`
- `results/summary_best_versions_gtx1650_official.csv`

Secondary RTX 4070 files:

- `results/timing_results_rtx4070.csv`
- `results/correctness_results_rtx4070.csv`
- `results/summary_best_versions_rtx4070.csv`
- `results/plots_rtx4070/`

Official benchmark matrix:

- GPU: NVIDIA GeForce GTX 1650 with Max-Q Design
- Images: 512x512, 1024x1024, 2048x2048, 4096x4096
- Filters: 3x3, 5x5, 7x7, 11x11
- Filter types: box, Gaussian-like, sharpen, Sobel-like
- Block sizes: 8x8, 16x16, 32x8, 32x16
- Repeats: 5
- Warmups: 1
- Timing rows: 1408
- Failed correctness rows: 0

Secondary RTX 4070 matrix:

- GPU: NVIDIA GeForce RTX 4070 Laptop GPU
- Timing rows: 1408
- Failed correctness rows: 0
- Summary rows: 64

## CPU Versus CUDA

The CPU implementation is single-threaded by design. It is the required sequential baseline and the correctness oracle. The CUDA kernels exploit pixel-level parallelism: each output pixel, or in some kernels each small output group, can be computed independently.

The strongest speedups appear for large images and large filters. This is expected because the CPU cost grows with `width * height * filter_size * filter_size`, while the GPU can spread the independent pixel work across many threads. Larger workloads also reduce the relative impact of fixed GPU setup overhead.

Small cases can still have good kernel-only speedup but weaker total-time speedup because allocation and host-device transfer overheads are large compared with the amount of computation.

## Kernel-Only Versus Total GPU Timing

The project reports two speedup styles:

- Kernel-only speedup: CPU time divided by CUDA kernel time.
- Total GPU speedup: CPU time divided by allocation, copy, kernel, copy-back, and free time.

Kernel-only timing answers: "How fast is the GPU computation once data is on the GPU?"

Total GPU timing answers: "How fast is the whole GPU path if the image starts on the CPU and the result must return to the CPU?"

Both are useful. Kernel-only timing highlights CUDA implementation quality. Total timing is more realistic for standalone applications that do not already keep image data resident on the GPU.

## Why Separable Convolution Wins

The `cuda_separable` version is valid only for box and Gaussian-like filters because those filters are generated from a 1D representation.

For an 11x11 direct filter, each output pixel uses 121 coefficient applications. A separable 11x11 filter becomes one horizontal 11-element pass and one vertical 11-element pass, or 22 coefficient applications per pixel. This reduces arithmetic work dramatically.

That is why the strongest official result is:

- `cuda_separable`
- 4096x4096 image
- 11x11 Gaussian-like filter
- 32x8 block
- 744.215965x kernel-only speedup
- 56.205213x total GPU speedup

This should be presented as an algorithmic optimization, not only a CUDA memory optimization.

## Why Shared Plus Constant Memory Wins Direct Cases

Sharpen and Sobel-like filters are treated as direct filters in this project. The separable path is intentionally not reported for them.

For direct convolution, `cuda_shared_constant_filter` is the strongest large-filter kernel because it combines two useful memory-hierarchy ideas:

- Shared memory reduces repeated input-image global-memory reads inside a tile.
- Constant memory is suitable for small read-only filter coefficients accessed repeatedly by many threads.

The best direct-convolution kernel-only result is:

- `cuda_shared_constant_filter`
- 4096x4096 image
- 11x11 Sobel-like filter
- 32x16 block
- 432.778406x kernel-only speedup

This supports the project title: memory-hierarchy-aware CUDA implementation matters when separable convolution is not mathematically available.

## GTX 1650 Versus RTX 4070

The RTX 4070 run uses the same benchmark matrix as the GTX 1650 run. It confirms that the code and benchmark pipeline scale to stronger hardware while preserving correctness.

Headline comparison:

- GTX best kernel-only speedup: 744.216x, `cuda_separable`, 4096x4096, 11x11 Gaussian-like.
- RTX best kernel-only speedup: 1338.130x, `cuda_separable`, 1024x1024, 11x11 box.
- GTX best direct-convolution speedup: 432.778x, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel-like.
- RTX best direct-convolution speedup: 784.821x, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel-like.

The important interpretation does not change: separable convolution dominates when the filter allows algorithmic reduction, and shared+constant memory is the strongest direct-convolution strategy for large Sobel-like cases. The RTX 4070 mainly changes the magnitude of the timings and speedups.

## Why Block Shape Matters

The block-size sweep uses 8x8, 16x16, 32x8, and 32x16. No single block shape wins every case.

Block shape affects:

- memory coalescing
- shared-memory tile and halo shape
- occupancy
- scheduling overhead
- ratio of useful output pixels to halo pixels

The best-version summary records the winning block shape for each image/filter/filter-type case. This is better than hardcoding only 16x16 because it shows that launch configuration is part of the performance study.

## Why Register Tiling Helps But Does Not Dominate

`cuda_multi_output` and `cuda_register_tiled` make one thread compute two horizontal outputs. This can reuse nearby input reads and keep two accumulators in registers.

The best new Phase 4 kernel result is:

- `cuda_register_tiled`
- 512x512 image
- 3x3 Sobel-like filter
- 16x16 block
- 409.607974x kernel-only speedup

However, the register-tiled kernel does not dominate the strongest large direct-convolution cases. For 4096x4096 11x11 Sobel-like convolution, `cuda_shared_constant_filter` remains the best direct kernel-time method. This is useful experimentally because it shows that output tiling is not automatically better than memory-hierarchy optimization.

## Recommended Report Message

Use this interpretation in the final report:

CUDA gives strong acceleration for 2D convolution because output pixels are independent and the workload is highly data-parallel. The best implementation depends on filter structure and timing perspective. Separable convolution is strongest for box and Gaussian-like filters because it reduces the operation count. For direct sharpen and Sobel-like filters, shared-memory input tiling plus constant-memory filter coefficients gives the strongest large-filter performance. Block shape also affects performance, so the final benchmark treats launch configuration as an experimental variable.

Use the RTX 4070 results as secondary evidence: they show hardware scaling, but the GTX 1650 remains the official baseline for reproducibility.
