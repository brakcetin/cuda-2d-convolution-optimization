# 20260523 - Full Expansion Roadmap

## Purpose

This note records the updated decision after the literature review: we have enough time, so the project should grow beyond the minimum CUDA course requirements. The goal is still not to become an unfocused research project. The goal is to build a strong, reproducible performance study that starts from the proposal and then adds increasingly advanced comparisons step by step.

The project remains centered on:

- Correct sequential CPU baseline.
- Correct CUDA direct convolution implementations.
- Memory-hierarchy-aware optimization.
- Clear benchmark methodology.
- Report-ready analysis, tables, plots, and explanations.

## Current Baseline State

As of commit `fcf72b6 Add literature review experiment plan`, the project already has:

- CPU single-threaded 2D convolution baseline.
- Naive CUDA global-memory convolution.
- Shared-memory tiled CUDA convolution.
- Shared-memory plus constant-memory filter convolution.
- CUDA separable convolution for separable filters.
- Correctness verification using CPU output as the reference.
- Benchmark CLI for image sizes, filter sizes, repeats, warmups, and versions.
- GTX 1650 official benchmark results.
- 4096x4096 stress-test results.
- CSV outputs and generated plots.
- Notes, scripts, README, and implementation documentation.

The current project already satisfies the proposal at a solid level. The new work should make it stronger by improving benchmark rigor, widening comparison dimensions, and adding research-inspired advanced variants.

## Interpretation Of The Papers

### Memory-hierarchy paper

The memory-hierarchy article supports measuring more than raw kernel time. It argues that image-processing applications are often constrained by memory movement and locality.

Project action:

- Add detailed GPU time breakdown.
- Report allocation, host-to-device copy, kernel, device-to-host copy, and total time.
- Keep kernel-only and total-time speedups separate.
- Explain when transfer overhead dominates.

### Register-convolution and memory-transaction papers

The register-based convolution and memory-transaction papers focus on reducing communication: fewer global memory transactions, more work per thread, register reuse, warp shuffle, and better coalescing.

Project action:

- Add register-tiled or multi-output-per-thread convolution after the benchmark pipeline is stronger.
- Add a warp-shuffle or row-reuse experiment only after simpler variants are stable.
- Compare this with shared memory to show different ways of reducing redundant memory traffic.

### Perrot optimized GPU convolution paper

The Perrot paper supports more advanced direct-convolution implementations, including register-oriented reuse and computing multiple neighboring outputs per thread.

Project action:

- Add a direct-convolution advanced version that computes multiple adjacent output pixels per thread.
- Treat it as research-inspired, not as the first optimization.
- Compare it mainly against naive/shared/constant direct convolution.

### Adaptive tiling paper

The adaptive tiling paper strongly supports shared memory, constant memory, tile-size sensitivity, loop unrolling, and tuning by filter/image size.

Project action:

- Add block-size comparison.
- Add optional loop-unrolled kernels for fixed filter sizes.
- Generate best-version summaries because the best implementation may change by filter size and image size.

### GpuCV paper

GpuCV supports the idea of framework-style benchmarking, implementation switching, and comparing multiple execution backends.

Project action:

- Add best-version summary tables.
- Optionally add OpenCV image loading and OpenCV CPU comparison.
- If OpenCV CUDA is available later, compare carefully as a library baseline, not as our main implementation.

### cuDNN evaluation paper

The cuDNN paper shows that serious convolution studies compare many algorithms and configurations. It also shows that algorithm choice depends heavily on parameters.

Project action:

- Add cuDNN comparison only after our own kernels are stable.
- Discuss cuDNN as an industrial deep-learning convolution library, not as a replacement for our educational CUDA implementation.
- Consider FFT and Winograd as advanced algorithmic comparisons.

## Alignment With Proposal And Project Goal

The proposal goal is:

```text
Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations
```

The existing implementation already matches this because it compares CPU, naive CUDA, shared memory, constant memory, and separable convolution.

The expanded roadmap improves alignment by adding:

- Stronger timing methodology.
- More filter types used in image processing.
- Block-size and tile-size sensitivity.
- GFLOP/s throughput analysis.
- GPU time breakdown.
- Best-version selection.
- Optional advanced algorithms and library baselines.

This makes the project more than "CPU versus CUDA". It becomes a full performance study, which is exactly what the title and proposal promise.

## Phase 1 - Benchmark Rigor

### Goal

Make the current benchmark results more statistically credible and more report-ready.

### Implementation tasks

