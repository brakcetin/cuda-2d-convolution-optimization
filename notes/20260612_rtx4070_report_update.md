# 20260612 - RTX 4070 Report Update

## Purpose

This note records the report update after pulling the teammate's RTX 4070 Laptop GPU benchmark results from GitHub.

## Pulled Commit

Latest pulled commit:

```text
9a85390 Add RTX 4070 Laptop GPU benchmark results
```

## Validation

GTX 1650 official results:

```text
timing rows: 1408
failed rows: 0
summary rows: 64
```

RTX 4070 Laptop GPU results:

```text
timing rows: 1408
failed rows: 0
summary rows: 64
```

## New RTX Result Files

```text
results\timing_results_rtx4070.csv
results\correctness_results_rtx4070.csv
results\summary_best_versions_rtx4070.csv
results\plots_rtx4070\
```

## Report Updates

Updated report-facing files:

- `README.md`
- `docs\FinalReport.md`
- `docs\BenchmarkTables.md`
- `docs\GpuComparison.md`
- `docs\ResultInterpretation.md`
- `docs\PresentationOutline.md`

## Interpretation

The GTX 1650 remains the official baseline because it is the consistent development benchmark machine. The RTX 4070 results are secondary evidence showing that the implementation scales to stronger hardware.

Key RTX observations:

- Best RTX kernel-only speedup: `1338.129858x`, `cuda_separable`, 1024x1024, 11x11 box, 16x16 block.
- Best RTX total GPU speedup: `79.304347x`, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel-like, 32x16 block.
- Best RTX direct-convolution speedup: `784.821102x`, `cuda_shared_constant_filter`, 4096x4096, 11x11 Sobel-like, 32x16 block.

The main interpretation remains stable: separable convolution wins when the filter is mathematically separable, while shared-memory tiling plus constant-memory filters is strongest for large direct convolution.

## Next Step

Regenerate or manually update the final PDF report from the updated Markdown report before submission.
