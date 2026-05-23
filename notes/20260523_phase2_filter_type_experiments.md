# 20260523 - Phase 2 Filter Type Experiments

## Purpose

This note records Phase 2 of the expanded CUDA convolution project: filter type experiments. The goal was to make the benchmark compare filter structure, not only image size and filter size.

## Chronological Work Log

1. Checked the current repository status.
   ```powershell
   git status --short
   ```
   The tree was clean before starting.

2. Inspected the filter, benchmark, CLI, CPU, and CUDA separable code.
   ```powershell
   Get-Content src\filters.h
   Get-Content src\filters.cpp
   Get-Content src\benchmark.h
   Get-Content src\main.cu
   Get-Content src\convolution_cpu.h
   Get-Content src\convolution_cpu.cpp
   ```

3. Added a `FilterSpec` generator.
   - `box`: normalized square filter plus 1D separable vector.
   - `gaussian`: normalized Gaussian-like 1D vector and 2D outer product.
   - `sharpen`: centered 3x3 sharpen kernel embedded in the selected filter size.
   - `sobel`: centered Sobel-X-like 3x3 kernel embedded in the selected filter size.

4. Added CPU separable reference.
   - Direct CUDA versions still compare against direct CPU convolution.
   - Separable CUDA now compares against CPU separable convolution.
   - This avoids pretending separable output should be compared against a different direct filter.

5. Updated CUDA separable convolution.
   - It now accepts the generated 1D filter vector.
   - It no longer internally assumes a box filter.
   - It runs for `box` and `gaussian` only.

6. Added CLI support.
   ```powershell
   --filter-types box,gaussian,sharpen,sobel
   ```
   PowerShell wrapper support:
   ```powershell
   -FilterTypes "box,gaussian,sharpen,sobel"
   ```

7. Updated CSV schema.
   - Added `filter_type` to timing and correctness rows.
   - Added `filter_type` to best-version summaries.
   - Best-version grouping is now image size + filter size + filter type.

8. Updated plotting.
   - Existing plots default to `box` rows when multiple filter types exist.
   - Added:
     ```text
     results/plots/speedup_by_filter_type_1024_7x7.png
     ```

## Commands Run

Build:

```powershell
.\scripts\build_release.ps1
```

Smoke test:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -FilterTypes "box,gaussian,sharpen,sobel" -Repeats 2 -Warmups 1 -Versions "all"
```

Correctness matrix:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -Repeats 3 -Warmups 1 -Versions "all"
```

Official Phase 2 GTX 1650 benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -Repeats 5 -Warmups 1 -Versions "all"
```

Validation:

```powershell
$rows = Import-Csv results\timing_results.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$badSep = $rows | Where-Object { $_.version -eq 'cuda_separable' -and $_.filter_type -notin @('box','gaussian') }
```

Plot generation:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

4096 stress refresh:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -Repeats 3 -Warmups 1 -Versions "all"
```

## Results

Official Phase 2 matrix:

- Image sizes: `512,1024,2048`
- Filter sizes: `3,5,7,11`
- Filter types: `box,gaussian,sharpen,sobel`
- Repeats: `5`
- Warmups: `1`
- Rows: `168`
- Correctness failures: `0`
- Invalid separable rows: `0`

Best official results:

- Best kernel-only speedup: `311.912111x`
- Best kernel-only case: `2048x2048`, `11x11`, `gaussian`, `cuda_separable`
- Best total GPU speedup: `30.644802x`
- Best total-time case: `2048x2048`, `11x11`, `box`, `cuda_separable`

Supplemental 4096 stress refresh:

- Rows: `56`
- Correctness failures: `0`
- Invalid separable rows: `0`
- Best kernel-only speedup: `486.423457x`
- Best kernel-only case: `4096x4096`, `11x11`, `gaussian`, `cuda_separable`
- Best total GPU speedup: `37.275758x`
- Best total-time case: `4096x4096`, `11x11`, `gaussian`, `cuda_separable`

## Interpretation

This phase strengthens the project because the proposal mentions real image-processing filters such as Gaussian blur, sharpening, and Sobel edge detection. The benchmark now reflects those examples instead of using only a box filter.

The main interpretation is:

- Box and Gaussian-like filters are separable, so `cuda_separable` is a valid algorithmic optimization.
- Sharpen and Sobel-like filters are handled by direct convolution only.
- Constant-memory filters are important for larger direct convolution cases.
- The best version depends on filter type, not only filter size.

This matches the literature:

- The adaptive tiling paper supports comparing performance across filter and tile characteristics.
- The memory-hierarchy paper supports separating kernel and total GPU time.
- GpuCV and cuDNN-style studies compare multiple implementations and configurations, which is now closer to our benchmark style.

## Important Implementation Detail

Sharpen and Sobel-like filters are centered 3x3 kernels embedded inside 5x5, 7x7, and 11x11 arrays. This keeps the benchmark matrix consistent while still testing direct kernels over the full selected filter size.

The GFLOP/s estimate still uses the full direct-loop operation count for these sparse filters because the implementation still loops over all filter coefficients.

## Next Steps

Next milestone:

```text
Phase 3 - Block Size And Tile Shape Comparison
```

Planned additions:

- Add block width and block height CLI options.
- Test `8x8`, `16x16`, `32x8`, and `32x16`.
- Add block dimensions to CSV files.
- Generate block-size comparison plots.
- Update best-version summaries so the report can discuss tile sensitivity.