1. Add repeated-run statistics:
   - average
   - minimum
   - maximum
   - standard deviation
2. Add GFLOP/s estimates:
   - CPU GFLOP/s
   - CUDA kernel GFLOP/s
3. Add GPU time breakdown:
   - allocation time
   - host-to-device copy time
   - kernel time
   - device-to-host copy time
   - total time
4. Update CSV columns.
5. Update plotting script to handle new fields.
6. Add a best-version summary CSV:
   - best kernel-time version per case
   - best total-time version per case
   - correctness status

### Important scripts

```powershell
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512,1024,2048" -FilterSizes "3,5,7,11" -Repeats 5 -Warmups 1 -Versions "all"
python .\scripts\plot_results.py --input results\timing_results.csv --output-dir results\plots
```

### Acceptance criteria

- All official benchmark rows pass correctness.
- Statistics are written to CSV.
- GFLOP/s columns are present and plausible.
- Total GPU time equals the measured full GPU path, not only kernel time.
- The report can explain why kernel speedup and total speedup differ.

### Suggested commit

```powershell
git add src scripts README.md docs notes results
git commit -m "Add rigorous benchmark statistics"
git push
```

## Phase 2 - Filter Type Experiments

### Goal

Show that performance depends not only on filter size, but also on filter structure.

### Filter types

1. Box filter:
   - normalized
   - separable
   - currently the main filter style
2. Gaussian-like filter:
   - normalized
   - separable
   - good for comparing direct convolution with separable convolution
3. Sharpen filter:
   - non-separable direct filter
   - useful image-processing example
4. Edge/Sobel-like filter:
   - edge-detection style
   - likely 3x3 and non-box
   - may need special handling because classic Sobel is directional

### Implementation tasks

1. Add a `filter_type` CLI option.
2. Generate each filter in `filters.cpp`.
3. Add `filter_type` column to CSV files.
4. Run direct CUDA versions for every filter type.
5. Run separable CUDA only for filters that are mathematically separable.
6. Make the correctness logic clear:
   - direct versions compare against CPU direct convolution
   - separable versions compare against CPU separable reference for separable filters

### Interpretation

This directly addresses the proposal's claim that separable convolution is only valid for suitable filters. It avoids overclaiming that separable convolution is always the best solution.

### Acceptance criteria

- Box and Gaussian-like filters support separable comparison.
- Sharpen and edge/Sobel-like filters are handled by direct convolution variants.
- CSVs clearly record filter type.
- Report explains why filter type changes valid algorithms.

### Suggested commit

```powershell
git add src scripts README.md docs notes results
git commit -m "Add filter type benchmark experiments"
git push
```

## Phase 3 - Block Size And Tile Shape Comparison

### Goal

Measure tile/block sensitivity, motivated by adaptive tiling literature.

### Block sizes

Test:

- `8x8`
- `16x16`
- `32x8`
- `32x16`

The current default `16x16` remains the baseline.

### Implementation tasks

1. Add block width and block height CLI options.
2. Pass block dimensions into CUDA launch wrappers.
3. Ensure dynamic shared memory size uses the selected block shape.
4. Add block width and block height columns to CSV.
5. Add plots for block-size comparison.
6. Add a summary table showing best block shape per version/filter/image case.

### Interpretation

This turns the project into a tuning study. The result may show that no single block size is always best, which aligns with the adaptive tiling paper.

### Acceptance criteria

- All block-size configurations pass correctness.
- Resource-heavy block shapes fail gracefully if they exceed shared memory or thread limits.
- The README documents the default and tested block sizes.

### Suggested commit

```powershell
git add src scripts README.md docs notes results
git commit -m "Add block size benchmark sweep"
git push
```

## Phase 4 - Register Tiling And Multi-Output Direct Convolution

### Goal

Add an advanced direct convolution inspired by the register-convolution and Perrot papers.

### Candidate implementation

Implement a version such as:

```text
cuda_register_tiled
```

Possible design:

- One thread computes two adjacent horizontal output pixels.
- Reuse overlapping input values in registers.
- Keep global memory accesses coalesced.
- Support common filter sizes first, then generalize if clean.

### Why this comes after block-size experiments

Register tiling is easier to interpret after we know the behavior of naive/shared/constant versions under different block shapes.

### Acceptance criteria

- Correctness passes against CPU direct convolution.
- It is compared only against direct convolution variants.
- Report explains that this reduces communication and repeated memory loads, matching the research papers.

