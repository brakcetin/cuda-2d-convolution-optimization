# 20260523 - Initial CUDA Convolution Milestone

## Purpose Of This Note

This note is written for future reimplementation. If the project must be rebuilt from scratch, follow the chronological steps, file responsibilities, and scripts/commands below.

Repository/project:

- GitHub: https://github.com/brakcetin/cuda-2d-convolution-optimization.git
- Course: CENG-479 Parallel Programming
- Project title: Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations
- Final goal: source code, correctness verification, benchmark tables/graphs, clean GitHub repository, implementation report, and 10-minute final presentation.

## Chronological Work Log

### 1. Inspected The Existing Repository

The local project directory was:

```text
C:\Users\Burak\Burak\Projects\cuda-2d-convolution-optimization
```

Initial inspection showed:

- There was a `docs/` folder.
- The directory was not yet a Git repository.
- There was no `README.md`, `CMakeLists.txt`, `src/`, `include/`, or `results/` project structure.
- The existing documents contained the project proposal, implementation report requirements, and related papers.

Useful inspection commands:

```powershell
Get-ChildItem -Force
rg --files
git status --short
```

Interpretation:

The repository had academic/context material but not an implementation scaffold. Because this is a CUDA final project, the first priority was to create a reproducible build structure and a correct CPU/GPU baseline before adding advanced optimizations.

### 2. Checked Project Requirements And References

The local project documents were read first:

- `docs/Submissions/CENG479-Sub1-ProjectProposal.md`
- `docs/Submissions/CENG479-Sub1-ProjectProposal-2211808002-Burak_Cetin.md`
- `docs/Submissions/CENG479-Sub2-ImplementationReport.md`

Important extracted requirements:

- Language: English.
- Team size: 2 students.
- Source code must include sequential baseline and parallel CUDA version.
- Report must include GitHub link.
- Final presentation is 10 minutes and must include benchmark results.
- Grading prioritizes correctness, speedup analysis, code quality/documentation, and demo readiness.

External reference interpretation:

- CUDA's standard execution model maps naturally to image convolution by assigning one thread to one output pixel.
- A naive global-memory kernel is the correct first CUDA implementation because it is simple, comparable with the CPU reference, and becomes the baseline for later shared-memory and constant-memory versions.

Decision:

Do not start with shared memory or constant memory. First stabilize:

1. CPU baseline.
2. Naive CUDA baseline.
3. Correctness comparison.
4. Benchmark and CSV output.

### 3. Created The Project Structure

Created the requested structure:

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
├── docs/
└── notes/
    └── 20260523_initial_cuda_milestone.md
```

Useful directory creation command:

```powershell
New-Item -ItemType Directory -Force src, include, results, docs, notes | Out-Null
```

### 4. Added Common Data Structures

File:

- `include/common.h`

What it contains:

- `kCorrectnessTolerance = 1.0e-4f`
- `CorrectnessMetrics`
- `BenchmarkCase`
- `BenchmarkResult`

Reasoning:

These structs keep benchmark/correctness data consistent across `main`, benchmark code, and CSV writing.

### 5. Implemented The CPU Baseline

Files:

- `src/convolution_cpu.h`
- `src/convolution_cpu.cpp`

Method:

1. Accept `std::vector<float>` input image.
2. Accept `std::vector<float>` square filter.
3. Validate image dimensions and odd filter size.
4. Loop through every output pixel.
5. Loop through every filter coordinate.
6. Convert filter coordinate into image coordinate.
7. Skip out-of-range image coordinates.
8. Accumulate valid image/filter products.

Important detail:

Skipping out-of-range coordinates is equivalent to zero-padding because pixels outside the image contribute zero.

Pseudo-code:

```text
for y in image height:
    for x in image width:
        sum = 0
        for fy in filter size:
            for fx in filter size:
                image_y = y + fy - radius
                image_x = x + fx - radius
                if image coordinate is inside image:
                    sum += input[image_y, image_x] * filter[fy, fx]
        output[y, x] = sum
