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
- Use the committed RTX 4070 results as secondary hardware comparison evidence.

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
|-- README.md
|-- CMakeLists.txt
|-- .gitignore
|-- src/
|   |-- main.cu
|   |-- benchmark.cpp / benchmark.h
|   |-- convolution_cpu.cpp / convolution_cpu.h
|   |-- convolution_cuda.cu / convolution_cuda.cuh
|   |-- filters.cpp / filters.h
|   `-- image_io.cpp / image_io.h
|-- include/
|   `-- common.h
|-- scripts/
|   |-- check_environment.ps1
|   |-- configure_release.ps1
|   |-- build_release.ps1
|   |-- run_benchmarks.ps1
|   |-- plot_results.py
|   |-- prepare_real_images.ps1
|   |-- run_pgm_demo.ps1
|   |-- run_profiling.ps1
|   |-- run_demo_dashboard.ps1
|   `-- tool_paths.ps1
|-- data/
|   |-- sample_input.pgm
|   `-- real_images/
|       |-- building.png / building_1024.pgm
|       |-- portrait.jpg / portrait_1024.pgm
|       `-- texture.png / texture_1024.pgm
|-- results/
|   |-- timing_results.csv
|   |-- correctness_results.csv
|   |-- summary_best_versions.csv
|   |-- timing_results_gtx1650_official.csv
|   |-- correctness_results_gtx1650_official.csv
|   |-- summary_best_versions_gtx1650_official.csv
|   |-- building_sobel.pgm
|   |-- portrait_gaussian.pgm
|   |-- portrait_sharpen.pgm
|   |-- texture_sobel.pgm
|   |-- profiling/
|   `-- plots/
|-- demo_app/
|   |-- server.py
|   |-- README.md
|   |-- requirements.txt
|   `-- static/
|-- docs/
|   |-- FinalReport.md
|   |-- BenchmarkTables.md
|   |-- ImplementationNotes.md
|   |-- PresentationOutline.md
|   |-- ResultInterpretation.md
|   |-- ProfilingGuide.md
|   |-- GpuComparison.md
|   |-- papers/
|   `-- Submissions/
`-- notes/
    |-- 20260523_*.md
    `-- 20260524_*.md
```

The `build/` directory is generated locally by CMake and is intentionally not part of the tracked source tree.

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

## Project Pipeline

Use this pipeline after pulling the repository on any CUDA-capable machine.

1. Pull the latest repository state:

   ```powershell
   git pull
   git status --short
   ```

2. Check the local CUDA/CMake/MSVC environment:

   ```powershell
   .\scripts\check_environment.ps1
   ```

3. Configure CMake:

   ```powershell
   .\scripts\configure_release.ps1
   ```

4. Build the Release executable:

   ```powershell
   .\scripts\build_release.ps1
   ```

5. Validate the committed official GTX 1650 result files:

   ```powershell
   $rows = Import-Csv results\timing_results.csv
   $failed = $rows | Where-Object { $_.passed -ne 'true' }
   $summary = Import-Csv results\summary_best_versions.csv
   $rows.Count
   $failed.Count
   $summary.Count
   ```

   Expected values:

   ```text
   1408
   0
   64
   ```

6. Run the official benchmark on another GPU only if new hardware results are needed:

   ```powershell
   .\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048,4096" -FilterSizes "3,5,7,11" -FilterTypes "box,gaussian,sharpen,sobel" -BlockSizes "8x8,16x16,32x8,32x16" -Repeats 5 -Warmups 1 -Versions "all"
   ```

   If this is an RTX 4070 run, save the generated CSV files separately:

   ```powershell
   Copy-Item results\timing_results.csv results\timing_results_rtx4070.csv
   Copy-Item results\correctness_results.csv results\correctness_results_rtx4070.csv
   Copy-Item results\summary_best_versions.csv results\summary_best_versions_rtx4070.csv
   ```

7. Generate plots from the current benchmark CSV:

   ```powershell
   python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
   ```

8. Prepare real-image demo inputs:

   ```powershell
   .\scripts\prepare_real_images.ps1
   ```

   This script uses ImageMagick when available. On Burak's machine it detects:

   ```text
   C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe
   ```

9. Run qualitative real-image demos:

   ```powershell
   .\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\building_1024.pgm" -OutputPath "results\building_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
   .\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_gaussian.pgm" -FilterType "gaussian" -FilterSize 11 -Version "cuda_separable" -BlockSize "32x8"
   .\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_sharpen.pgm" -FilterType "sharpen" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
   .\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\texture_1024.pgm" -OutputPath "results\texture_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
   ```

10. Restore official GTX 1650 CSVs after any smoke/demo benchmark that overwrites result files:

    ```powershell
    Copy-Item results\timing_results_gtx1650_official.csv results\timing_results.csv
    Copy-Item results\correctness_results_gtx1650_official.csv results\correctness_results.csv
    Copy-Item results\summary_best_versions_gtx1650_official.csv results\summary_best_versions.csv
    python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
    ```

11. Run the presentation dashboard and live image demo:

   ```powershell
   .\scripts\configure_release.ps1
   .\scripts\build_release.ps1
   python -m pip install -r demo_app\requirements.txt
   .\scripts\run_demo_dashboard.ps1
   ```

   Manual form:

   ```powershell
   cd demo_app
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   python server.py
   ```

   Open `http://127.0.0.1:5000`.

