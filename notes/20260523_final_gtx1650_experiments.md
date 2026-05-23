# 20260523 - Final GTX 1650 Experiments

## Purpose

This note records the final experiment sequence for the CENG-479 CUDA 2D convolution project. It includes the exact commands, benchmark hardware, validation results, interpretations, and next steps.

## Hardware And Toolchain

Official benchmark GPU:

```text
NVIDIA GeForce GTX 1650 with Max-Q Design
```

Toolchain verified:

- CMake 4.3.3
- NVIDIA CUDA Toolkit 13.2
- `nvcc` 13.2.78
- Visual Studio Build Tools 2022
- MSVC 19.44
- NVIDIA driver 581.80

## Chronological Experiment Log

### 1. Preflight

Commands:

```powershell
git status --short
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
```

Result:

- Git was clean before experiments.
- CMake, `nvcc`, `nvidia-smi`, and MSVC were available.
- CMake configured successfully.
- `convolution_benchmark.exe` built successfully.

Interpretation:

The repository is reproducible from scripts on the GTX 1650 machine.

### 2. Correctness Smoke Test

Command:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3,5,7,11" -Repeats 1 -Warmups 1 -Versions "all"
```

Result:

- All CUDA versions passed for all tested filter sizes.
- This verified boundary handling and filter-radius handling for 3x3, 5x5, 7x7, and 11x11 filters.

### 3. Medium Stability Test

Command:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024" -FilterSizes "3,5,7,11" -Repeats 3 -Warmups 1 -Versions "all"
```

Result:

- All CUDA versions passed.
- No crashes, memory failures, or invalid timings were observed.

Interpretation:

This confirmed the project was stable enough for the official benchmark matrix.

### 4. Official Full Benchmark Matrix

Command:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
```

Official output files:

- `results/timing_results.csv`
- `results/correctness_results.csv`
- `results/timing_results_gtx1650_official.csv`
- `results/correctness_results_gtx1650_official.csv`

Result summary:

- Rows: 48
- CUDA versions: 4
- Image sizes: 512, 1024, 2048
- Filter sizes: 3, 5, 7, 11
- All correctness checks passed.
- Maximum reported absolute error in the CSV: `0.000001`
- Best kernel-only speedup: `482.630190x`, for 1024x1024, 11x11, `cuda_separable`
- Best total GPU speedup: `15.540952x`, for 2048x2048, 11x11, `cuda_separable`

Interpretation:

The CUDA implementations are correct for the official benchmark matrix. The separable version is the strongest result for large filters because the generated normalized box filter is separable and reduces arithmetic from `k*k` work per pixel to `2*k` work per pixel. The constant-memory filter version also improves larger direct-convolution cases compared with the naive/shared-only variants.

### 5. Optional 4096x4096 Stress Test

Command:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -Repeats 3 -Warmups 1 -Versions "all"
```

Supplemental output files:

- `results/timing_results_gtx1650_4096_stress.csv`
- `results/correctness_results_gtx1650_4096_stress.csv`

Result summary:

- Rows: 16
- All correctness checks passed.
- Maximum reported absolute error in the CSV: `0.000001`
- Best 4096 kernel-only speedup: `467.280821x`, for 11x11, `cuda_separable`
- Best 4096 total GPU speedup: `30.922419x`, for 11x11, `cuda_separable`

Interpretation:

4096x4096 is practical on the GTX 1650 for this project. It can be included as a supplemental stress-test table. The main report should still use the 512/1024/2048 matrix as the official benchmark matrix because those results are generated with 5 repeats.

### 6. Plot Generation

Command:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Generated plots:

- `results/plots/speedup_by_version.png`
- `results/plots/time_by_image_size_3x3.png`
- `results/plots/speedup_by_filter_size_1024.png`
- `results/plots/kernel_vs_total_time.png`

Note:

`matplotlib` was installed with:

```powershell
python -m pip install matplotlib
```

## Final Interpretation

The project now satisfies the core final-submission expectations:

- sequential CPU baseline exists
- multiple CUDA implementations exist
- correctness is verified for all official benchmark rows
- benchmark CSVs are generated
- graphs are generated
- hardware is documented
- notes record the exact methodology

The most important result for the report is that CUDA provides strong kernel-only speedups over the single-threaded CPU baseline, and the separable implementation becomes especially strong for larger filters. Total GPU timing is lower than kernel-only speedup because allocation and host-device transfers are included.

## Next Steps

1. Use the official CSVs and plots in the implementation report.
2. Add selected result tables to the presentation.
3. Discuss why first-run/total-time overhead can be high for small cases.
4. Commit and push final benchmark files, plots, documentation, and this note.
