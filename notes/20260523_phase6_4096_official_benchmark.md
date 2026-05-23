# 20260523 - Phase 6 4096 Official Benchmark

## Purpose

The 4096x4096 benchmark was previously treated as a lower-repeat stress test. After confirming that the GTX 1650 Max-Q can complete it reliably, we promoted 4096x4096 into the official benchmark matrix.

This makes the project stronger because the proposal explicitly discussed large images such as 2048x2048 and 4096x4096. The final benchmark now evaluates the largest planned image size with the same repeat count, filter matrix, filter-type matrix, block-size sweep, and correctness checks as the smaller cases.

## Chronological Log

### 1. Ran The New Official Benchmark

Command:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

Result:

- The run completed successfully on the GTX 1650 Max-Q.
- Runtime was about 247 seconds.
- Output files were written to:
  - `results/timing_results.csv`
  - `results/correctness_results.csv`
  - `results/summary_best_versions.csv`
- The benchmark reported that all CUDA runs passed correctness.

### 2. Validated The CSV Files

Command:

```powershell
$rows = Import-Csv results\timing_results.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$summary = Import-Csv results\summary_best_versions.csv
$rows.Count
$failed.Count
$summary.Count
```

Observed result:

```text
timing rows: 1408
failed rows: 0
summary rows: 64
```

Interpretation:

- The official matrix is now 4 image sizes * 4 filter sizes * 4 filter types * 4 block sizes.
- Box and Gaussian-like filters produce 6 CUDA rows each because `cuda_separable` is valid for them.
- Sharpen and Sobel-like filters produce 5 CUDA rows each because `cuda_separable` is intentionally skipped.
- This gives 352 benchmark rows per image size and 1408 rows total.

### 3. Preserved The Official CSV Files

Command:

```powershell
Copy-Item -LiteralPath results\timing_results.csv -Destination results\timing_results_gtx1650_official.csv
Copy-Item -LiteralPath results\correctness_results.csv -Destination results\correctness_results_gtx1650_official.csv
Copy-Item -LiteralPath results\summary_best_versions.csv -Destination results\summary_best_versions_gtx1650_official.csv
```

Interpretation:

- The default result CSVs and the official GTX 1650 CSVs now point to the same 4096-inclusive official matrix.
- The older `*_gtx1650_4096_stress.csv` files remain in the repository as historical lower-repeat stress artifacts.

### 4. Regenerated Plots

Command:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Generated plot files:

- `results/plots/speedup_by_version.png`
- `results/plots/time_by_image_size_3x3.png`
- `results/plots/speedup_by_filter_size_1024.png`
- `results/plots/kernel_vs_total_time.png`
- `results/plots/speedup_by_filter_type_1024_7x7.png`
- `results/plots/speedup_by_block_size_1024_7x7_box.png`
- `results/plots/direct_versions_speedup_1024_7x7_sobel.png`

### 5. Extracted Headline Results

Best official kernel-only result:

```text
cuda_separable
4096x4096
11x11 gaussian
block 32x8
kernel speedup: 744.215965x
```

Best official total-time result:

```text
cuda_separable
4096x4096
11x11 gaussian
block 32x8
total speedup: 56.205213x
```

Best direct-convolution kernel-only result:

```text
cuda_shared_constant_filter
4096x4096
11x11 sobel
block 32x16
kernel speedup: 432.778406x
```

Best new Phase 4 kernel result:

```text
cuda_register_tiled
512x512
3x3 sobel
block 16x16
kernel speedup: 409.607974x
```

### 6. Updated Documentation

Updated files:

- `README.md`
- `docs/BenchmarkTables.md`
- `docs/FinalReport.md`
- `docs/ImplementationNotes.md`
- `docs/PresentationOutline.md`

Main documentation changes:

- The official matrix now includes 4096x4096.
- Official row count changed from 1056 to 1408.
- The old 4096 stress result is no longer described as the main large-image result.
- The older stress CSVs are described as historical lower-repeat artifacts.
- Headline speedups now use the 4096-inclusive official run.

## Interpretation

Adding 4096x4096 to the official benchmark makes the project better aligned with the proposal because the proposal discussed large image sizes and performance scalability. It also strengthens the performance study: larger images reduce the relative impact of fixed GPU overhead and make kernel behavior easier to interpret.

The best overall result is now `cuda_separable` on a 4096x4096 Gaussian-like 11x11 filter. This is expected because separable convolution reduces arithmetic from `k*k` work per pixel to two `k`-length passes. This is an algorithmic improvement, not only a memory-hierarchy improvement.

For non-separable direct filters, the best result is still `cuda_shared_constant_filter`. That supports the memory-hierarchy focus of the project: shared-memory input tiling plus constant-memory filter coefficients is especially useful when direct convolution must still use the full 2D filter loop.

The `cuda_register_tiled` result remains useful, but it should be presented carefully. It is the strongest new Phase 4 kernel in one headline case, yet it does not replace shared+constant filtering as the best direct method for large 11x11 direct filters.

## Scripts Needed By Future Me

Environment and build:

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
```

Official benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

Validation:

```powershell
$rows = Import-Csv results\timing_results.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$summary = Import-Csv results\summary_best_versions.csv
$rows.Count
$failed.Count
$summary.Count
```

Plot generation:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Git checkpoint:

```powershell
git status --short
git add README.md docs notes results
git commit -m "Promote 4096 benchmark to official matrix"
git push
```

## Next Steps

1. Review `docs/FinalReport.md` and `docs/BenchmarkTables.md` for wording before submission.
2. Use `docs/PresentationOutline.md` to prepare the 10-minute presentation.
3. Optionally run the same official benchmark on the RTX 4070 for a secondary hardware comparison, but keep GTX 1650 as the official result source unless the report is updated consistently.
