# 20260523 - Strong Project Execution Log

## Purpose

This note tracks the chronological implementation of the stronger CENG-479 CUDA convolution project plan. It should help future reimplementation by explaining what changed, why it changed, which commands were used, and what the next engineering step is.

## Chronological Work Log

### 1. Confirmed Current Repository State

Commands:

```powershell
git status --short
git log --oneline --decorate -5
rg --files docs notes src include results
```

Observed:

- `main` was already connected to `origin/main`.
- Latest pushed commit before execution was `20b50c1 Expand initial milestone notes`.
- The proposal document had been renamed locally.
- Git saw this as a deleted old proposal file plus a new renamed proposal file.

Interpretation:

The proposal rename was a separate history event and should be committed before any code work. That keeps the repository timeline understandable.

### 2. Committed Proposal Rename

Commands:

```powershell
git add docs\Submissions\CENG479-Sub1-ProjectProposal-2211808002-Burak_Cetin.md docs\Submissions\CENG479-Sub1-ProjectProposal-Cagri-Burak.md
git diff --cached --name-status
git commit -m "Rename project proposal document"
git push
```

Git recognized the change as a 100% rename:

```text
docs/Submissions/CENG479-Sub1-ProjectProposal-2211808002-Burak_Cetin.md
-> docs/Submissions/CENG479-Sub1-ProjectProposal-Cagri-Burak.md
```

Commit:

```text
4c560cb Rename project proposal document
```

Interpretation:

This commit belongs only to the document rename and was pushed immediately. This matches the project rule that commits should be useful checkpoints.

### 3. Added Helper Scripts

Added:

- `scripts/check_environment.ps1`
- `scripts/configure_release.ps1`
- `scripts/build_release.ps1`
- `scripts/run_benchmarks.ps1`

Why:

The project must be reproducible on an unknown CUDA GPU machine. These scripts reduce manual command mistakes during final benchmark collection.

Script purposes:

- `check_environment.ps1`: verifies `cmake`, `nvcc`, and `nvidia-smi`.
- `configure_release.ps1`: configures CMake Release build into `build/`.
- `build_release.ps1`: builds the configured project.
- `run_benchmarks.ps1`: runs benchmark executable with image sizes, filter sizes, repeats, warmups, and selected versions.

Future benchmark command example:

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
```

## Interpretation

The project is now moving from a small demo toward a real performance-study workflow. The scripts are intentionally simple because reliability and reproducibility matter more than clever automation for this course submission.

## Next Steps

1. Commit and push the helper scripts and this note.
2. Make the C++ benchmark executable accept CLI benchmark parameters.
3. Add all planned CUDA versions one milestone at a time.
4. Keep updating notes after each milestone.

### 4. Stabilized Benchmark Architecture

Changed the benchmark executable so it can be used as an experiment harness instead of a hard-coded demo.

New command-line options:

```powershell
.\build\Release\convolution_benchmark.exe --image-sizes 512,1024,2048 --filter-sizes 3,5,7,11 --repeats 5 --warmups 1 --versions all
```

What changed:

- Image sizes are configurable.
- Filter sizes are configurable.
- Repeat count is configurable.
- Warm-up count is configurable.
- Version selection is configurable.
- CSV output now includes device name, repeat count, GPU total time, kernel speedup, and total speedup.

Interpretation:

This turns the program into a proper benchmark tool. The final GPU is unknown, so the workload must be adjustable without recompiling. The default matrix is ambitious enough for the proposal but still realistic: 512, 1024, and 2048 image sizes with 3x3, 5x5, 7x7, and 11x11 filters.

Next step:

Add the shared-memory tiled CUDA version and plug it into the same benchmark pipeline.

### 5. Added Shared-Memory Tiled CUDA Convolution

Added version:

```text
cuda_shared_memory_tiled
```

Kernel idea:

- Each CUDA block still computes a 16x16 output tile.
- Threads cooperatively load a larger input tile into dynamic shared memory.
- The shared tile includes halo pixels required by the filter radius.
- Out-of-image halo values are loaded as zero, preserving zero-padding behavior.
- After `__syncthreads()`, each thread computes its output pixel from shared memory.

Why this matters:

The naive CUDA version repeatedly reads overlapping neighborhoods from global memory. Shared-memory tiling reduces redundant global memory traffic, especially for 7x7 and 11x11 filters. This directly matches the proposal's memory-hierarchy-aware optimization goal.

How to run only naive and shared versions:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "cuda_naive_global_memory,cuda_shared_memory_tiled"
```

