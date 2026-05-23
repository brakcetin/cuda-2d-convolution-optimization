# GTX 1650 And RTX 4070 Comparison Plan

The official project benchmark uses the NVIDIA GeForce GTX 1650 with Max-Q Design. RTX 4070 results can be added as secondary evidence if the teammate runs the same benchmark matrix.

## Rule

Do not mix GTX 1650 and RTX 4070 rows in the same official CSV files. Keep each GPU in separate files so the report remains reproducible.

## RTX 4070 Command

Run this on the RTX 4070 machine from the repository root:

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

Then copy the generated files:

```powershell
Copy-Item results\timing_results.csv results\timing_results_rtx4070.csv
Copy-Item results\correctness_results.csv results\correctness_results_rtx4070.csv
Copy-Item results\summary_best_versions.csv results\summary_best_versions_rtx4070.csv
```

## Validation

Expected validation:

```powershell
$rows = Import-Csv results\timing_results_rtx4070.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$summary = Import-Csv results\summary_best_versions_rtx4070.csv
$rows.Count
$failed.Count
$summary.Count
```

Expected values:

- timing rows: 1408
- failed rows: 0
- summary rows: 64

## What To Compare

Compare:

- best kernel-only speedup per GPU
- best total GPU speedup per GPU
- best direct-convolution kernel per GPU
- whether the same block shape wins
- whether RTX 4070 changes the relative ranking of kernels

## Report Interpretation

If RTX 4070 results are added, present them as secondary hardware comparison, not as a replacement for the GTX 1650 official baseline. The main report can say:

"The official benchmark was collected on the GTX 1650 Max-Q to keep the results reproducible on the development machine. A secondary RTX 4070 run can be used to show how the same implementation scales on a stronger GPU."

## Current Status

RTX 4070 benchmark CSVs have not been added yet. This document is the exact handoff plan for the teammate.
