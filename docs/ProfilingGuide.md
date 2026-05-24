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

## Project Script

The repository includes a helper script that profiles the representative cases below:

```powershell
.\scripts\run_profiling.ps1
```

The script:

- detects `ncu`
- finds `build\Release\convolution_benchmark.exe` or `build\convolution_benchmark.exe`
- writes profiler text logs to `results\profiling\`
- restores the official GTX 1650 CSV files after profiling

If NVIDIA performance counters are disabled, Nsight Compute may stop with `ERR_NVGPUCTRPERM`. In that case, enable GPU performance counters in the NVIDIA driver settings or rerun from an environment where the user has profiler counter access.

On Windows, the usual fix is:

1. Open NVIDIA Control Panel.
2. Enable the Developer menu if it is hidden.
3. Go to **Developer > Manage GPU Performance Counters**.
4. Select **Allow access to the GPU performance counters to all users**.
5. Apply the change and rerun `.\scripts\run_profiling.ps1`.

Expected text outputs:

```text
results\profiling\separable_4096_gaussian_11_32x8.txt
results\profiling\shared_constant_4096_sobel_11_32x16.txt
results\profiling\direct_compare_1024_sobel_7.txt
```

Binary `.ncu-rep` exports may be useful locally, but they are ignored by Git to avoid committing large profiler artifacts.

To keep running all cases even when one case fails because of permissions, use:

```powershell
.\scripts\run_profiling.ps1 -ContinueOnError
```

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
- Text profiler summaries are saved under `results/profiling/`.
