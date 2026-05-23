# 20260523 - Optional PGM Demo Path

## Purpose

This note records the optional real-image demo path. The official benchmark remains synthetic because it is reproducible and controlled. The PGM path exists only to make the final presentation/demo more concrete.

## Chronological Steps

### 1. Added PGM Image I/O

Files:

- `src/image_io.h`
- `src/image_io.cpp`

Supported formats:

- `P2` ASCII grayscale PGM
- `P5` binary grayscale PGM
- max value up to 255

Pixel representation:

- input pixels are converted to `float` values in `[0, 1]`
- output pixels are written as `P2`
- output normalization is enabled by default for demo visibility

### 2. Added Demo Mode To The Existing Executable

New CLI options:

```powershell
--demo-input input.pgm
--demo-output output.pgm
--demo-filter-type sobel
--demo-filter-size 3
--demo-version cuda_shared_constant_filter
--demo-block-size 16x16
--demo-normalize-output true
```

The demo path supports:

- `cpu`
- `cuda_naive_global_memory`
- `cuda_shared_memory_tiled`
- `cuda_shared_constant_filter`
- `cuda_multi_output`
- `cuda_register_tiled`
- `cuda_separable` for box and Gaussian-like filters only

### 3. Added Helper Script

File:

- `scripts/run_pgm_demo.ps1`

Default command:

```powershell
.\scripts\run_pgm_demo.ps1
```

Equivalent explicit command:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\sample_input.pgm" -OutputPath "results\demo_output.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

### 4. Added Sample Image

File:

- `data/sample_input.pgm`

This is a small 16x16 grayscale test image for dependency-free demos.

## Validation Commands

Build:

```powershell
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
```

Run demo:

```powershell
.\scripts\run_pgm_demo.ps1
```

Expected:

- `results/demo_output.pgm` is created.
- the executable prints CUDA version, image size, filter, kernel time, max/mean error, and pass/fail status.

## Interpretation

This feature makes the project feel more complete in a presentation because it can process a real grayscale image file. It does not replace the official benchmark matrix. The report should still treat synthetic image data as the official performance source because synthetic data makes the workload controlled and repeatable.

## Next Steps

1. Build and test the demo path.
2. Keep generated `results/demo_output.pgm` out of commits unless needed for presentation.
3. Use the demo only after showing the committed official benchmark plots.