Next step:

Add constant-memory filter coefficients, keeping shared-memory input tiling in place.

### 6. Added Constant-Memory Filter CUDA Version

Added version:

```text
cuda_shared_constant_filter
```

Kernel idea:

- Input image tile is still loaded into dynamic shared memory.
- Filter coefficients are copied into CUDA constant memory before launching the kernel.
- The constant filter storage supports the planned maximum direct filter size: 11x11, or 121 floats.

Why this matters:

The filter is small, read-only, and accessed by all threads. Constant memory is a standard CUDA memory-space optimization for this pattern. This gives the report a clean comparison:

```text
naive global memory -> shared input tile -> shared input tile + constant filter
```

How to run this comparison:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "cuda_naive_global_memory,cuda_shared_memory_tiled,cuda_shared_constant_filter"
```

Next step:

Add separable convolution for filters that can be represented as two 1D passes.

### 7. Added Separable CUDA Convolution

Added version:

```text
cuda_separable
```

Important assumption:

The current generated 2D filter is a normalized box filter. A box filter is separable, because a `k x k` average is equivalent to a horizontal `k`-element average followed by a vertical `k`-element average.

Kernel idea:

- First CUDA kernel computes horizontal 1D convolution into an intermediate image.
- Second CUDA kernel computes vertical 1D convolution from the intermediate image into the final output.
- The arithmetic cost drops from `k*k` multiply-adds per pixel to `2*k` multiply-adds per pixel.

Why this matters:

This gives the project an algorithmic optimization in addition to memory-hierarchy optimizations. For larger filters such as 11x11, separable convolution should be a strong performance result if the filter is separable.

How to run all implemented versions:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
```

Next step:

Add result plotting scripts and update final documentation so the repository is report-ready.

### 8. Added Plotting And Report-Ready Notes

Added:

- `scripts/plot_results.py`
- `results/plots/.gitkeep`
- `docs/ImplementationNotes.md`

Plot script outputs:

- `speedup_by_version.png`
- `time_by_image_size_3x3.png`
- `speedup_by_filter_size_1024.png`
- `kernel_vs_total_time.png`

Command:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Interpretation:

The project now has the full implementation skeleton for source code, benchmark data, generated graphs, and report notes. Real graph images should be generated only after running benchmarks on the actual CUDA machine.

Next step:

Run validation commands available in this environment, document tool limitations, and commit the documentation/plotting milestone.

### 9. Script Validation Fix

Fixed `scripts/run_benchmarks.ps1` so the `param(...)` block appears before executable PowerShell statements.

Why:

PowerShell scripts should declare parameters before `Set-StrictMode` and other executable statements. This keeps the benchmark runner script callable with named parameters such as `-ImageSizes`, `-FilterSizes`, and `-Versions`.

Validation:

```powershell
python scripts\plot_results.py --help
```

Result:

- Plot script argument parsing works.

PowerShell scripts were parsed with `System.Management.Automation.PSParser`.

Result:

- `check_environment.ps1`: syntax OK.
- `configure_release.ps1`: syntax OK.
- `build_release.ps1`: syntax OK.
- `run_benchmarks.ps1`: syntax OK after moving `param(...)`.

Environment check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check_environment.ps1
```

Observed:

- `nvidia-smi` exists.
- GPU visible: NVIDIA GeForce GTX 1650.
- Driver reports CUDA Version 13.0 support.
- `cmake` is missing from PATH.
- `nvcc` is missing from PATH.

Interpretation:

The machine has an NVIDIA driver and GPU visibility, but the build toolchain is not configured. Install CMake and CUDA Toolkit, or add them to PATH, before compiling and collecting final benchmark CSVs.

### 10. Installed CMake And CUDA Toolkit

Installed with winget:

```powershell
winget install --id Kitware.CMake -e --accept-source-agreements --accept-package-agreements
winget install --id Nvidia.CUDA -e --accept-source-agreements --accept-package-agreements
```

Installed versions verified in the current shell by prepending install folders to PATH:

```powershell
$env:Path = 'C:\Program Files\CMake\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin;' + $env:Path
cmake --version
nvcc --version
```

Observed:

- CMake 4.3.3 installed at `C:\Program Files\CMake\bin`.
- CUDA Toolkit 13.2 installed at `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2`.
- `nvcc` reports CUDA compilation tools release 13.2.

Added script helper:

- `scripts/tool_paths.ps1`

Why:

The current Codex/PowerShell process did not automatically pick up installer PATH changes. The project scripts now add common CMake and CUDA Toolkit paths for the current script process before checking, configuring, building, or running benchmarks.

Remaining issue:

`cl.exe` was not found on PATH, and no MSVC `cl.exe` was found under `C:\Program Files\Microsoft Visual Studio`. CUDA on Windows still needs a supported host C++ compiler, normally Visual Studio Build Tools with the C++ workload.

### 11. Installed Visual Studio Build Tools

Installed with winget:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-source-agreements --accept-package-agreements --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Observed:

- Visual Studio Build Tools installed at `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools`.
- `cl.exe` and `nmake.exe` are available under the MSVC toolchain folder.

Updated:

- `scripts/configure_release.ps1` now uses the Visual Studio generator:

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
```