```

### 6. Implemented The Naive CUDA Version

Files:

- `src/convolution_cuda.cuh`
- `src/convolution_cuda.cu`

Kernel design:

- One CUDA thread computes one output pixel.
- Thread coordinates:
  - `x = blockIdx.x * blockDim.x + threadIdx.x`
  - `y = blockIdx.y * blockDim.y + threadIdx.y`
- If `x` or `y` is outside the image, return.
- Each thread loops over the filter and reads input/filter values from global memory.
- Boundary handling matches the CPU baseline by skipping out-of-range image coordinates.

Block size:

```text
16x16 threads
```

Reasoning:

16x16 gives 256 threads per block, which is a common and reasonable starting point for 2D image kernels. It is simple, readable, and suitable before doing occupancy/profiling-based tuning.

CUDA wrapper responsibilities:

1. Allocate device memory.
2. Copy input image and filter to device.
3. Launch one warm-up kernel.
4. Synchronize and check errors.
5. Create CUDA events.
6. Launch timed kernel.
7. Measure kernel-only time with CUDA events.
8. Copy output back to host.
9. Free CUDA resources.

CUDA error checking:

The macro `CUDA_CHECK(call)` was added in `src/convolution_cuda.cuh`. It prints the source file, line number, and CUDA error string, then exits.

### 7. Implemented Synthetic Data Generation

Files:

- `src/filters.h`
- `src/filters.cpp`

Implemented:

- `generate_random_image(width, height, seed)`
- `generate_normalized_filter(filter_size)`

Image generation:

- Uses `std::mt19937`.
- Generates random grayscale `float` values in `[0, 1]`.

Filter generation:

- Creates a square filter.
- Every value is `1.0 / (filter_size * filter_size)`.
- Filter coefficients sum to 1.

Reasoning:

No OpenCV or image loading is needed for the first milestone. Synthetic data keeps the benchmark reproducible and avoids external dependencies.

### 8. Implemented Correctness Verification

Files:

- `src/benchmark.h`
- `src/benchmark.cpp`

Function:

- `compare_outputs(reference, candidate, tolerance)`

Metrics:

- Max absolute error.
- Mean absolute error.
- Pass/fail with tolerance `1e-4`.

Formula:

```text
abs_error = abs(cpu_output[i] - gpu_output[i])
max_abs_error = max(all abs_error)
mean_abs_error = sum(abs_error) / number_of_pixels
passed = max_abs_error <= 1e-4
```

Reasoning:

The CPU implementation is the reference. Floating-point CPU/GPU differences are expected to be very small for this baseline, so `1e-4` is a reasonable tolerance.

### 9. Implemented Benchmarking

Files:

- `src/benchmark.h`
- `src/benchmark.cpp`
- `src/main.cu`

Current benchmark cases:

```text
512x512, 3x3
512x512, 5x5
1024x1024, 3x3
1024x1024, 5x5
```

CPU timing:

- Uses `std::chrono::high_resolution_clock`.

GPU timing:

- Uses CUDA events.
- Measures kernel-only time.

Speedup:

```text
speedup = cpu_time_ms / gpu_kernel_time_ms
```

CSV columns:

```text
image_width,image_height,filter_size,version,cpu_time_ms,gpu_kernel_time_ms,speedup,max_abs_error,mean_abs_error,passed
```

Output files:

- `results/timing_results.csv`
- `results/correctness_results.csv`

Note:

Both CSV files currently use the same schema and receive the same rows. Later, timing and correctness can be split more strictly if the report needs different tables.

### 10. Wrote The README

File:

- `README.md`

Included:

- Project description.
- Implemented versions.
- Technologies used.
- Build instructions.
- Run instructions.
- Benchmark parameters.
- Output files.
- Current implementation status.
- Known limitations.

Repository description used:

```text
CUDA implementations of 2D image convolution with CPU baseline, shared-memory tiling, constant-memory filters, separable convolution, and speedup analysis.
```

### 11. Checked Local Tool Availability

Commands tried:

```powershell
nvcc --version
cmake --version
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

Result:

- `nvcc` was not available on PATH.
- `cmake` was not available on PATH.
- Local build could not be completed in this environment.

Interpretation:

The source tree is prepared, but real compilation and benchmark collection must happen on a machine with CMake and CUDA Toolkit installed/configured.

### 12. Created Git Repository, Committed, And Pushed

The folder was not initially a Git repository, so Git was initialized.

Commands used:

```powershell
git init
git branch -M main
git remote add origin https://github.com/brakcetin/cuda-2d-convolution-optimization.git
git add .
git commit -m "Initial CUDA convolution benchmark project"
git push -u origin main
```

Commit created:

```text
9e8fc29 Initial CUDA convolution benchmark project
```

Author and committer:

```text
Burak Cetin <brakcetin660@gmail.com>
```

Important:

The commit belongs to Burak's configured Git identity. This is useful for project tracking and grading evidence.

## Important Scripts And Commands For Future Work

These are not stored as `.ps1` files yet, but they are the exact command blocks future-you can reuse. If the project grows, move them into a `scripts/` folder.

### Check Repository State

Use before starting any milestone:

```powershell
git status --short
git branch --show-current
git log --oneline --decorate -5
```

Purpose:

- Verify current branch.
- Verify whether there are uncommitted changes.
- See recent milestone commits.

### Check CUDA And Build Tools

Use before building:

```powershell
nvcc --version
cmake --version
nvidia-smi
```

Purpose:

- Confirms CUDA compiler exists.
- Confirms CMake exists.
- Confirms NVIDIA driver/GPU is visible.

### Configure CMake Build

Use from repository root:

```powershell
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
```

Purpose:

- Generates the build system in `build/`.
- Keeps generated files out of the source tree.

### Build The Project

For single-config generators:

```powershell
cmake --build build
```

For Visual Studio generators:

```powershell
cmake --build build --config Release
```

Purpose:

- Builds the `convolution_benchmark` executable.

### Run Benchmark On Windows

If using Visual Studio generator:

```powershell
.\build\Release\convolution_benchmark.exe
```

If using Ninja or another single-config generator:

```powershell
.\build\convolution_benchmark.exe
```

Purpose:

- Runs all benchmark cases.
- Prints CPU time, GPU kernel time, speedup, max/mean error, and pass/fail.
- Writes CSV files into `results/`.

### Run Benchmark On Linux

```bash
./build/convolution_benchmark
```

Purpose:

- Same benchmark flow on Linux.

### Inspect Result CSV Files

PowerShell:

```powershell
Get-Content results\timing_results.csv
Get-Content results\correctness_results.csv
```

Purpose:

- Quickly verify rows were written.
- Check that `passed` is `true`.
- Check that speedup values look reasonable.

### Clean Build Folder

Safer manual cleanup:

```powershell
Remove-Item -Recurse -Force build
```

Purpose:

- Removes generated build files when CMake cache/compiler settings are wrong.

Warning:

Only run this from the repository root and only for the `build` folder.

### Commit A New Milestone

Use after each meaningful milestone:

```powershell
git status --short
git add .
git commit -m "Describe milestone here"
git push
```

Purpose:

- Keeps progress trackable.
- Makes it easy to return to a known working state.

Commit message examples:

```text
Add shared memory tiled convolution
Add constant memory filter benchmark
Record benchmark results for naive CUDA kernel
Add benchmark plots for report
```

### Create A New Daily Note

Naming format:

```text
notes/YYYYMMDD_short_topic.md
```

Example:

```text
notes/20260524_shared_memory_tiling.md
```

Minimum sections to include:

```text
# YYYYMMDD - Topic

## Purpose
## Chronological Work Log
## What Changed
## Interpretation
## Commands/Scripts Used
## Validation
## Commit Information
## Next Steps
```

Purpose:

Future-you should be able to understand the exact order of work and reproduce the method without guessing.

## Current File Responsibilities

`CMakeLists.txt`

- Defines C++17/CUDA17 project.
- Builds `convolution_benchmark`.
- Includes `src/` and `include/`.

`include/common.h`

- Shared constants and result structs.

`src/convolution_cpu.cpp`

- Single-threaded CPU reference convolution.

`src/convolution_cuda.cu`

- Naive CUDA global-memory kernel and wrapper.

`src/convolution_cuda.cuh`

- CUDA wrapper declaration and error checking macro.

`src/filters.cpp`

- Synthetic image and filter generation.

`src/benchmark.cpp`

- Benchmark cases.
- Correctness comparison.
- Timing workflow.
- CSV writer.

`src/main.cu`

- Creates `results/`.
- Runs benchmarks.
- Writes CSV files.
- Returns nonzero if correctness fails.

`results/*.csv`

- CSV output targets.
- Currently committed with header rows so the folder exists in Git.

`notes/*.md`

- Chronological implementation notes and reimplementation guide.

## Current Limitations

- Local build was not verified because `cmake` and `nvcc` were missing from PATH.
- GPU timing is kernel-only. End-to-end GPU timing with memory copies should be added later.
- Only 512x512 and 1024x1024 images are benchmarked.
- Only 3x3 and 5x5 filters are benchmarked.
- No shared-memory tiled kernel yet.
- No constant-memory filter implementation yet.
- No separable convolution yet.
- No graphs yet.
- No image file loading or OpenCV, by design for this first milestone.

## Next Steps

1. Configure CUDA Toolkit and CMake on the benchmark machine.
2. Build the project in Release mode.
3. Run the benchmark executable.
4. Confirm all rows have `passed=true`.
5. Commit real benchmark CSV outputs if they are stable and useful.
6. Add a new daily note before implementing shared memory.
7. Implement shared-memory tiled CUDA convolution.
8. Compare `cuda_naive_global_memory` and `cuda_shared_memory_tiled`.
9. Add 7x7 and 11x11 filters.
10. Add 2048x2048 and possibly 4096x4096 image sizes.
11. Generate plots for report/presentation.
12. Keep each milestone as a separate commit with a clear message.