### Suggested commit

```powershell
git add src README.md docs notes results
git commit -m "Add register tiled convolution experiment"
git push
```

## Phase 5 - Warp Shuffle Or Row-Reuse Experiment

### Goal

Add a lower-level communication-reduction experiment inspired by memory-transaction optimization work.

### Candidate implementation

Possible names:

```text
cuda_warp_shuffle_row_reuse
cuda_row_reuse
```

Potential design:

- Start with 3x3 or 5x5.
- Use warp-level operations or row reuse to reduce redundant loads.
- Keep this as an experimental version if full generality makes the code too complex.

### Risk

Warp-shuffle convolution is easy to make architecture-specific or hard to read. It should not replace the clean shared-memory explanation. It should be presented as an advanced experiment.

### Acceptance criteria

- Correctness passes for the supported filter sizes.
- Unsupported cases are clearly skipped or documented.
- Report connects it to the memory-transaction paper.

### Suggested commit

```powershell
git add src README.md docs notes results
git commit -m "Add warp level row reuse experiment"
git push
```

## Phase 6 - FFT-Based Convolution

### Goal

Add an algorithmic comparison for large filters or large images.

### Candidate implementation

Use cuFFT if available:

- Pad image and filter.
- Transform both to frequency domain.
- Multiply elementwise.
- Inverse transform.
- Crop output.

### Interpretation

FFT convolution has different tradeoffs:

- It can be useful for large filters.
- It has setup and transform overhead.
- It may not beat direct convolution for small filters such as 3x3 or 5x5.

### Acceptance criteria

- Compare FFT only where mathematically and implementation-wise valid.
- Document boundary handling carefully because zero-padding and circular convolution details matter.
- Do not let FFT complexity destabilize existing direct-convolution results.

### Suggested commit

```powershell
git add src CMakeLists.txt README.md docs notes results
git commit -m "Add FFT convolution comparison"
git push
```

## Phase 7 - Winograd Convolution

### Goal

Add a specialized small-filter algorithmic comparison, most likely for 3x3 filters.

### Candidate implementation

Start narrow:

- 3x3 filters only.
- Small tile transform.
- Compare against direct convolution for 3x3.

### Risk

Winograd is mathematically more complex and can be sensitive to numerical precision. It should be treated as an advanced optional comparison.

### Acceptance criteria

- Correctness tolerance is documented.
- Only supported configurations are benchmarked.
- Report explains that Winograd is specialized, not a universal replacement.

### Suggested commit

```powershell
git add src README.md docs notes results
git commit -m "Add Winograd convolution comparison"
git push
```

## Phase 8 - cuDNN Baseline

### Goal

Compare our educational CUDA kernels with a highly optimized industrial library.

### Candidate implementation

- Add optional CMake detection for cuDNN.
- Add a `cuda_cudnn` or `cudnn_convolution` version if cuDNN is installed.
- Keep it optional so the repo still builds without cuDNN.

### Interpretation

cuDNN is not a fair "student kernel versus student kernel" comparison. It is useful as an external reference point showing how far industrial libraries go.

### Acceptance criteria

- Build does not fail when cuDNN is missing.
- README clearly marks cuDNN as optional.
- Report uses cuDNN to contextualize, not to replace our CUDA implementation.

### Suggested commit

```powershell
git add src CMakeLists.txt README.md docs notes results
git commit -m "Add optional cuDNN benchmark baseline"
git push
```

## Phase 9 - OpenCV And GpuCV-Style Comparison

### Goal

Add real-image workflow and optional framework-style comparison.

### Candidate implementation

1. Add optional OpenCV image loading.
2. Convert input images to grayscale float.
3. Run existing kernels on real images.
4. Optionally compare with OpenCV CPU `filter2D`.
5. If OpenCV CUDA modules are available, compare as optional library backend.

### Interpretation

This connects the synthetic benchmark to practical image processing. It also reflects the GpuCV paper's framework-style view.

### Acceptance criteria

- Synthetic benchmark remains the official reproducible benchmark.
- Real-image runs are additional demos.
- OpenCV is optional and documented.

### Suggested commit

```powershell
git add src CMakeLists.txt README.md docs notes results
git commit -m "Add optional OpenCV image benchmark path"
git push
```

## Phase 10 - RGB Image Support

### Goal

Extend from grayscale images to color images.

### Candidate implementation

- Store RGB as interleaved or planar floats.
- Prefer planar layout for easier coalescing and per-channel convolution.
- Run convolution independently per channel.
- Add correctness comparison against CPU RGB implementation.

