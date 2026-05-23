# CUDA 2D Convolution Optimization

CUDA implementations of 2D image convolution with CPU baseline, shared-memory tiling, constant-memory filters, separable convolution, and speedup analysis.

## Project Description

This repository is for the CENG-479 Parallel Programming final project:

**Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations**

The project studies how a sequential 2D grayscale image convolution baseline compares with progressively optimized CUDA implementations. This first milestone establishes the correctness and benchmark pipeline using a CPU baseline and a naive global-memory CUDA kernel.

The current implementation intentionally starts with the standard CUDA baseline: one CUDA thread computes one output pixel, reading image pixels and filter coefficients directly from global memory. NVIDIA's CUDA programming model and sample convolution material use the same grid/block execution model as the foundation before introducing shared memory, constant memory, and separable filters. This keeps the first version correct, readable, and suitable for later memory-hierarchy experiments.

## Implemented Versions

- `cpu_sequential`: single-threaded CPU reference implementation.
- `cuda_naive_global_memory`: one CUDA thread per output pixel, 16x16 thread blocks, global-memory image/filter reads.

Planned next versions:

- Shared-memory tiled CUDA convolution.
- Constant-memory filter coefficients.
- Separable convolution for applicable filters.
- Larger benchmark matrix and graphs for the final report.

## Technologies Used

- C++17
- CUDA C++
- CMake
- `std::chrono` for CPU timing
- CUDA events for GPU kernel timing

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

Both CSV files use the same columns:

```text
image_width,image_height,filter_size,version,device_name,repeat_count,cpu_time_ms,gpu_kernel_time_ms,gpu_total_time_ms,kernel_speedup,total_speedup,max_abs_error,mean_abs_error,passed
```

Files:

- `results/timing_results.csv`
- `results/correctness_results.csv`

## Current Implementation Status

Completed:

- Initial CMake CUDA project structure.
- Single-threaded CPU convolution baseline.
- Naive CUDA global-memory convolution.
- CUDA error checking macro.
- Synthetic image/filter generation.
- Correctness comparison with max and mean absolute error.
- Configurable benchmark runner with repeat/warm-up counts and selectable versions.
- CSV result generation.

Limitations:

- No OpenCV or image file loading yet.
- GPU timing is kernel-only; host-device transfer timing will be added in a later milestone.
- Only 512x512 and 1024x1024 images with 3x3 and 5x5 filters are benchmarked in this first milestone.
- Shared memory, constant memory, separable convolution, profiling metrics, and graphs are planned next.
