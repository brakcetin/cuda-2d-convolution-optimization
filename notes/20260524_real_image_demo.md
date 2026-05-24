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

ImageMagick download source:

- https://imagemagick.org/download/#windows&gsc.tab=0

Downloaded installer:

- `C:\Users\Burak\Downloads\ImageMagick-7.1.2-23-Q16-HDRI-x64-dll.exe`

Installed executable:

- `C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe`

ImageMagick was installed, but `magick` was not detected on PATH in this PowerShell session:

```powershell
Get-Command magick -ErrorAction SilentlyContinue
```

Direct version check:

```powershell
& "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe" -version
```

Observed:

```text
Version: ImageMagick 7.1.2-23 Q16-HDRI x64
```

A helper script was updated:

```powershell
.\scripts\prepare_real_images.ps1
```

The helper script now detects ImageMagick in three ways:

1. `magick` on PATH.
2. `C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe`.
3. Any `C:\Program Files\ImageMagick*\magick.exe`.

If ImageMagick is not found, it falls back to Python/Pillow.

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

Observed output:

```text
Using ImageMagick: C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe
data\real_images\building.png -> data\real_images\building_1024.pgm
data\real_images\portrait.jpg -> data\real_images\portrait_1024.pgm
data\real_images\texture.png -> data\real_images\texture_1024.pgm
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
Kernel time ms: 0.250272
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
Kernel time ms: 0.407552
Max abs error: 3.57628e-07
Mean abs error: 3.04456e-08
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
Kernel time ms: 0.251232
Max abs error: 5.36442e-07
Mean abs error: 1.00909e-07
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
Kernel time ms: 0.240672
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
