# Profiling Guide

This guide explains how to add profiling evidence without changing the official benchmark methodology.

## Purpose

The official results are based on the benchmark CSV files. Profiling is optional supporting evidence for the report and Q&A. It can help explain why a kernel behaves the way it does, but it should not replace the timing CSVs.

## Recommended Tool

Use NVIDIA Nsight Compute if it is installed:

```powershell
ncu --version
```

If Nsight Compute is not available, document that profiling was not collected and keep the benchmark CSV analysis as the main evidence.

## Representative Cases

Profile only selected cases instead of the full 1408-row matrix.

### Separable Best Case

Purpose: explain why algorithmic reduction dominates for separable filters.

```powershell
ncu --set full --target-processes all .\build\Release\convolution_benchmark.exe --image-sizes 4096 --filter-sizes 11 --filter-types gaussian --block-sizes 32x8 --repeats 5 --warmups 1 --versions cuda_separable
```

### Best Direct Memory-Hierarchy Case

Purpose: inspect shared-memory and constant-memory behavior for a non-separable filter.

```powershell
ncu --set full --target-processes all .\build\Release\convolution_benchmark.exe --image-sizes 4096 --filter-sizes 11 --filter-types sobel --block-sizes 32x16 --repeats 5 --warmups 1 --versions cuda_shared_constant_filter
```

### Direct-Kernel Comparison Case

Purpose: compare direct implementations on the same Sobel-like workload.

```powershell
ncu --set full --target-processes all .\build\Release\convolution_benchmark.exe --image-sizes 1024 --filter-sizes 7 --filter-types sobel --block-sizes 16x16,32x8 --repeats 3 --warmups 1 --versions cuda_naive_global_memory,cuda_shared_memory_tiled,cuda_shared_constant_filter,cuda_multi_output,cuda_register_tiled
```

## Metrics To Inspect

Useful Nsight Compute sections and ideas:

- Memory Workload Analysis: global memory load/store behavior.
- Speed Of Light: whether the kernel is closer to compute-bound or memory-bound.
- Occupancy: whether block shape or register usage limits active warps.
- Warp State Statistics: stalled cycles and likely bottlenecks.
- Shared Memory: shared-memory load/store behavior for tiled kernels.

Report-friendly metrics:

- achieved occupancy
- DRAM throughput
- L2 cache throughput
- global load efficiency or sector usage
- shared-memory throughput
- warp execution efficiency

## How To Use Results In The Report

Do not paste the full profiler output into the report. Use one small table or paragraph:

| Case | Kernel | Important Observation |
|---|---|---|
| 4096, 11x11 gaussian | `cuda_separable` | Lower arithmetic work explains the strongest speedup. |
| 4096, 11x11 sobel | `cuda_shared_constant_filter` | Shared input reuse and constant filter reads support direct convolution. |
| 1024, 7x7 sobel | direct versions | Block shape and memory hierarchy change the winning implementation. |

## Notes

- Nsight profiling can slow execution significantly.
- Profiling results may differ between GTX 1650 and RTX 4070.
- Official timing claims should still come from committed CSVs.
- If profiling is added, save screenshots or exported reports under `docs/profiling/` or `results/profiling/`.
