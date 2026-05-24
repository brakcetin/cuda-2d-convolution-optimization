# 20260524 - Real Image Demo

## Purpose

This note records how the real-image demo inputs were prepared and tested. These images are for qualitative presentation/demo use only. The official benchmark remains the synthetic GTX 1650 matrix because it is controlled, reproducible, and already validated.

## Input Images

Downloaded files:

- `data/real_images/building.png`
- `data/real_images/portrait.jpg`
- `data/real_images/texture.png`

Converted demo inputs:

- `data/real_images/building_1024.pgm`
- `data/real_images/portrait_1024.pgm`
- `data/real_images/texture_1024.pgm`

## Tooling

ImageMagick was not detected on PATH in this session:

```powershell
Get-Command magick -ErrorAction SilentlyContinue
```

Python and Pillow were available, so the conversion used Python/Pillow locally. A helper script was added:

```powershell
.\scripts\prepare_real_images.ps1
```

The helper script uses ImageMagick if `magick` is available and falls back to Python/Pillow otherwise.

## Conversion Commands

ImageMagick form:

```powershell
magick "data\real_images\building.png" -colorspace Gray -resize 1024x1024! "data\real_images\building_1024.pgm"
magick "data\real_images\portrait.jpg" -colorspace Gray -resize 1024x1024! "data\real_images\portrait_1024.pgm"
magick "data\real_images\texture.png" -colorspace Gray -resize 1024x1024! "data\real_images\texture_1024.pgm"
```

Project helper form:

```powershell
.\scripts\prepare_real_images.ps1
```

## Demo Runs

Building Sobel:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\building_1024.pgm" -OutputPath "results\building_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

Result:

```text
Image: 1024x1024
Filter: sobel 3x3
Kernel time ms: 0.24992
Max abs error: 0
Mean abs error: 0
Passed: true
```

Portrait Gaussian:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_gaussian.pgm" -FilterType "gaussian" -FilterSize 11 -Version "cuda_separable" -BlockSize "32x8"
```

Result:

```text
Image: 1024x1024
Filter: gaussian 11x11
Kernel time ms: 0.409824
Max abs error: 3.57628e-07
Mean abs error: 3.04957e-08
Passed: true
```

Portrait Sharpen:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_sharpen.pgm" -FilterType "sharpen" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

Result:

```text
Image: 1024x1024
Filter: sharpen 3x3
Kernel time ms: 0.270368
Max abs error: 4.76837e-07
Mean abs error: 1.00891e-07
Passed: true
```

Texture Sobel:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\texture_1024.pgm" -OutputPath "results\texture_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

Result:

```text
Image: 1024x1024
Filter: sobel 3x3
Kernel time ms: 0.262304
Max abs error: 0
Mean abs error: 0
Passed: true
```

## Official Benchmark Validation

The official synthetic CSV files were not rerun. They still validate as:

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

## Interpretation

The real-image demo improves presentation quality because it shows actual edge detection, blur, and sharpening outputs. It does not replace the official benchmark. The official benchmark should remain synthetic because synthetic images make image size, filter type, repeats, and block sizes controlled and reproducible.

## Important Reminder

If the images are from a stock-photo or third-party source, keep a source/license note for the final report or replace them with photos taken by the team.
