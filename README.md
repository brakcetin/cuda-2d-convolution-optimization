# CUDA 2D Convolution Optimization

CUDA implementations of 2D image convolution with CPU baseline, shared-memory tiling, constant-memory filters, separable convolution, and speedup analysis.

## Project Description

This repository is for the CENG-479 Parallel Programming final project:

**Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations**

The project studies how a sequential 2D grayscale image convolution baseline compares with progressively optimized CUDA implementations. The benchmark pipeline now reports correctness, repeat-based timing statistics, GFLOP/s estimates, GPU time breakdown, speedups, plots, and best-version summaries.

The implementation starts with the standard CUDA baseline: one CUDA thread computes one output pixel. It then adds memory-hierarchy-aware and algorithmic optimizations so the final report can compare how each design changes performance.

## Implemented Versions

- `cpu_sequential`: single-threaded CPU reference implementation.
- `cuda_naive_global_memory`: one CUDA thread per output pixel, 16x16 thread blocks, global-memory image/filter reads.
- `cuda_shared_memory_tiled`: input tile plus halo loaded into dynamic shared memory.
- `cuda_shared_constant_filter`: shared-memory input tile with filter coefficients stored in CUDA constant memory.
- `cuda_separable`: horizontal and vertical 1D passes for the generated separable box filter.

Planned next work:

- Add filter type experiments: box, Gaussian-like, sharpen, and Sobel-like filters.
- Add block-size comparison experiments: 8x8, 16x16, 32x8, and 32x16.
- Add advanced comparisons step by step after the benchmark foundation remains stable.

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
./build/convolution_benchmark --image-sizes 512,1024,2048 --filter-sizes 3,5,7,11 --repeats 5 --warmups 1 --versions all
```

On Windows with a Visual Studio generator:

```powershell
.\build\Release\convolution_benchmark.exe --image-sizes 512,1024,2048 --filter-sizes 3,5,7,11 --repeats 5 --warmups 1 --versions all
```

The program prints timing and correctness information for each benchmark case and writes CSV output files under `results/`.

Helper scripts are available under `scripts/`:

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
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

Current filter sizes:

- 3x3
- 5x5
- 7x7
- 11x11

Data generation:

- Synthetic grayscale images with random `float` values in `[0, 1]`.
- Normalized square filters where all coefficients sum to 1.
- Zero-padding at image boundaries.

Correctness verification:

- CPU output is the reference.
- CUDA output is compared against the CPU output.
- Metrics: maximum absolute error and mean absolute error.
- Tolerance: `1e-4`.

## Output Files

The main timing and correctness CSV files use the same expanded benchmark schema:

```text
image_width,image_height,filter_size,version,device_name,repeat_count,estimated_operations,cpu_time_ms,cpu_min_time_ms,cpu_max_time_ms,cpu_stddev_time_ms,gpu_kernel_time_ms,gpu_kernel_min_time_ms,gpu_kernel_max_time_ms,gpu_kernel_stddev_time_ms,gpu_total_time_ms,gpu_total_min_time_ms,gpu_total_max_time_ms,gpu_total_stddev_time_ms,gpu_allocation_time_ms,gpu_host_to_device_time_ms,gpu_device_to_host_time_ms,gpu_free_time_ms,kernel_speedup,total_speedup,cpu_gflops,gpu_kernel_gflops,max_abs_error,mean_abs_error,passed
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

The best-version summary files include:

```text
image_width,image_height,filter_size,best_kernel_time_version,best_total_time_version,best_kernel_speedup,best_total_speedup,correctness_status
```

## Final GTX 1650 Benchmark Summary

Official benchmark hardware:

- NVIDIA GeForce GTX 1650 with Max-Q Design

Official benchmark matrix:

- image sizes: 512x512, 1024x1024, 2048x2048
- filter sizes: 3x3, 5x5, 7x7, 11x11
- repeats: 5
- warmups: 1
- versions: all implemented CUDA versions

Official result summary:

- 48 benchmark rows were collected.
- All CUDA correctness checks passed.
- Maximum reported absolute error in the CSV is below `1e-6`.
- Best official kernel-only speedup is `329.099377x` for `cuda_separable` on 2048x2048 with 11x11 filter.
- Best official total GPU speedup is `30.094411x` for `cuda_shared_constant_filter` on 2048x2048 with 11x11 filter.
- The closest total-time competitor for that case is `cuda_separable` with `30.070500x`.

Supplemental 4096x4096 stress test:

- 16 benchmark rows were collected.
- All CUDA correctness checks passed.
- Best stress-test kernel-only speedup is `435.061000x` for `cuda_separable` with 11x11 filter.
- Best stress-test total GPU speedup is `35.031400x` for `cuda_separable` with 11x11 filter.

## Current Implementation Status

Completed:

- Initial CMake CUDA project structure.
- Single-threaded CPU convolution baseline.
- Naive CUDA global-memory convolution.
- CUDA error checking macro.
- Synthetic image/filter generation.
- Correctness comparison with max and mean absolute error.
- Configurable benchmark runner with repeat/warm-up counts and selectable versions.
- Timing statistics: average, minimum, maximum, and standard deviation.
- GPU timing breakdown: allocation, host-to-device copy, kernel, device-to-host copy, and free time.
- Estimated operation counts and CPU/CUDA kernel GFLOP/s.
- Best-version summary CSV generation.
- Shared-memory tiled CUDA implementation.
- Constant-memory filter CUDA implementation.
- Separable CUDA implementation for normalized box filters.
- Plot generation script for benchmark graphs.
- CSV result generation.

Limitations:

- No OpenCV or image file loading yet.
- Benchmarks use synthetic grayscale images and normalized box filters.
- GTX 1650 Max-Q is the official benchmark GPU, so absolute timings will differ on stronger GPUs.
- 4096x4096 is included as a supplemental stress test, while the official matrix uses 512/1024/2048 with 5 repeats.
- GPU total time is a per-run estimate built from fixed allocation/copy/free overhead plus each timed kernel sample; warm-up kernels are excluded.
- Profiling metrics from Nsight tools are not collected automatically yet.
