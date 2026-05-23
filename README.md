# CUDA 2D Convolution Optimization

CUDA implementations of 2D image convolution with CPU baseline, shared-memory tiling, constant-memory filters, separable convolution, and speedup analysis.

## Project Description

This repository is for the CENG-479 Parallel Programming final project:

**Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations**

The project studies how a sequential 2D grayscale image convolution baseline compares with progressively optimized CUDA implementations. The benchmark pipeline now reports correctness, repeat-based timing statistics, GFLOP/s estimates, GPU time breakdown, speedups, plots, and best-version summaries.

The implementation starts with the standard CUDA baseline: one CUDA thread computes one output pixel. It then adds memory-hierarchy-aware and algorithmic optimizations so the final report can compare how each design changes performance.

## Implemented Versions

- `cpu_sequential`: single-threaded CPU reference implementation.
- `cuda_naive_global_memory`: one CUDA thread per output pixel, configurable thread-block shape, global-memory image/filter reads.
- `cuda_shared_memory_tiled`: input tile plus halo loaded into dynamic shared memory.
- `cuda_shared_constant_filter`: shared-memory input tile with filter coefficients stored in CUDA constant memory.
- `cuda_multi_output`: direct global-memory convolution where each thread computes two horizontal output pixels.
- `cuda_register_tiled`: direct global-memory 2x1 register-tiled convolution with two per-thread accumulators.
- `cuda_separable`: horizontal and vertical 1D passes for generated separable box and Gaussian-like filters.

Final polish items:

- Convert the Markdown report into the final PDF submission.
- Prepare the 10-minute presentation from the outline and committed plots.
- Optionally add RTX 4070 secondary results if the teammate runs the same benchmark matrix.

## Technologies Used

- C++17
- CUDA C++
- CMake
- `std::chrono` for CPU timing
- CUDA events for GPU kernel timing
- Repeat-based benchmark statistics and GFLOP/s estimates

## Project Structure

```text
cuda-2d-convolution-optimization/
├── README.md
├── CMakeLists.txt
├── .gitignore
├── src/
│   ├── main.cu
│   ├── convolution_cpu.cpp
│   ├── convolution_cpu.h
│   ├── convolution_cuda.cu
│   ├── convolution_cuda.cuh
│   ├── filters.cpp
│   ├── filters.h
│   ├── benchmark.cpp
│   └── benchmark.h
├── include/
│   └── common.h
├── results/
│   ├── timing_results.csv
│   └── correctness_results.csv
└── docs/
```

## Build Instructions

Requirements:

- NVIDIA GPU with CUDA support
- CUDA Toolkit with `nvcc`
- CMake 3.18 or newer
- A C++17-capable compiler

Build:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

On Windows with Visual Studio generators, the executable is usually created under `build/Release/`.

## Run Instructions

From the repository root:

```bash
./build/convolution_benchmark --image-sizes 512,1024,2048,4096 --filter-sizes 3,5,7,11 --filter-types box,gaussian,sharpen,sobel --block-sizes 8x8,16x16,32x8,32x16 --repeats 5 --warmups 1 --versions all
```

On Windows with a Visual Studio generator:

```powershell
.\build\Release\convolution_benchmark.exe --image-sizes 512,1024,2048,4096 --filter-sizes 3,5,7,11 --filter-types box,gaussian,sharpen,sobel --block-sizes 8x8,16x16,32x8,32x16 --repeats 5 --warmups 1 --versions all
```

The program prints timing and correctness information for each benchmark case and writes CSV output files under `results/`.

Helper scripts are available under `scripts/`:

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
```

Generate plots after benchmark CSV files are populated:

```powershell
python -m pip install matplotlib
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

## Benchmark Parameters

Current image sizes:

- 512x512
- 1024x1024
- 2048x2048
- 4096x4096

Current filter sizes:

- 3x3
- 5x5
- 7x7
- 11x11

Data generation:

- Synthetic grayscale images with random `float` values in `[0, 1]`.
- Filter types: normalized box, Gaussian-like, sharpen, and Sobel-like.
- Box and Gaussian-like filters are separable and are also tested with `cuda_separable`.
- Sharpen and Sobel-like filters use direct convolution versions only.
- Zero-padding at image boundaries.

CUDA block sizes:

- Default block shape: 16x16.
- Official block-size sweep: 8x8, 16x16, 32x8, and 32x16.
- Block sizes are validated so width and height are positive and width * height is at most 1024 threads.

Correctness verification:

- CPU output is the reference.
- CUDA output is compared against the CPU output.
- Metrics: maximum absolute error and mean absolute error.
- Tolerance: `1e-4`.

## Output Files

The main timing and correctness CSV files use the same expanded benchmark schema:

```text
image_width,image_height,filter_size,filter_type,version,device_name,block_width,block_height,repeat_count,estimated_operations,cpu_time_ms,cpu_min_time_ms,cpu_max_time_ms,cpu_stddev_time_ms,gpu_kernel_time_ms,gpu_kernel_min_time_ms,gpu_kernel_max_time_ms,gpu_kernel_stddev_time_ms,gpu_total_time_ms,gpu_total_min_time_ms,gpu_total_max_time_ms,gpu_total_stddev_time_ms,gpu_allocation_time_ms,gpu_host_to_device_time_ms,gpu_device_to_host_time_ms,gpu_free_time_ms,kernel_speedup,total_speedup,cpu_gflops,gpu_kernel_gflops,max_abs_error,mean_abs_error,passed
```

Files:

- `results/timing_results.csv`
- `results/correctness_results.csv`
- `results/summary_best_versions.csv`
- `results/timing_results_gtx1650_official.csv`
- `results/correctness_results_gtx1650_official.csv`
- `results/summary_best_versions_gtx1650_official.csv`
- `results/timing_results_gtx1650_4096_stress.csv`
- `results/correctness_results_gtx1650_4096_stress.csv`
- `results/summary_best_versions_gtx1650_4096_stress.csv`
- `results/plots/`

Final documentation artifacts:

- `docs/FinalReport.md`
- `docs/BenchmarkTables.md`
- `docs/PresentationOutline.md`
- `docs/ImplementationNotes.md`

The best-version summary files include:

```text
image_width,image_height,filter_size,filter_type,best_kernel_time_version,best_kernel_block_width,best_kernel_block_height,best_total_time_version,best_total_block_width,best_total_block_height,best_kernel_speedup,best_total_speedup,correctness_status
```

## Final GTX 1650 Benchmark Summary

Official benchmark hardware:

- NVIDIA GeForce GTX 1650 with Max-Q Design

Official benchmark matrix:

- image sizes: 512x512, 1024x1024, 2048x2048, 4096x4096
- filter sizes: 3x3, 5x5, 7x7, 11x11
- filter types: box, Gaussian-like, sharpen, Sobel-like
- block sizes: 8x8, 16x16, 32x8, 32x16
- repeats: 5
- warmups: 1
- versions: all implemented CUDA versions

Official result summary:

- 1408 benchmark rows were collected.
- All CUDA correctness checks passed.
- Maximum reported absolute error in the CSV is approximately `1e-6`, well below the `1e-4` tolerance.
- Best official kernel-only speedup is `744.215965x` for `cuda_separable` on 4096x4096 with 11x11 Gaussian-like filter using a 32x8 block.
- Best official total GPU speedup is `56.205213x` for `cuda_separable` on 4096x4096 with 11x11 Gaussian-like filter using a 32x8 block.
- Best official direct-convolution kernel-only speedup is `432.778406x` for `cuda_shared_constant_filter` on 4096x4096 with 11x11 Sobel-like filter using a 32x16 block.
- Best official new-kernel speedup is `409.607974x` for `cuda_register_tiled` on 512x512 with 3x3 Sobel-like filter using a 16x16 block.
- `cuda_separable` is reported only for box and Gaussian-like filters.

