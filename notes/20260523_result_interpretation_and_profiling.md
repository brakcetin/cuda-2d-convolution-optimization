# 20260523 - Result Interpretation And Profiling Notes

## Purpose

This note records the documentation milestone that explains the benchmark results more deeply and prepares optional profiling and RTX 4070 comparison work.

## Chronological Steps

### 1. Added Result Interpretation

Created:

- `docs/ResultInterpretation.md`

What it explains:

- CPU versus CUDA speedup.
- Kernel-only timing versus total GPU timing.
- Why separable convolution wins for box and Gaussian-like filters.
- Why `cuda_shared_constant_filter` is strongest for large direct Sobel/sharpen-like cases.
- Why block shape matters.
- Why `cuda_register_tiled` helps but does not dominate shared+constant filtering.

### 2. Added Profiling Guide

Created:

- `docs/ProfilingGuide.md`

Important commands:

```powershell
ncu --set full --target-processes all .\build\Release\convolution_benchmark.exe --image-sizes 4096 --filter-sizes 11 --filter-types gaussian --block-sizes 32x8 --repeats 5 --warmups 1 --versions cuda_separable
```

```powershell
ncu --set full --target-processes all .\build\Release\convolution_benchmark.exe --image-sizes 4096 --filter-sizes 11 --filter-types sobel --block-sizes 32x16 --repeats 5 --warmups 1 --versions cuda_shared_constant_filter
```

```powershell
ncu --set full --target-processes all .\build\Release\convolution_benchmark.exe --image-sizes 1024 --filter-sizes 7 --filter-types sobel --block-sizes 16x16,32x8 --repeats 3 --warmups 1 --versions cuda_naive_global_memory,cuda_shared_memory_tiled,cuda_shared_constant_filter,cuda_multi_output,cuda_register_tiled
```

Metrics to inspect:

- achieved occupancy
- DRAM throughput
- L2 cache throughput
- global memory load behavior
- shared-memory usage
- warp execution efficiency

### 3. Added RTX 4070 Comparison Handoff

Created:

- `docs/GpuComparison.md`

The RTX 4070 run is optional. GTX 1650 remains official. If the teammate runs the matrix, the RTX files should be saved separately:

- `results/timing_results_rtx4070.csv`
- `results/correctness_results_rtx4070.csv`
- `results/summary_best_versions_rtx4070.csv`

## Interpretation

The project now has stronger written analysis. The key report story is:

1. CUDA accelerates convolution because output pixels are independent.
2. Separable convolution wins when the filter structure allows it.
3. Shared-memory plus constant-memory filtering wins important direct convolution cases.
4. Block shape changes performance, so it is a real benchmark variable.
5. Register tiling is useful evidence, but not a universal winner.

## Next Steps

1. Implement optional PGM image demo path.
2. Add docs for real-image demo usage.
3. Run build and smoke tests.
4. Commit and push each milestone separately.
