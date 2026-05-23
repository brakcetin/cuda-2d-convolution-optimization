# 20260523 Phase 4 Multi-Output And Register Tiling

## Purpose

This phase adds two direct-convolution CUDA kernels so the project is not only carried by separable convolution results. The goal is to strengthen the direct 2D convolution story for sharpen and Sobel-like filters, where `cuda_separable` is intentionally not used.

The related papers discuss memory hierarchy, tiling, and reducing communication or redundant work. This phase adds per-thread output tiling as a realistic course-project version of that idea: each thread computes two horizontal output pixels and keeps the accumulators local.

## Chronological Work Log

1. Confirmed the repository was clean before implementation.

   ```powershell
   git status --short
   ```

2. Added new CUDA wrapper declarations.

   File changed:

   - `src/convolution_cuda.cuh`

   New wrappers:

   ```cpp
   convolution_cuda_multi_output(...)
   convolution_cuda_register_tiled(...)
   ```

3. Added two direct-convolution kernels.

   File changed:

   - `src/convolution_cuda.cu`

   Implemented versions:

   - `cuda_multi_output`
   - `cuda_register_tiled`

   Kernel mapping:

   ```cpp
   x0 = (blockIdx.x * blockDim.x + threadIdx.x) * 2
   x1 = x0 + 1
   y = blockIdx.y * blockDim.y + threadIdx.y
   ```

   Grid width rule:

   ```cpp
   ceil(width / (2 * block_width))
   ```

   Interpretation:

   - `cuda_multi_output` computes two adjacent pixels per thread using direct global-memory filter reads.
   - `cuda_register_tiled` computes a 2x1 tile with two local accumulators.
   - Both preserve zero-padding and compare against the CPU direct convolution reference.
   - Neither uses shared memory or constant memory, so the phase isolates output tiling and register accumulation.

4. Wired the new versions into the benchmark runner.

   File changed:

   - `src/benchmark.cpp`

   Added aliases:

   ```text
   multi -> cuda_multi_output
   register -> cuda_register_tiled
   ```

   `--versions all` now includes both new direct kernels.

5. Updated plotting.

   File changed:

   - `scripts/plot_results.py`

   Added plot:

   ```text
   results/plots/direct_versions_speedup_1024_7x7_sobel.png
   ```

6. Built the project.

   Command:

   ```powershell
   .\scripts\build_release.ps1
   ```

   Result:

   - Build passed.

7. Ran smoke test for the two new kernels.

   Command:

   ```powershell
   .\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -FilterTypes "box,sobel" -BlockSizes "16x16,32x8" -Repeats 2 -Warmups 1 -Versions "cuda_multi_output,cuda_register_tiled"
   ```

   Result:

   - All rows passed correctness.

8. Ran correctness matrix for the two new kernels.

   Command:

   ```powershell
   .\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "cuda_multi_output,cuda_register_tiled"
   ```

   Result:

   - All rows passed correctness.

9. Ran official full Phase 4 benchmark.

   Command:

   ```powershell
   .\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
   ```

   Result:

   ```text
   rows: 1056
   failed rows: 0
   new kernel rows: 384
   bad separable rows: 0
   ```

   Best official kernel-only result:

   ```text
   449.182387x, 2048x2048, 11x11, gaussian, cuda_separable, block 32x8
   ```

   Best official total-time result:

   ```text
   36.267330x, 2048x2048, 11x11, sobel, cuda_shared_constant_filter, block 16x16
   ```

   Best official direct-convolution kernel-only result:

   ```text
   345.862019x, 1024x1024, 11x11, sharpen, cuda_shared_constant_filter, block 32x16
   ```

   Best official new-kernel result:

   ```text
   159.009746x, 1024x1024, 11x11, sharpen, cuda_register_tiled, block 32x8
   ```

10. Saved the official Phase 4 benchmark results.

    Commands:

    ```powershell
    Copy-Item -LiteralPath results\timing_results.csv -Destination results\timing_results_gtx1650_official.csv
    Copy-Item -LiteralPath results\correctness_results.csv -Destination results\correctness_results_gtx1650_official.csv
    Copy-Item -LiteralPath results\summary_best_versions.csv -Destination results\summary_best_versions_gtx1650_official.csv
    ```

11. Ran supplemental 4096x4096 stress benchmark.

    Command:

    ```powershell
    .\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "all"
    ```

    Result:

    ```text
    rows: 352
    failed rows: 0
    ```

    Best stress kernel-only result:

    ```text
    474.771679x, 4096x4096, 11x11, box, cuda_separable, block 32x8
    ```

    Best stress total-time result:

    ```text
    36.079514x, 4096x4096, 11x11, gaussian, cuda_separable, block 16x16
    ```

12. Saved stress results and restored the official matrix as default CSVs.

    Commands:

    ```powershell
    Copy-Item -LiteralPath results\timing_results.csv -Destination results\timing_results_gtx1650_4096_stress.csv
    Copy-Item -LiteralPath results\correctness_results.csv -Destination results\correctness_results_gtx1650_4096_stress.csv
    Copy-Item -LiteralPath results\summary_best_versions.csv -Destination results\summary_best_versions_gtx1650_4096_stress.csv

    Copy-Item -LiteralPath results\timing_results_gtx1650_official.csv -Destination results\timing_results.csv
    Copy-Item -LiteralPath results\correctness_results_gtx1650_official.csv -Destination results\correctness_results.csv
    Copy-Item -LiteralPath results\summary_best_versions_gtx1650_official.csv -Destination results\summary_best_versions.csv
    ```

13. Regenerated plots.

    Command:

    ```powershell
    python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
    ```

    New plot:

    ```text
    results/plots/direct_versions_speedup_1024_7x7_sobel.png
    ```

14. Updated documentation.

    Files changed:

    - `README.md`
    - `docs/ImplementationNotes.md`
    - `notes/20260523_phase4_multi_output_register_tiling.md`

## Interpretation

The new kernels are correct and useful, but they do not dominate the strongest established versions.

Important observations:

- `cuda_separable` still wins the overall kernel-only result because box and Gaussian-like filters are mathematically separable.
- `cuda_shared_constant_filter` wins the best official total-time result on an 11x11 Sobel-like case, which strengthens the direct-convolution memory-hierarchy story.
- `cuda_register_tiled` is stronger than `cuda_multi_output` in the best new-kernel case.
- Output tiling improves some direct cases, but constant-memory filter reuse is still more important for larger direct filters on the GTX 1650.

This is aligned with the proposal because the project now compares:

- CPU baseline
- naive CUDA
- shared-memory tiling
- constant-memory filters
- separable convolution
- block-size/tile-shape sensitivity
- multi-output/register-tiled direct convolution

## Important Scripts

Official Phase 4 benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

4096 stress benchmark:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "all"
```

New-kernel-only correctness matrix:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 3 -Warmups 1 -Versions "cuda_multi_output,cuda_register_tiled"
```

Plot generation:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

## Next Steps

1. Create report-ready tables from `results/summary_best_versions.csv`.
2. Add a short final report draft under `docs/`.
3. Prepare presentation slides with:
   - method overview
   - kernel design comparison
   - benchmark methodology
   - speedup plots
   - direct vs separable interpretation
4. Do not add more CUDA kernels unless the report/presentation are already stable.
