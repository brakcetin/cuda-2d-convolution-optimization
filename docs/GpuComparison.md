# GTX 1650 And RTX 4070 Comparison

The official project benchmark uses the NVIDIA GeForce GTX 1650 with Max-Q Design. A secondary NVIDIA GeForce RTX 4070 Laptop GPU benchmark has also been collected with the same benchmark matrix. The RTX 4070 results are useful for hardware scaling discussion, but they do not replace the GTX 1650 official baseline.

## Rule

Do not mix GTX 1650 and RTX 4070 rows in the same official CSV files. Keep each GPU in separate files so the report remains reproducible.

## RTX 4070 Command

The teammate used the same benchmark workflow from the repository root:

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

The generated files were saved separately:

```powershell
Copy-Item results\timing_results.csv results\timing_results_rtx4070.csv
Copy-Item results\correctness_results.csv results\correctness_results_rtx4070.csv
Copy-Item results\summary_best_versions.csv results\summary_best_versions_rtx4070.csv
```

## Validation

Validation command:

```powershell
$rows = Import-Csv results\timing_results_rtx4070.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$summary = Import-Csv results\summary_best_versions_rtx4070.csv
$rows.Count
$failed.Count
$summary.Count
```

Observed values:

- timing rows: 1408
- failed rows: 0
- summary rows: 64

## Result Files

- GTX 1650 official baseline:
  - `results/timing_results.csv`
  - `results/correctness_results.csv`
  - `results/summary_best_versions.csv`
- RTX 4070 secondary benchmark:
  - `results/timing_results_rtx4070.csv`
  - `results/correctness_results_rtx4070.csv`
  - `results/summary_best_versions_rtx4070.csv`
  - `results/plots_rtx4070/`

## Headline Comparison

| Metric | GTX 1650 Max-Q | RTX 4070 Laptop GPU |
|---|---|---|
| Timing rows | 1408 | 1408 |
| Failed correctness rows | 0 | 0 |
| Summary rows | 64 | 64 |
| Best kernel-only speedup | 744.216x, `cuda_separable`, 4096x4096, 11x11 Gaussian, 32x8 | 1338.130x, `cuda_separable`, 1024x1024, 11x11 box, 16x16 |
| Best total GPU speedup | 56.205x, `cuda_separable`, 4096x4096, 11x11 Gaussian, 32x8 | 79.304x, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel, 32x16 |
| Best direct kernel-only speedup | 432.778x, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel, 32x16 | 784.821x, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel, 32x16 |

## Representative Same-Case Comparison

| Case | Version / Block | GTX kernel speedup | GTX total speedup | RTX kernel speedup | RTX total speedup |
|---|---|---:|---:|---:|---:|
| 4096x4096, 11x11 Gaussian | `cuda_separable`, 32x8 | 744.216x | 56.205x | 1145.663x | 72.970x |
| 4096x4096, 11x11 Sobel | `cuda_shared_constant_filter`, 32x16 | 432.778x | 36.610x | 784.821x | 79.304x |
| 1024x1024, 7x7 Sobel | `cuda_shared_constant_filter`, 32x16 | 146.015x | 13.634x | 491.757x | 20.534x |

## Interpretation

The RTX 4070 improves absolute GPU kernel times and increases many speedup values, especially for direct convolution. The relative interpretation remains consistent: separable convolution is strongest when the filter is mathematically separable, while `cuda_shared_constant_filter` is the strongest large direct-convolution method for Sobel-like workloads. The strongest RTX total-time result comes from the shared+constant direct kernel, showing that transfer and setup overhead can change the best total-time winner even when separable convolution has excellent kernel-only performance.
