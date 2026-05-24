# 20260524 - Nsight Compute Profiling

## Purpose

This note records the profiling milestone. The goal is to add a small amount of profiler evidence to support the final report without changing the official benchmark methodology.

Official timing claims still come from the GTX 1650 synthetic CSV files:

```text
results\timing_results.csv
results\correctness_results.csv
results\summary_best_versions.csv
```

## Tool Check

Nsight Compute CLI was detected:

```powershell
ncu --version
```

Expected installed version on this machine:

```text
NVIDIA Nsight Compute 2026.1.1
```

## Script

A helper script was added:

```powershell
.\scripts\run_profiling.ps1
```

The script:

- checks that `ncu` exists
- finds the benchmark executable in `build\Release\` or `build\`
- writes text logs under `results\profiling\`
- restores official GTX 1650 CSV files after profiling

## Representative Cases

Case 1: separable best case.

```powershell
ncu --set full --target-processes all .\build\convolution_benchmark.exe --image-sizes 4096 --filter-sizes 11 --filter-types gaussian --block-sizes 32x8 --repeats 5 --warmups 1 --versions cuda_separable
```

Purpose: explain why algorithmic reduction dominates for separable Gaussian-like filters.

Case 2: best direct memory-hierarchy case.

```powershell
ncu --set full --target-processes all .\build\convolution_benchmark.exe --image-sizes 4096 --filter-sizes 11 --filter-types sobel --block-sizes 32x16 --repeats 5 --warmups 1 --versions cuda_shared_constant_filter
```

Purpose: inspect shared-memory and constant-memory behavior for a non-separable filter.

Case 3: direct-kernel comparison.

```powershell
ncu --set full --target-processes all .\build\convolution_benchmark.exe --image-sizes 1024 --filter-sizes 7 --filter-types sobel --block-sizes 16x16,32x8 --repeats 3 --warmups 1 --versions cuda_naive_global_memory,cuda_shared_memory_tiled,cuda_shared_constant_filter,cuda_multi_output,cuda_register_tiled
```

Purpose: compare direct implementations under the same Sobel-like workload.

## Expected Output Files

```text
results\profiling\separable_4096_gaussian_11_32x8.txt
results\profiling\shared_constant_4096_sobel_11_32x16.txt
results\profiling\direct_compare_1024_sobel_7.txt
```

Binary `.ncu-rep` files are ignored by Git because they can be large and are not needed for the Markdown report.

## Interpretation Plan

- `cuda_separable` should be explained primarily as algorithmic reduction from `k*k` work to two `k`-length passes.
- `cuda_shared_constant_filter` should be explained as the strongest direct-convolution memory-hierarchy version for large Sobel-like cases.
- Direct-kernel comparison should support the claim that no single block shape or direct CUDA strategy wins every workload.

## Next Steps

1. Run `.\scripts\run_profiling.ps1`.
2. Inspect the generated `results\profiling\*.txt` logs.
3. Keep only compact text summaries in Git.
4. Use the observations in `docs\FinalReport.md`.

## Run Result On This Machine

The profiling script was executed after confirming that `ncu` and the benchmark executable exist:

```powershell
.\scripts\build_release.ps1
.\scripts\run_profiling.ps1
```

The benchmark executable launched successfully under Nsight Compute, but Nsight stopped before collecting detailed metrics:

```text
ERR_NVGPUCTRPERM - The user does not have permission to access NVIDIA GPU Performance Counters
```

This means the current machine needs NVIDIA GPU performance-counter access enabled before detailed metrics such as occupancy, memory throughput, and warp-state statistics can be collected.

The script restored the official GTX 1650 CSV files after the failed profiling attempt. Validation remained:

```text
timing rows: 1408
failed rows: 0
summary rows: 64
```

## Interpretation

No profiler-derived performance-counter metrics should be claimed yet. The report can honestly say that Nsight Compute profiling was prepared and attempted, but detailed counter collection was blocked by driver permission settings. The benchmark interpretation remains supported by the committed CSV files, timing statistics, speedups, GFLOP/s estimates, and correctness results.

After enabling NVIDIA performance-counter access, rerun:

```powershell
.\scripts\run_profiling.ps1
```

## Second Run

The profiling command was run again after the first documentation update:

```powershell
.\scripts\run_profiling.ps1
```

Result: the benchmark executable still launched and passed correctness for the first profiling case, but Nsight Compute still reported `ERR_NVGPUCTRPERM`. Therefore, performance-counter access is not enabled yet on this Windows/NVIDIA setup.

Practical fix to try next:

1. Open NVIDIA Control Panel.
2. Enable the Developer menu if it is hidden.
3. Open **Developer > Manage GPU Performance Counters**.
4. Select **Allow access to the GPU performance counters to all users**.
5. Apply the setting.
6. Rerun:

```powershell
.\scripts\run_profiling.ps1
```
