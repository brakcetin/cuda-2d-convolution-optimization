# 20260523 Phase 3 Block Size Sweep

## Purpose

This phase adds block-size and tile-shape comparison to the CUDA 2D convolution benchmark. The goal is to make the project stronger than a fixed-launch comparison by testing whether different CUDA block shapes change performance for the same convolution kernels.

This directly supports the proposal goal of a memory-hierarchy-aware CUDA performance study. It also connects to the adaptive tiling literature: tile shape can affect memory reuse, occupancy, halo overhead, and memory transaction behavior.

## Chronological Work Log

1. Started from a clean pushed Phase 2 state.

   Latest completed milestone before this phase:

   ```powershell
   git status --short
   ```

2. Added block-size data structures.

   Files changed:

   - `include/common.h`
   - `src/benchmark.h`

   Implementation:

   - Added `BlockSize` with default `16x16`.
   - Added `block_width` and `block_height` fields to benchmark results.
   - Added `block_sizes` to benchmark options.

3. Added command-line and script support.

   Files changed:

   - `src/main.cu`
   - `scripts/run_benchmarks.ps1`

   New CLI option:

   ```powershell
   --block-sizes 8x8,16x16,32x8,32x16
   ```

   New PowerShell wrapper option:

   ```powershell
   -BlockSizes "8x8,16x16,32x8,32x16"
   ```

   Validation rules:

   - block width must be positive
   - block height must be positive
   - `block_width * block_height <= 1024`
   - malformed values such as `16`, `x16`, or `16x0` fail with a clear error

4. Updated CUDA launch wrappers to use runtime block dimensions.

   Files changed:

   - `src/convolution_cuda.cuh`
   - `src/convolution_cuda.cu`

   Implementation:

   - Removed the hardcoded launch shape from CUDA wrappers.
   - Passed `block_width` and `block_height` into all CUDA versions:
     - `cuda_naive_global_memory`
     - `cuda_shared_memory_tiled`
     - `cuda_shared_constant_filter`
     - `cuda_separable`
   - Updated shared-memory allocation to use the selected block shape:

   ```cpp
   (block_width + 2 * radius) * (block_height + 2 * radius) * sizeof(float)
   ```

5. Updated benchmark execution and CSV outputs.

   File changed:

   - `src/benchmark.cpp`

   Implementation:

   - Added an inner loop over block sizes for every image/filter/filter-type case.
   - CPU reference and CPU timing are computed once per image/filter/filter-type case and reused across block-size runs.
   - Added `block_width` and `block_height` to timing and correctness CSV files.
   - Updated the best-version summary to report both the winning version and the winning block shape.

6. Updated plotting.

   File changed:

   - `scripts/plot_results.py`

   Implementation:

   - Existing plots filter to `box` and `16x16` when multiple filter/block configurations are present.
   - Added a new block-size plot:

   ```text
   results/plots/speedup_by_block_size_1024_7x7_box.png
   ```

7. Built and tested.

   Build command:

   ```powershell
   .\scripts\build_release.ps1
   ```

   Result:

   - Build passed.

8. Ran the Phase 3 smoke test.

   Command:

   ```powershell
   .\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -FilterTypes "box" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 2 -Warmups 1 -Versions "all"
   ```

   Result:

   - All rows passed correctness.
   - This confirmed that every CUDA version accepted runtime block dimensions.

9. Ran the Phase 3 correctness matrix.

   Command:

   ```powershell
   .\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "all"
   ```

   Result:

   - All rows passed correctness.
   - `cuda_separable` appeared only for `box` and `gaussian`.

10. Ran the official Phase 3 benchmark.

    Command:

    ```powershell
    .\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
    ```

    Result:

    - `672` rows collected.
    - `0` failed rows.
    - `0` invalid separable rows.
    - `0` invalid block-size rows.

    Official best kernel-time result:

    ```text
    452.838800x, 2048x2048, 11x11, gaussian, cuda_separable, block 32x8
    ```

    Official best total-time result:

    ```text
    33.483935x, 2048x2048, 11x11, gaussian, cuda_separable, block 32x8
    ```

11. Preserved the official Phase 3 results.

    Commands:

    ```powershell
    Copy-Item -LiteralPath results\timing_results.csv -Destination results\timing_results_gtx1650_official.csv
    Copy-Item -LiteralPath results\correctness_results.csv -Destination results\correctness_results_gtx1650_official.csv
    Copy-Item -LiteralPath results\summary_best_versions.csv -Destination results\summary_best_versions_gtx1650_official.csv
    ```