Why:

The Visual Studio generator lets CMake discover the MSVC/CUDA host compiler setup without requiring every terminal to be a Developer Command Prompt.

### 12. Switched Scripts To Developer Command Environment

The Visual Studio generator did not detect the CUDA toolset immediately after installing Build Tools and CUDA. To make the project scripts more reliable, the CMake scripts now locate `VsDevCmd.bat` with `vswhere` and run configure/build inside the Visual Studio developer environment.

Updated:

- `scripts/tool_paths.ps1` now has `Get-VsDevCmdPath`.
- `scripts/configure_release.ps1` runs:

```powershell
cmd /c "`"$VsDevCmd`" -arch=x64 && cmake -S . -B build -G `"NMake Makefiles`" -DCMAKE_BUILD_TYPE=Release"
```

- `scripts/build_release.ps1` runs CMake build inside the same developer environment.

Why:

CUDA on Windows needs MSVC host compiler environment variables such as PATH, INCLUDE, and LIB. `VsDevCmd.bat` initializes those correctly.

### 13. Configured, Built, And Ran Smoke Benchmark

Commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check_environment.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\configure_release.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_release.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -Repeats 1 -Warmups 1 -Versions "all"
```

Environment result:

- CMake 4.3.3 found.
- CUDA Toolkit 13.2 found.
- `nvcc` found.
- NVIDIA GPU found: NVIDIA GeForce GTX 1650 with Max-Q Design.
- MSVC host compiler found through Visual Studio Build Tools developer environment.

Configure result:

- CMake detected MSVC 19.44.
- CMake detected CUDA compiler NVIDIA 13.2.78.
- Build files generated successfully.

Build result:

- `convolution_benchmark.exe` built successfully.

Smoke benchmark result:

- Image: 512x512.
- Filter: 3x3.
- Repeats: 1.
- Versions: all.
- All CUDA versions passed correctness.

Observed versions:

- `cuda_naive_global_memory`
- `cuda_shared_memory_tiled`
- `cuda_shared_constant_filter`
- `cuda_separable`

Interpretation:

The Windows CUDA build environment is now usable. The project has crossed an important line: it is no longer just source code, it configures, builds, runs on the GPU, and validates all implemented CUDA versions against the CPU baseline.

Next step:

Run the full benchmark matrix after deciding whether the GTX 1650 Max-Q should be the final benchmark GPU or only the development/test GPU.

### 14. Benchmark Hardware Decision

Decision:

All tests, correctness verification runs, and real benchmark runs for Burak's implementation workflow will be performed on:

```text
NVIDIA GeForce GTX 1650 with Max-Q Design
```

Context:

- Burak has the GTX 1650 machine locally.
- The group member has access to an RTX 4070.
- The RTX 4070 may be useful for optional comparison later, but it is not the primary benchmark source for Burak's current workflow.

Interpretation:

Using the GTX 1650 as the official benchmark machine keeps the workflow reproducible for Burak because the same machine is used for development, correctness checks, and result collection. The report should clearly state the benchmark hardware so the absolute speedup values are interpreted correctly.

Recommended wording for report:

```text
All benchmark results reported in this study were collected on an NVIDIA GeForce GTX 1650 with Max-Q Design. An RTX 4070 was available to another team member, but the main performance tables use a single consistent GPU platform to keep measurements reproducible.
```

Recommended full benchmark command for GTX 1650:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
```

Optional larger workload:

```powershell
.\scripts\run_benchmarks.ps1 -ImageSizes "4096" -FilterSizes "3,5,7,11" -Repeats 3 -Warmups 1 -Versions "all"
```

Only include 4096x4096 in the final report if it completes reliably on the GTX 1650 and does not make the benchmark process impractical.
