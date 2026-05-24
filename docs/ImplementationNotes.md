# Implementation Notes

## Sequential Baseline

The CPU implementation is a single-threaded grayscale 2D convolution. It uses nested loops over output rows, output columns, filter rows, and filter columns. Boundary handling is zero-padding: out-of-image coordinates are skipped, which is equivalent to multiplying those locations by zero.

The CPU output is the correctness reference for direct 2D CUDA versions.

## CUDA Versions

Implemented versions:

- `cuda_naive_global_memory`: one CUDA thread computes one output pixel; input image and filter are read from global memory.
- `cuda_shared_memory_tiled`: each block loads a tile plus halo into dynamic shared memory, then computes output pixels from shared memory.
- `cuda_shared_constant_filter`: input tile is loaded into shared memory and filter coefficients are read from CUDA constant memory.
- `cuda_multi_output`: one thread computes two horizontally adjacent direct-convolution outputs using global-memory image and filter reads.
- `cuda_register_tiled`: one thread computes a 2x1 direct-convolution output tile with two register accumulators.
- `cuda_separable`: for generated separable filters, performs horizontal 1D convolution followed by vertical 1D convolution.

## Filter Types

Implemented synthetic filters:

- `box`: normalized square box filter. This is separable.
- `gaussian`: Gaussian-like normalized filter generated from a 1D Gaussian-style vector and outer product. This is separable.
- `sharpen`: canonical 3x3 sharpen kernel centered inside the selected odd filter size.
- `sobel`: canonical Sobel-X-like 3x3 edge filter centered inside the selected odd filter size.

The direct CPU and CUDA versions run all filter types. The separable CPU and CUDA paths run only `box` and `gaussian`, because sharpen and Sobel-like filters are not treated as separable in this project phase.

## Correctness Strategy

Every CUDA output is compared with the CPU output for the same image and filter.

Metrics:

- Maximum absolute error.
- Mean absolute error.
- Pass/fail with tolerance `1e-4`.

The separable version is valid for the current box and Gaussian-like filters because both are generated from 1D filters. Sharpen and Sobel-like filters are compared only with direct convolution variants.

## Optional PGM Demo Path

The official benchmark uses synthetic images because that keeps every run reproducible. The executable also supports a small real-image demo mode using dependency-free grayscale PGM files.

Demo command:

```powershell
.\scripts\prepare_real_images.ps1
.\scripts\run_pgm_demo.ps1 -InputPath "data\sample_input.pgm" -OutputPath "results\demo_output.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

The PGM path supports simple `P2` and `P5` grayscale images with max value up to 255. Output is written as an ASCII `P2` file. Output normalization is enabled by default so edge filters such as Sobel are visible in image viewers.

Current real-image examples:

- building image: Sobel edge detection
- portrait image: Gaussian blur and sharpen
- texture image: Sobel edge detection

## Benchmark Strategy

The benchmark executable supports configurable:

- image sizes
- filter sizes
- filter types
- CUDA block sizes
- repeat count
- warm-up count
- CUDA versions

Official final benchmark matrix:

- image sizes: 512, 1024, 2048, 4096
- filter sizes: 3, 5, 7, 11
- filter types: box, gaussian, sharpen, sobel
- block sizes: 8x8, 16x16, 32x8, 32x16
- repeats: 5
- warmups: 1

Official benchmark GPU:

- NVIDIA GeForce GTX 1650 with Max-Q Design

Historical supplemental stress files:

- Older 4096x4096 lower-repeat CSVs are preserved as historical artifacts.
- The current official matrix includes 4096x4096 with 5 repeats.

Phase 1 benchmark rigor update:

- CPU timing now records every repeat and reports average, minimum, maximum, and standard deviation.
- CUDA kernel timing now records every measured repeat with CUDA events.
- GPU total timing is reported as fixed allocation/copy/free overhead plus each measured kernel sample.
- GPU time breakdown is recorded for allocation, host-to-device copy, kernel, device-to-host copy, and free time.
- CSV output includes estimated operation count, CPU GFLOP/s, and CUDA kernel GFLOP/s.
- `results/summary_best_versions.csv` records the best kernel-time and best total-time version for each image/filter case.
- Phase 2 adds `filter_type` to all benchmark CSVs and groups best-version summaries by image size, filter size, and filter type.
- Phase 3 adds runtime-configurable CUDA block dimensions. All CUDA launches now use the selected block shape, shared-memory tile allocation uses `(block_width + 2 * radius) * (block_height + 2 * radius)`, and the best-version summary records the winning block shape.
- Phase 4 adds two direct-convolution output-tiling kernels. `cuda_multi_output` and `cuda_register_tiled` keep the same direct operation-count estimate as the other direct kernels because they change work assignment and reuse, not convolution mathematics.

## Performance Interpretation Guide

Expected trend:

1. CPU baseline is slowest for large images and filters.
2. Naive CUDA should be faster than CPU but inefficient due to repeated global memory reads.
3. Shared-memory tiling should improve reuse of overlapping input neighborhoods.
4. Constant-memory filters may improve filter coefficient reads, especially when many threads read the same coefficient.
5. Separable convolution should be strongest for large separable filters because arithmetic drops from `k*k` to `2*k` operations per pixel.

Observed final result highlights:

- All official benchmark rows passed correctness.
- Current official matrix contains 1408 rows: 4 image sizes * 4 filter sizes * 4 filter types * 4 block sizes, with six versions for box/Gaussian-like filters and five direct versions for sharpen/Sobel-like filters.
- Best official kernel-only speedup: `744.215965x`, 4096x4096, 11x11, `gaussian`, `cuda_separable`, 32x8 block.
- Best official total GPU speedup: `56.205213x`, 4096x4096, 11x11, `gaussian`, `cuda_separable`, 32x8 block.
- Best official direct-convolution kernel-only speedup: `432.778406x`, 4096x4096, 11x11, `sobel`, `cuda_shared_constant_filter`, 32x16 block.
- Best official new-kernel speedup: `409.607974x`, 512x512, 3x3, `sobel`, `cuda_register_tiled`, 16x16 block.

Interpretation:

The separable implementation is the strongest kernel-time version for large box and Gaussian-like filters because those filters are mathematically separable. It is intentionally not reported for sharpen or Sobel-like filters. Constant-memory filtering helps the direct convolution variants for larger filter sizes and is often the strongest direct-convolution option for sharpen and Sobel-like filters. Shared-memory tiling is useful when global-memory reuse offsets the extra tile-loading overhead. Small cases can show lower total GPU speedup because setup, allocation, and transfer costs dominate.

The block-size sweep supports the adaptive-tiling theme from the related literature: tile shape changes occupancy, memory coalescing behavior, shared-memory footprint, and halo overhead. The 32x8 block shape won the headline official kernel and total cases, but the best-version summary shows that no single shape dominates every image/filter/version combination. For the final report, this is stronger than reporting only a hardcoded 16x16 launch because it demonstrates that launch configuration is an experimental variable.

The multi-output and register-tiled direct kernels strengthen the direct-convolution comparison, especially for sharpen and Sobel-like filters where separable convolution is not reported. The register-tiled kernel is the stronger of the two new kernels in the official run, but the shared+constant direct kernel remains the best direct implementation overall for larger 11x11 sharpen/Sobel-like cases. This is still useful experimentally: it shows that output tiling helps some cases, while memory-hierarchy optimization of filter reads can dominate for larger direct filters.

The Phase 1 standard-deviation columns expose run-to-run stability. For example, the 2048x2048 11x11 shared-memory tiled run showed noticeably higher kernel variance than the other 11x11 direct variants. This is useful report evidence: a single average can hide benchmark instability, so min/max/stddev should be kept in the final tables or appendix.

## Submission Fit

The project fits Submission 2 because it includes:

- a sequential CPU baseline
- several parallel CUDA implementations
- correctness verification against CPU output
- benchmark tables and generated graphs
- GitHub-ready source code and scripts
- report and presentation drafts

No UI is required. A graphical interface would not improve the grading criteria unless the instructor specifically requested one. The strongest use of effort is the CUDA implementation, benchmark rigor, result interpretation, and presentation material.

## Challenges And Solutions

- Boundary handling can easily diverge between CPU and GPU. Solution: all versions use zero-padding semantics.
- Shared-memory halo indexing is error-prone. Solution: load a full `(blockDim + 2 * radius)` tile and use CPU comparison for every benchmark case.
- Hardcoded launch shapes can hide performance sensitivity. Solution: expose block sizes through CLI and scripts, validate them, and record the selected dimensions in every CSV row.
- Output-tiling kernels can be harder to interpret than separable convolution because they do not reduce the mathematical operation count. Solution: keep their operation estimate equal to other direct kernels and discuss them as scheduling/reuse experiments.
- Timing can be misleading if only one run is measured. Solution: configurable repeats, warmups, min/max/stddev, and GFLOP/s.
- GPU transfer overhead affects practical speedup. Solution: CSV includes kernel-only timing, total GPU timing, and allocation/copy/free breakdown.
- First CUDA calls and small workloads can have high total overhead. Solution: report kernel-only and total timing separately and use larger image sizes for final analysis.