## Demo Dashboard Setup And Run

Use these steps when you want to show the project during the presentation. Run all commands in **Windows PowerShell**.

1. Open PowerShell and go to the repository root:

   ```powershell
   cd C:\Users\Burak\Burak\Projects\cuda-2d-convolution-optimization
   ```

2. Pull the latest GitHub version:

   ```powershell
   git pull
   git status --short
   ```

   `git status --short` should print nothing before starting a clean presentation run.

3. Check CUDA, CMake, Visual Studio compiler, and NVIDIA driver tools:

   ```powershell
   .\scripts\check_environment.ps1
   ```

4. Configure and build the CUDA executable:

   ```powershell
   .\scripts\configure_release.ps1
   .\scripts\build_release.ps1
   ```

   The demo backend automatically searches for:

   ```text
   build\Release\convolution_benchmark.exe
   build\convolution_benchmark.exe
   ```

5. Install the Python packages for the local web app:

   ```powershell
   python -m pip install -r demo_app\requirements.txt
   ```

   Optional virtual environment form:

   ```powershell
   cd demo_app
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   cd ..
   ```

6. Start the dashboard:

   ```powershell
   .\scripts\run_demo_dashboard.ps1
   ```

7. Open the app in a browser:

   ```text
   http://127.0.0.1:5000
   ```

8. Use **Dashboard Mode** first:

   - Show GTX 1650 and RTX 4070 row counts and correctness badges.
   - Show CPU time, CUDA kernel time, total GPU time, speedup, and error metrics.
   - Show plots and explain kernel-only speedup versus total GPU speedup.

9. Use **Live Image Demo Mode** for a real image:

   - Upload `data\real_images\building.png`.
   - Select `sobel`, filter size `3`, version `cuda_shared_constant_filter`, block size `16x16`.
   - Click **Run CUDA Demo**.
   - Show the original image, filtered output image, timing metrics, and correctness result.

   A second good demo is:

   - Upload `data\real_images\portrait.jpg`.
   - Select `gaussian`, filter size `11`, version `cuda_separable`, block size `32x8`.

10. Stop the dashboard after the presentation:

    ```text
    Press Ctrl+C in the PowerShell window running the Flask server.
    ```

Presentation note: Dashboard Mode is the safe fallback and works from committed CSV/plot files. Live Image Demo Mode runs the real CUDA executable. Benchmark timing mostly depends on image dimensions, filter size, CUDA version, block size, GPU model, and transfer overhead; it does not mainly depend on what the image semantically contains.

Troubleshooting:

- If Flask or Pillow is missing, run `python -m pip install -r demo_app\requirements.txt`.
- If the app says the CUDA executable is missing, rerun `.\scripts\configure_release.ps1` and `.\scripts\build_release.ps1`.
- If port `5000` is busy, run `.\scripts\run_demo_dashboard.ps1 -Port 5001` and open `http://127.0.0.1:5001`.
- If `cuda_separable` gives a validation error, choose `box` or `gaussian`; separable convolution is not valid for `sobel` or `sharpen` in this project.
- If a virtual environment is created but `pip` is unavailable, use the non-venv command from the repository root: `python -m pip install -r demo_app\requirements.txt`.
- If Chrome reports `ERR_NO_BUFFER_SPACE` for `app.js`, the Flask server is usually still working. Stop the server with `Ctrl+C`, close extra browser tabs, restart the dashboard on another port with `.\scripts\run_demo_dashboard.ps1 -Port 5001`, and open `http://127.0.0.1:5001`. Edge or an incognito Chrome window is also a good fallback.

Generate plots after benchmark CSV files are populated:

```powershell
python -m pip install matplotlib
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

Optional PGM demo path:

```powershell
.\scripts\prepare_real_images.ps1
.\scripts\run_pgm_demo.ps1 -InputPath "data\sample_input.pgm" -OutputPath "results\demo_output.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

The PGM demo is for presentation/demo use only. It does not replace the official synthetic benchmark matrix. `prepare_real_images.ps1` uses ImageMagick when available; on this machine it detects `C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe`.

Real demo examples:

