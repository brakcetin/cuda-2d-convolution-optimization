# Presentation Outline

Target duration: 10 minutes  
Format: 10 slides  
Team split: both members present

## Slide 1 - Title and Problem

Speaker: Burak  
Time: 45 seconds

Content:

- Project title: Accelerating 2D Image Convolution on GPU
- Course: CENG-479 Parallel Programming
- Team: Burak Cetin and Cagri Celik
- Problem: direct 2D convolution is expensive for large images and filters

Speaker note:

Open by stating that the project is a CUDA performance study, not just a single GPU implementation.

## Slide 2 - Why Convolution Is Parallel

Speaker: Burak  
Time: 60 seconds

Content:

- Each output pixel can be computed independently
- Direct convolution cost grows with `width * height * filter_size^2`
- Neighboring pixels reuse overlapping input neighborhoods
- This creates both parallelism and memory-reuse opportunities

Visual:

- Small diagram or equation for 2D convolution

## Slide 3 - Implemented Versions

Speaker: Burak  
Time: 75 seconds

Content:

- CPU sequential baseline
- CUDA naive global memory
- CUDA shared-memory tiled
- CUDA shared + constant filter
- CUDA multi-output
- CUDA register-tiled
- CUDA separable for box/Gaussian-like filters

Speaker note:

Mention that sharpen and Sobel-like filters are not treated as separable, so direct CUDA versions remain important.

## Slide 4 - Benchmark Methodology

Speaker: Cagri  
Time: 75 seconds

Content:

- GPU: NVIDIA GeForce GTX 1650 with Max-Q Design
- Official matrix: 512, 1024, 2048 images
- Filters: 3x3, 5x5, 7x7, 11x11
- Filter types: box, Gaussian-like, sharpen, Sobel-like
- Block sizes: 8x8, 16x16, 32x8, 32x16
- Repeats: 5, warmups: 1

Visual:

- `results/plots/kernel_vs_total_time.png`

## Slide 5 - Correctness Verification

Speaker: Cagri  
Time: 60 seconds

Content:

- CPU output is the reference
- Metrics: max absolute error and mean absolute error
- Tolerance: `1e-4`
- Official benchmark: 1056 rows, 0 failures
- Stress benchmark: 352 rows, 0 failures

Speaker note:

This slide protects the project in Q&A: all performance numbers are backed by correctness checks.

## Slide 6 - Performance Results: Speedup by Version

Speaker: Burak  
Time: 90 seconds

Content:

- Best kernel-only speedup: 449.182x
- Case: 2048x2048, 11x11 Gaussian-like, `cuda_separable`, 32x8
- Separable convolution wins because it reduces work from `k^2` to `2k`

Visual:

- `results/plots/speedup_by_version.png`

## Slide 7 - Performance Results: Filter and Block Sensitivity

Speaker: Cagri  
Time: 90 seconds

Content:

- Filter type affects which optimization is best
- Block shape affects performance
- 32x8 often performs well, but no block shape wins everywhere

Visuals:

- `results/plots/speedup_by_filter_type_1024_7x7.png`
- `results/plots/speedup_by_block_size_1024_7x7_box.png`

## Slide 8 - Direct vs Separable Interpretation

Speaker: Burak  
Time: 90 seconds

Content:

- Best total GPU speedup: 36.267x
- Case: 2048x2048, 11x11 Sobel-like, `cuda_shared_constant_filter`, 16x16
- Best direct kernel-only speedup: 345.862x
- Best new Phase 4 kernel: `cuda_register_tiled`, 159.010x

Visual:

- `results/plots/direct_versions_speedup_1024_7x7_sobel.png`

Speaker note:

The key interpretation: separable is strongest when mathematically valid; constant memory is strongest for many large direct filters.

## Slide 9 - Challenges and Solutions

Speaker: Cagri  
Time: 75 seconds

Content:

- Boundary handling: solved with consistent zero-padding
- Shared-memory halo indexing: solved with CPU verification across all cases
- Timing noise: solved with repeats, warmups, min/max/stddev
- GPU overhead: reported kernel-only and total GPU speedup separately

## Slide 10 - Conclusion and Future Work

Speaker: Both  
Time: 90 seconds

Content:

- CUDA provides large speedups for 2D convolution
- Memory hierarchy matters, especially constant memory for direct filters
- Separable convolution is strongest when the filter supports it
- Block-size tuning is important
- Future work: Nsight profiling, RTX 4070 comparison, RGB images, real image input

Closing line:

The project meets the course goals by providing a correct CPU baseline, multiple CUDA implementations, reproducible benchmarking, CSV outputs, plots, and speedup analysis.

## Demo Flow

Use this if a short live demo is requested:

```powershell
.\scripts\check_environment.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -FilterTypes "box,sobel" -BlockSizes "16x16,32x8" -Repeats 2 -Warmups 1 -Versions "all"
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Important:

- For the final presentation, show committed official results, not the quick demo CSV produced by the smoke run.
- If the smoke run is used during practice, restore official CSVs afterward from `results/timing_results_gtx1650_official.csv`, `results/correctness_results_gtx1650_official.csv`, and `results/summary_best_versions_gtx1650_official.csv`.