### Interpretation

RGB support is practical, but it is not required for the core proposal. It should be added after benchmark rigor and filter comparisons are complete.

### Acceptance criteria

- Grayscale path remains unchanged and stable.
- RGB benchmark is clearly labeled.
- Report explains the extra memory bandwidth and 3-channel workload.

### Suggested commit

```powershell
git add src README.md docs notes results
git commit -m "Add RGB convolution support"
git push
```

## Phase 11 - Multi-GPU Or Multi-Hardware Study

### Goal

Use available hardware effectively without overpromising.

### Preferred approach

Because the user has GTX 1650 and the teammate has RTX 4070, the strongest and safest comparison is:

```text
multi-hardware benchmark comparison
```

Run the same official benchmark matrix on:

- GTX 1650
- RTX 4070

Then compare:

- kernel time
- total time
- speedup
- best version per GPU

### Optional true multi-GPU approach

True multi-GPU convolution should only be attempted if one machine has multiple CUDA GPUs. Otherwise, it becomes artificial.

### Acceptance criteria

- Same code and same benchmark command are used on both GPUs.
- Device name is recorded in CSV.
- Report explains architecture differences qualitatively.

### Suggested commit

```powershell
git add results README.md docs notes
git commit -m "Add multi hardware benchmark comparison"
git push
```

## Chronological Execution Order

Recommended order:

1. Benchmark rigor and statistics.
2. Filter type experiments.
3. Block-size sweep.
4. Best-version summary and plot expansion.
5. Register-tiled direct convolution.
6. Warp-shuffle or row-reuse experiment.
7. FFT convolution.
8. Winograd convolution.
9. Optional cuDNN baseline.
10. Optional OpenCV real-image path.
11. RGB support.
12. GTX 1650 versus RTX 4070 multi-hardware comparison.
13. Final README, report notes, and presentation material.

The first three phases are the most important because they directly strengthen the proposal's performance-study promise. The later phases are impressive but should be isolated so the existing project never breaks.

## Final Experiment Matrix After Expansion

Core matrix:

- Image sizes: `512,1024,2048,4096`
- Filter sizes: `3,5,7,11`
- Filter types: `box,gaussian,sharpen,sobel`
- Repeats: `5` or more
- Warmups: `1` or more
- Block sizes: `8x8,16x16,32x8,32x16`

Versions:

- `cpu`
- `cuda_naive_global_memory`
- `cuda_shared_memory_tiled`
- `cuda_shared_constant_filter`
- `cuda_separable`
- `cuda_register_tiled`
- `cuda_warp_or_row_reuse`
- `cuda_fft`
- `cuda_winograd`
- optional `cudnn`
- optional `opencv_cpu`
- optional `opencv_cuda`

The final report should not show every raw row in the main body. It should use summary tables and selected plots, then keep full CSV files in `results/`.

## Report Interpretation Plan

The report should answer these questions:

1. Does CUDA beat the single-threaded CPU baseline?
2. How much of the speedup survives after memory transfer overhead?
3. Does shared memory improve direct convolution?
4. Does constant memory improve filter access?
5. When does separable convolution dominate?
6. Does block size change the best CUDA configuration?
7. Do different filter types change the best algorithm?
8. Do register/warp-level optimizations help beyond shared memory?
9. Are FFT or Winograd useful for this project workload?
10. How different are GTX 1650 and RTX 4070 results?

## Risk Controls

- Keep each new version behind a selectable benchmark version name.
- Never remove the existing working CPU/CUDA versions.
- Commit after each milestone.
- Push after each milestone.
- If an advanced implementation is unstable, document it as experimental and exclude it from official correctness-passing results.
- Keep CSV schema version changes documented in notes and README.
- Keep synthetic benchmark as the official reproducible path even if OpenCV image loading is added.

## What Future Me Should Do First

Start with Phase 1:

```powershell
git status --short
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
.\scripts\run_benchmarks.ps1 -ImageSizes "512" -FilterSizes "3" -Repeats 1 -Warmups 1 -Versions "all"
```

Then modify the benchmark data structures to store all repeat timings instead of only averages. Once the repeat timings are stored, computing min, max, standard deviation, and GFLOP/s is straightforward.

## Current Decision

We will add all requested experiments step by step, but we will preserve the existing stable project as the baseline. The next concrete milestone is benchmark rigor because it benefits every later experiment and directly improves the final report.