```powershell
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\building_1024.pgm" -OutputPath "results\building_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_gaussian.pgm" -FilterType "gaussian" -FilterSize 11 -Version "cuda_separable" -BlockSize "32x8"
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\portrait_1024.pgm" -OutputPath "results\portrait_sharpen.pgm" -FilterType "sharpen" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
.\scripts\run_pgm_demo.ps1 -InputPath "data\real_images\texture_1024.pgm" -OutputPath "results\texture_sobel.pgm" -FilterType "sobel" -FilterSize 3 -Version "cuda_shared_constant_filter" -BlockSize "16x16"
```

## Real Image File Map

Committed source images:

- `data/real_images/building.png`
- `data/real_images/portrait.jpg`
- `data/real_images/texture.png`

Committed converted PGM demo inputs:

- `data/real_images/building_1024.pgm`
- `data/real_images/portrait_1024.pgm`
- `data/real_images/texture_1024.pgm`

Committed real-image demo outputs:

- `results/building_sobel.pgm`
- `results/portrait_gaussian.pgm`
- `results/portrait_sharpen.pgm`
- `results/texture_sobel.pgm`

The real-image files are qualitative presentation/demo material. Official speedup claims use the synthetic benchmark CSV files under `results/`. The demo outputs are committed so a teammate can immediately inspect the expected visual results after pulling the repository.

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
- `docs/ResultInterpretation.md`
- `docs/ProfilingGuide.md`
- `docs/GpuComparison.md`
- `docs/PresentationOutline.md`
- `docs/ImplementationNotes.md`

The best-version summary files include:

```text
image_width,image_height,filter_size,filter_type,best_kernel_time_version,best_kernel_block_width,best_kernel_block_height,best_total_time_version,best_total_block_width,best_total_block_height,best_kernel_speedup,best_total_speedup,correctness_status
```

## Final GTX 1650 Benchmark Summary

Official benchmark hardware:

- NVIDIA GeForce GTX 1650 with Max-Q Design
- Secondary comparison hardware: NVIDIA GeForce RTX 4070 Laptop GPU

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

Secondary RTX 4070 result summary:

- 1408 benchmark rows were collected.
- All CUDA correctness checks passed.
- Best RTX kernel-only speedup is `1338.129858x` for `cuda_separable` on 1024x1024 with 11x11 box filter using a 16x16 block.
- Best RTX total GPU speedup is `79.304347x` for `cuda_shared_constant_filter` on 4096x4096 with 11x11 Sobel-like filter using a 32x16 block.
- RTX plots are available under `results/plots_rtx4070/`.

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

No UI is required for this course project, but a local demo dashboard is now included for presentation readiness. The dashboard does not replace the official benchmark methodology; it visualizes committed CSV/plot results and can optionally run the CUDA executable on an uploaded real image.

Demo app:

- `demo_app/server.py`
- `demo_app/static/index.html`
- `demo_app/static/styles.css`
- `demo_app/static/app.js`
- `demo_app/README.md`

The demo has two modes: a safe dashboard mode using committed GTX/RTX results, and a live image mode that converts uploaded images to grayscale PGM and runs the CUDA executable.

## Nsight Compute Profiling

Optional profiling evidence can be collected for three representative cases:

```powershell
.\scripts\run_profiling.ps1
```

The script writes text summaries under `results/profiling/` and restores the official GTX 1650 CSV files after profiling. Profiling is supporting evidence only; official speedup claims still come from the committed synthetic benchmark CSV files.

Current note: on this Windows setup, Nsight Compute can attach to the benchmark executable, but detailed GPU counter collection is blocked by NVIDIA's `ERR_NVGPUCTRPERM` permission setting until performance-counter access is enabled.

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
- Optional dependency-free PGM image loading/writing demo path.
- Real-image demo inputs under `data/real_images/`.
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
- Nsight Compute profiling helper for representative kernels.
- Local Flask demo dashboard with live image upload mode.
- Block-size speedup plot for the 1024x1024, 7x7, box-filter case.
- Direct-version speedup plot for the 1024x1024, 7x7, Sobel-like case.
- CSV result generation.

Limitations:

- No OpenCV dependency is used. The optional real-image demo supports simple grayscale PGM files.
- Official benchmarks use synthetic grayscale images.
- Sharpen and Sobel-like filters are centered 3x3 kernels embedded in larger odd filter sizes to preserve the same filter-size benchmark matrix.
- GTX 1650 Max-Q is the official benchmark GPU, so absolute timings will differ on stronger GPUs.
- 4096x4096 is included in the official benchmark matrix with 5 repeats. Older lower-repeat 4096 stress CSVs are kept only for historical comparison.
- Best block shape is workload-dependent; the summary CSV records winners instead of assuming one block shape is universally optimal.
- GPU total time is a per-run estimate built from fixed allocation/copy/free overhead plus each timed kernel sample; warm-up kernels are excluded.
- Nsight Compute profiling is collected only for representative kernels, not for the full benchmark matrix.
