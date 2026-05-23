# 20260523 - Phase 1 Benchmark Rigor

## Purpose

This note records the implementation of the first expansion phase after the full roadmap: benchmark rigor. The goal was to make the current benchmark pipeline more credible before adding new filters, block-size sweeps, or advanced kernels.

## Chronological Work Log

1. Checked the repository status.
   ```powershell
   git status --short
   ```
   The tree was clean before implementation.

2. Inspected the benchmark and CUDA timing code.
   ```powershell
   Get-Content src\benchmark.h
   Get-Content src\benchmark.cpp
   Get-Content src\main.cu
   Get-Content src\convolution_cuda.cuh
   Get-Content include\common.h
   Get-Content src\convolution_cuda.cu
   ```

3. Extended common benchmark structures.
   - Added `TimingStats`.
   - Added CPU average/min/max/stddev fields.
   - Added CUDA kernel average/min/max/stddev fields.
   - Added CUDA total average/min/max/stddev fields.
   - Added GPU breakdown fields:
     - allocation
     - host-to-device copy
     - device-to-host copy
     - free
   - Added operation count and GFLOP/s fields.

4. Updated CPU timing.
   - The CPU baseline still runs single-threaded.
   - Every repeat is measured separately.
   - Average, minimum, maximum, and standard deviation are computed from repeat samples.
   - The final CPU output remains the correctness reference.

5. Updated CUDA timing.
   - Warmup kernels are still excluded from measured statistics.
   - Each measured repeat is timed with CUDA events.
   - Kernel statistics are computed from per-repeat event timings.
   - Total GPU time is estimated per run as:
     ```text
     allocation + host_to_device + kernel_sample + device_to_host + free
     ```
   - This keeps total-time statistics comparable while excluding warmup work.

6. Added CUDA context initialization before timed allocations.
   - The first smoke run showed that the first CUDA version paid one-time context startup cost inside allocation time.
   - `get_cuda_device_name()` now calls `cudaFree(nullptr)` before benchmarks begin.
   - This keeps total-time comparison fair across CUDA versions.

7. Added best-version summary output.
   - New file:
     ```text
     results/summary_best_versions.csv
     ```
   - It records the best kernel-time and total-time version for each image/filter case.

8. Built and fixed one syntax issue.
   - First build caught a missing parenthesis in the CPU timing sample push.
   - After patching, the build completed successfully.

## Commands Run

Environment check:

```powershell
.\scripts\check_environment.ps1
```

Configure:

```powershell
.\scripts\configure_release.ps1
```

Build:

```powershell
.\scripts\build_release.ps1
```

Smoke benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -Repeats 2 -Warmups 1 -Versions "all"
```

Correctness benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3,5,7,11" -Repeats 3 -Warmups 1 -Versions "all"
```

Official Phase 1 benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
```

CSV invariant check:

```powershell
$rows = Import-Csv results\timing_results.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$bad = $rows | Where-Object {
    [double]$_.cpu_min_time_ms -gt [double]$_.cpu_time_ms -or
    [double]$_.cpu_time_ms -gt [double]$_.cpu_max_time_ms -or
    [double]$_.gpu_kernel_min_time_ms -gt [double]$_.gpu_kernel_time_ms -or
    [double]$_.gpu_kernel_time_ms -gt [double]$_.gpu_kernel_max_time_ms -or
    [double]$_.gpu_total_min_time_ms -gt [double]$_.gpu_total_time_ms -or
    [double]$_.gpu_total_time_ms -gt [double]$_.gpu_total_max_time_ms -or
    [double]$_.cpu_gflops -le 0 -or
    [double]$_.gpu_kernel_gflops -le 0
}
"rows=$($rows.Count) failed=$($failed.Count) bad=$($bad.Count)"
```

Plot generation:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

4096 stress refresh:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -Repeats 3 -Warmups 1 -Versions "all"
```

## Results

Official Phase 1 matrix:

- Image sizes: `512,1024,2048`
- Filter sizes: `3,5,7,11`
- Repeats: `5`
- Warmups: `1`
- Versions: `all`
- Rows: `48`
- Correctness failures: `0`
- CSV invariant failures: `0`

Official best results:

- Best kernel-only speedup: `329.099377x`
- Best kernel-only case: `2048x2048`, `11x11`, `cuda_separable`
- Best total GPU speedup: `30.094411x`
- Best total-time case: `2048x2048`, `11x11`, `cuda_shared_constant_filter`
- Close total-time competitor: `cuda_separable`, `30.070500x`

Supplemental 4096 stress refresh:

- Rows: `16`
- Correctness failures: `0`
- Best kernel-only speedup: `435.061000x`
- Best total GPU speedup: `35.031400x`
- Best total-time case: `4096x4096`, `11x11`, `cuda_separable`

## Interpretation

The results remain aligned with the proposal:

- CPU is still the correctness and speedup baseline.
- All CUDA versions are compared against CPU.
- Kernel-only and total GPU speedup are both reported.
- The project now also reports statistical timing stability and GFLOP/s.

The results also align with the papers:

- The memory-hierarchy paper motivates separating transfer/allocation overhead from kernel time.
- The adaptive tiling paper motivates comparing shared memory and constant memory behavior by filter size.
- The register and memory-transaction papers motivate future work on communication reduction, but Phase 1 first made the measurement pipeline strong.
- The cuDNN and GpuCV papers motivate summary tables that identify the best implementation per configuration.

Important observation:

- The best kernel-time version and best total-time version can differ.
- For `2048x2048` with `11x11`, `cuda_separable` had the best kernel speedup, while `cuda_shared_constant_filter` narrowly had the best total speedup.
- This supports the report argument that kernel-only timing and practical end-to-end timing answer different questions.

Another useful observation:

- The `2048x2048`, `11x11`, `cuda_shared_memory_tiled` official run had high kernel standard deviation compared with the other 11x11 variants.
- This proves why min/max/stddev are valuable. Averages alone can hide unstable cases.

## Files Produced Or Updated

- `include/common.h`
- `src/benchmark.cpp`
- `src/benchmark.h`
- `src/convolution_cuda.cu`
- `src/main.cu`
- `README.md`
- `docs/ImplementationNotes.md`
- `results/timing_results.csv`
- `results/correctness_results.csv`
- `results/summary_best_versions.csv`
- `results/timing_results_gtx1650_official.csv`
- `results/correctness_results_gtx1650_official.csv`
- `results/summary_best_versions_gtx1650_official.csv`
- `results/timing_results_gtx1650_4096_stress.csv`
- `results/correctness_results_gtx1650_4096_stress.csv`
- `results/summary_best_versions_gtx1650_4096_stress.csv`
- `results/plots/`

## Next Steps

Next milestone:

```text
Phase 2 - Filter Type Experiments
```

Planned additions:

- Add `--filter-types`.
- Add box, Gaussian-like, sharpen, and Sobel-like filters.
- Keep separable convolution only for separable filters.
- Add `filter_type` to CSV outputs.
- Re-run correctness and benchmarks on GTX 1650.

This will strengthen the project by showing that the best convolution strategy depends not only on image size and filter size, but also on the mathematical structure of the filter.
