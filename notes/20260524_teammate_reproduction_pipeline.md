# 20260524 - Teammate Reproduction Pipeline

## Purpose

This note is written for a group member who pulls the project from GitHub and wants to reproduce the build, official benchmark validation, optional RTX 4070 run, and real-image demo workflow.

## 1. Fresh Pull

Run from the project directory:

```powershell
git pull
git status --short
```

The working tree should be clean before running official benchmarks.

## 2. Environment Check

```powershell
.\scripts\check_environment.ps1
```

This checks whether CMake, CUDA/NVCC, and NVIDIA GPU visibility are available.

## 3. Configure And Build

```powershell
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
```

The expected executable is:

```text
build\Release\convolution_benchmark.exe
```

## 4. Validate Official GTX 1650 Results

The committed official benchmark files are:

```text
results\timing_results.csv
results\correctness_results.csv
results\summary_best_versions.csv
results\timing_results_gtx1650_official.csv
results\correctness_results_gtx1650_official.csv
results\summary_best_versions_gtx1650_official.csv
```

Validation command:

```powershell
$rows = Import-Csv results\timing_results.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$summary = Import-Csv results\summary_best_versions.csv
$rows.Count
$failed.Count
$summary.Count
```

Expected:

```text
1408
0
64
```

## 5. Optional RTX 4070 Benchmark

GTX 1650 is the official benchmark GPU. RTX 4070 is optional secondary evidence.

Run:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

Save RTX files separately:

```powershell
Copy-Item results\timing_results.csv results\timing_results_rtx4070.csv
Copy-Item results\correctness_results.csv results\correctness_results_rtx4070.csv
Copy-Item results\summary_best_versions.csv results\summary_best_versions_rtx4070.csv
```

Validate RTX files:

```powershell
$rows = Import-Csv results\timing_results_rtx4070.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$summary = Import-Csv results\summary_best_versions_rtx4070.csv
$rows.Count
$failed.Count
$summary.Count
```

Expected:

```text
1408
0
64
```

## 6. Restore Official GTX 1650 Results After Experiments

Any benchmark run overwrites the default result CSVs. Restore official GTX 1650 files with:

```powershell
Copy-Item results\timing_results_gtx1650_official.csv results\timing_results.csv
Copy-Item results\correctness_results_gtx1650_official.csv results\correctness_results.csv
Copy-Item results\summary_best_versions_gtx1650_official.csv results\summary_best_versions.csv
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

## 7. Real-Image Demo File Map

Committed source images:

```text
data\real_images\building.png
data\real_images\portrait.jpg
data\real_images\texture.png
```

Committed converted PGM inputs:

```text
data\real_images\building_1024.pgm
data\real_images\portrait_1024.pgm
data\real_images\texture_1024.pgm
```

Committed real-image demo outputs:

```text
results\building_sobel.pgm
results\portrait_gaussian.pgm
results\portrait_sharpen.pgm
results\texture_sobel.pgm
```

The generated output files are committed as qualitative presentation references. They can still be regenerated locally to verify the demo workflow.

## 8. Prepare Real Images

```powershell
.\scripts\prepare_real_images.ps1
```

The script uses ImageMagick when available. Burak's installed path is:

```text
C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe
```

If ImageMagick is not available, the script falls back to Python/Pillow.

## 9. Run Real-Image Demos

Building Sobel:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\building_1024.pgm" -OutputPath "results\building_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

Portrait Gaussian:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_gaussian.pgm" -FilterType "gaussian" -FilterSize 11 -Version "cuda_separable" -BlockSize "32x8"
```

Portrait Sharpen:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_sharpen.pgm" -FilterType "sharpen" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

Texture Sobel:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\texture_1024.pgm" -OutputPath "results\texture_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

## 10. Interpretation

Use synthetic benchmark CSVs for official performance claims. Use real-image outputs only as qualitative demo material in the report or presentation.

The reason is methodological: synthetic inputs keep image size, filter size, filter type, repeats, and block sizes controlled. Real images make the presentation easier to understand visually, but they should not replace the official performance matrix.

## 11. Git Hygiene

Before committing any teammate results:

```powershell
git status --short
```

Commit RTX results separately from documentation changes if they are added:

```powershell
git add results docs notes
git commit -m "Add RTX 4070 comparison results"
git push
```

The real-image demo outputs are intentionally committed now because the team decided to include expected visual examples for teammate reproduction. Keep any extra temporary PGM experiments out of commits unless they are added to the documented demo set.

## 12. README Project Structure Refresh

The README project tree was refreshed after committing the real-image demo outputs. The old tree only showed the first milestone files and did not include the current `scripts/`, `data/real_images/`, `notes/`, expanded `docs/`, PGM demo path, or committed demo outputs.

Updated documentation now shows:

- current source modules, including `image_io.cpp` and `image_io.h`
- build, benchmark, plotting, and real-image helper scripts
- committed real-image inputs and converted PGM files
- official GTX 1650 CSV outputs
- committed qualitative PGM demo outputs
- final report, benchmark table, presentation, profiling, and result interpretation docs
- chronological notes folder

Interpretation: this makes the repository easier for a teammate to understand immediately after `git pull`, without needing to infer the current pipeline from scattered files.