Historical supplemental 4096x4096 stress files:

- The older `*_4096_stress.csv` files are preserved as lower-repeat historical artifacts.
- The official analysis now uses 4096x4096 in the 5-repeat matrix above.

## Proposal And Submission Alignment

This repository satisfies the original proposal and Submission 2 requirements:

- Sequential baseline: `cpu_sequential` is single-threaded and used as the correctness oracle.
- Parallel implementation: multiple CUDA kernels are implemented and benchmarked.
- Memory hierarchy study: naive global memory, shared-memory tiling, constant-memory filters, and register/output tiling are compared.
- Filter comparison: box, Gaussian-like, sharpen, and Sobel-like filters are included.
- Large workload comparison: 512x512 through 4096x4096 image sizes are included in the official benchmark.
- Correctness verification: every CUDA row reports max/mean absolute error and pass/fail status.
- Performance analysis: CSVs and plots include CPU time, kernel time, total GPU time, speedup, GFLOP/s, and timing statistics.
- Documentation: final report draft, benchmark tables, implementation notes, and presentation outline are provided under `docs/`.

## UI Decision

No UI is required for this course project. The official deliverables are source code, GitHub link, implementation report, benchmark tables/graphs, and a 10-minute presentation. The project intentionally focuses on CUDA implementation quality, correctness verification, reproducible benchmarking, and result interpretation instead of building a graphical interface.

Report-ready plots:

- `results/plots/speedup_by_version.png`
- `results/plots/time_by_image_size_3x3.png`
- `results/plots/speedup_by_filter_size_1024.png`
- `results/plots/kernel_vs_total_time.png`
- `results/plots/speedup_by_filter_type_1024_7x7.png`
- `results/plots/speedup_by_block_size_1024_7x7_box.png`
- `results/plots/direct_versions_speedup_1024_7x7_sobel.png`

## Current Implementation Status

Completed:

- Initial CMake CUDA project structure.
- Single-threaded CPU convolution baseline.
- Naive CUDA global-memory convolution.
- CUDA error checking macro.
- Synthetic image/filter generation.
- Filter type generation for box, Gaussian-like, sharpen, and Sobel-like filters.
- Correctness comparison with max and mean absolute error.
- Configurable benchmark runner with repeat/warm-up counts and selectable versions.
- Configurable CUDA block-size sweep.
- Timing statistics: average, minimum, maximum, and standard deviation.
- GPU timing breakdown: allocation, host-to-device copy, kernel, device-to-host copy, and free time.
- Estimated operation counts and CPU/CUDA kernel GFLOP/s.
- Best-version summary CSV generation.
- Shared-memory tiled CUDA implementation.
- Constant-memory filter CUDA implementation.
- Multi-output direct CUDA implementation.
- Register-tiled direct CUDA implementation.
- Separable CUDA implementation for separable box and Gaussian-like filters.
- Plot generation script for benchmark graphs.
- Block-size speedup plot for the 1024x1024, 7x7, box-filter case.
- Direct-version speedup plot for the 1024x1024, 7x7, Sobel-like case.
- CSV result generation.

Limitations:

- No OpenCV or image file loading yet.
- Benchmarks use synthetic grayscale images.
- Sharpen and Sobel-like filters are centered 3x3 kernels embedded in larger odd filter sizes to preserve the same filter-size benchmark matrix.
- GTX 1650 Max-Q is the official benchmark GPU, so absolute timings will differ on stronger GPUs.
- 4096x4096 is included in the official benchmark matrix with 5 repeats. Older lower-repeat 4096 stress CSVs are kept only for historical comparison.
- Best block shape is workload-dependent; the summary CSV records winners instead of assuming one block shape is universally optimal.
- GPU total time is a per-run estimate built from fixed allocation/copy/free overhead plus each timed kernel sample; warm-up kernels are excluded.
- Profiling metrics from Nsight tools are not collected automatically yet.
