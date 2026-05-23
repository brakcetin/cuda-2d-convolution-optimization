# 20260523 - Initial CUDA Convolution Milestone

## Context

Repository/project:

- GitHub: https://github.com/brakcetin/cuda-2d-convolution-optimization.git
- Course: CENG-479 Parallel Programming
- Project title: Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations
- Final goal: provide a clean repository with CPU baseline, CUDA implementations, correctness verification, benchmark tables/graphs, and documentation.

The local directory initially contained only `docs/` with the proposal, implementation report requirements, and related papers. It was not initialized as a Git repository.

## What Was Implemented

Created the initial CMake/CUDA project structure:

- `README.md`
- `CMakeLists.txt`
- `.gitignore`
- `include/common.h`
- `src/main.cu`
- `src/convolution_cpu.cpp`
- `src/convolution_cpu.h`
- `src/convolution_cuda.cu`
- `src/convolution_cuda.cuh`
- `src/filters.cpp`
- `src/filters.h`
- `src/benchmark.cpp`
- `src/benchmark.h`
- `results/timing_results.csv`
- `results/correctness_results.csv`

Implemented the first working milestone:

- Sequential CPU baseline for grayscale 2D convolution.
- Naive CUDA global-memory convolution.
- Zero-padding at image boundaries.
- Support for odd square filter sizes such as 3x3, 5x5, 7x7, and 11x11.
- Random synthetic grayscale image generation.
- Normalized square filter generation.
- Correctness verification against the CPU output.
- Max absolute error and mean absolute error calculation.
- Correctness tolerance of `1e-4`.
- CPU timing with `std::chrono`.
- CUDA kernel timing with CUDA events.
- CSV writing for timing and correctness results.

Current benchmark cases:

- 512x512 image with 3x3 filter.
- 512x512 image with 5x5 filter.
- 1024x1024 image with 3x3 filter.
- 1024x1024 image with 5x5 filter.

## Implementation Interpretation

The first CUDA version intentionally uses the standard baseline approach: one CUDA thread computes one output pixel. Each thread reads the input image and filter coefficients from global memory. This is not the final optimized version, but it is the correct foundation for the project because it makes the CPU/GPU correctness comparison and timing pipeline stable before adding shared memory and constant memory.

This approach matches the project requirements and the common CUDA teaching pattern:

1. Write a sequential CPU reference implementation.
2. Write a simple CUDA version with the same boundary behavior.
3. Compare GPU output against CPU output.
4. Measure speedup.
5. Add memory-hierarchy optimizations only after correctness is stable.

I did not implement shared memory, constant memory, separable convolution, or OpenCV loading in this milestone because those belong to later milestones and would make debugging harder before the baseline is proven correct.

## How To Reimplement This Milestone

1. Create a CMake project with `LANGUAGES CXX CUDA`.
2. Use C++17 and CUDA C++17.
3. Store common result structs and tolerance in `include/common.h`.
4. Implement `convolution_cpu` as four nested loops:
   - image row
   - image column
   - filter row
   - filter column
5. For boundary handling, skip out-of-range image coordinates. This is equivalent to zero-padding.
6. Implement `convolution_naive_kernel` in CUDA:
   - compute `x` and `y` from `blockIdx`, `blockDim`, and `threadIdx`
   - return if outside the image
   - loop over filter rows/columns
   - skip out-of-range image coordinates
   - write one output value
7. Use a 16x16 CUDA block size.
8. Allocate/copy/free device memory inside the CUDA wrapper.
9. Run one warm-up kernel launch before timing.
10. Use CUDA events around the timed kernel launch.
11. Copy GPU output back to host.
12. Compare CPU and GPU outputs using max absolute error and mean absolute error.
13. Write CSV files with columns:
    `image_width,image_height,filter_size,version,cpu_time_ms,gpu_kernel_time_ms,speedup,max_abs_error,mean_abs_error,passed`

## Build And Run

Build:

```powershell
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

Run on Windows:

```powershell
.\build\Release\convolution_benchmark.exe
```

Run on Linux/macOS-style shell:

```bash
./build/convolution_benchmark
```

## Local Validation Status

The source files and project structure were created, but local compilation could not be completed because `cmake` and `nvcc` were not available on PATH in the current environment.

Before presenting or collecting benchmark numbers, install/enable:

- CMake 3.18 or newer
- NVIDIA CUDA Toolkit
- A C++17 compiler
- NVIDIA GPU driver

Then run the build and benchmark commands above.

## Git Tracking Decision

The directory was not a Git repository at the start of this milestone. The next action is to initialize Git locally, connect the GitHub remote, commit the milestone using Burak Cetin's configured Git identity, and push the branch.

## Next Steps

1. Install or configure CMake and CUDA Toolkit on the benchmark machine.
2. Build the project in Release mode.
3. Run the benchmark executable and verify that all CUDA runs pass correctness.
4. Save the generated CSV files.
5. Add shared-memory tiled CUDA convolution.
6. Add constant-memory filter coefficients.
7. Add 7x7 and 11x11 filter benchmark cases.
8. Add larger image sizes such as 2048x2048 and 4096x4096 if the GPU has enough memory and runtime is acceptable.
9. Generate performance graphs for the final report and presentation.