12. Ran the supplemental 4096x4096 stress refresh.

    Command:

    ```powershell
    .\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "all"
    ```

    Result:

    - `224` rows collected.
    - `0` failed rows.

    Stress best kernel-time result:

    ```text
    466.565398x, 4096x4096, 11x11, gaussian, cuda_separable, block 32x8
    ```

    Stress best total-time result:

    ```text
    36.696784x, 4096x4096, 11x11, box, cuda_separable, block 32x8
    ```

13. Preserved the 4096 stress results and restored the official matrix as the default CSV set.

    Commands:

    ```powershell
    Copy-Item -LiteralPath results\timing_results.csv -Destination results\timing_results_gtx1650_4096_stress.csv
    Copy-Item -LiteralPath results\correctness_results.csv -Destination results\correctness_results_gtx1650_4096_stress.csv
    Copy-Item -LiteralPath results\summary_best_versions.csv -Destination results\summary_best_versions_gtx1650_4096_stress.csv

    Copy-Item -LiteralPath results\timing_results_gtx1650_official.csv -Destination results\timing_results.csv
    Copy-Item -LiteralPath results\correctness_results_gtx1650_official.csv -Destination results\correctness_results.csv
    Copy-Item -LiteralPath results\summary_best_versions_gtx1650_official.csv -Destination results\summary_best_versions.csv
    ```

14. Regenerated plots from the official 672-row matrix.

    Command:

    ```powershell
    python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
    ```

    Generated plots:

    - `results/plots/speedup_by_version.png`
    - `results/plots/time_by_image_size_3x3.png`
    - `results/plots/speedup_by_filter_size_1024.png`
    - `results/plots/kernel_vs_total_time.png`
    - `results/plots/speedup_by_filter_type_1024_7x7.png`
    - `results/plots/speedup_by_block_size_1024_7x7_box.png`

15. Updated documentation.

    Files changed:

    - `README.md`
    - `docs/ImplementationNotes.md`
    - `notes/20260523_phase3_block_size_sweep.md`

## Interpretation

The block-size sweep makes the project more aligned with the proposal because it studies CUDA implementation choices instead of only reporting CPU versus one GPU version.

The strongest result still comes from `cuda_separable`, which is expected for box and Gaussian-like filters because it reduces work from `filter_size * filter_size` operations per pixel to two 1D passes. This agrees with the project goal: performance improvement is not only from the GPU, but also from choosing an implementation that matches filter structure.

The direct convolution results remain important because sharpen and Sobel-like filters are not treated as separable in this project. For those filters, shared memory and constant memory comparisons are the meaningful CUDA memory-hierarchy experiments.

The 32x8 block shape won the headline official and stress cases. However, the best-version summary shows that no block shape is universally best. This is useful for the report because it supports the adaptive-tiling idea from the papers: tile shape is a benchmark variable, not a fixed constant.

## Results To Use In The Report

Official GTX 1650 matrix:

```text
image sizes: 512, 1024, 2048
filter sizes: 3, 5, 7, 11
filter types: box, gaussian, sharpen, sobel
block sizes: 8x8, 16x16, 32x8, 32x16
repeats: 5
warmups: 1
rows: 672
failed rows: 0
```

Supplemental stress matrix:

```text
image size: 4096
filter sizes: 3, 5, 7, 11
filter types: box, gaussian, sharpen, sobel
block sizes: 8x8, 16x16, 32x8, 32x16
repeats: 3
warmups: 1
rows: 224
failed rows: 0
```

## Important Scripts And Commands

Environment check:

```powershell
.\scripts\check_environment.ps1
```

Configure:

```powershell
.\scripts\configure_release.ps1
```

Build:

```powershell
.\scripts\build_release.ps1
```

Official benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

4096 stress benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "all"
```

Plot generation:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Validation snippet:

```powershell
$rows = Import-Csv results\timing_results.csv
$failed = $rows | Where-Object { $_.passed -ne 'true' }
$badSep = $rows | Where-Object { $_.version -eq 'cuda_separable' -and $_.filter_type -notin @('box','gaussian') }
$badBlock = $rows | Where-Object { [int]$_.block_width -le 0 -or [int]$_.block_height -le 0 -or ([int]$_.block_width * [int]$_.block_height) -gt 1024 }
$bestKernel = $rows | Sort-Object {[double]$_.kernel_speedup} -Descending | Select-Object -First 1
$bestTotal = $rows | Sort-Object {[double]$_.total_speedup} -Descending | Select-Object -First 1
```

## Next Steps

1. Add a register-tiled or multi-output direct convolution version.
2. Compare that version mainly against direct convolution filters, especially sharpen and Sobel-like filters.
3. Keep separable convolution separate in the interpretation because it is an algorithmic optimization, not just a memory-hierarchy optimization.
4. Add report-ready tables that summarize:
   - best direct CUDA version per case
   - best overall CUDA version per case
   - best block shape per case
   - kernel speedup versus total speedup
