# 20260612 - Demo Dashboard And Live Image App

## Purpose

This note records the implementation plan and code milestone for the presentation demo dashboard.

The goal is to support the CENG-479 final presentation with:

- a safe dashboard mode using committed GTX 1650 and RTX 4070 benchmark results
- a live image demo mode that runs the CUDA executable on an uploaded real image

## Files Added

```text
demo_app\server.py
demo_app\requirements.txt
demo_app\README.md
demo_app\static\index.html
demo_app\static\styles.css
demo_app\static\app.js
```

Runtime folders:

```text
demo_app\uploads\
demo_app\outputs\
demo_app\sample_results\fallback_images\
```

## C++ Demo Output Update

`src\main.cu` demo mode was extended to print:

- CPU time ms
- GPU kernel time ms
- GPU total time ms
- kernel speedup
- total speedup
- block size
- correctness metrics

This lets the Flask backend parse real executable output instead of fabricating UI metrics.

## Run Commands

From the repository root:

```powershell
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
cd demo_app
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python server.py
```

Open:

```text
http://127.0.0.1:5000
```

## Interpretation

The demo dashboard does not replace the official benchmark. Official performance claims still come from the synthetic CSV matrix.

The live demo is useful because it proves the executable can run on a real uploaded image. The key explanation for the presentation is:

```text
Uploaded image dimensions determine most of the convolution workload. Timing depends mainly on image size, filter size, CUDA version, block size, GPU model, and CPU/GPU transfer overhead; not on the semantic content of the image.
```

## Presentation Fallback

If the live CUDA demo fails, Dashboard Mode and committed fallback images remain available. This protects the presentation from environment issues.

## README Run Instructions Update

After the demo dashboard was implemented, the main README and `demo_app\README.md` were updated with a teammate-facing setup flow. The goal was to make the presentation demo reproducible after a fresh GitHub pull.

Chronological run sequence from the repository root:

```powershell
cd C:\Users\Burak\Burak\Projects\cuda-2d-convolution-optimization
git pull
git status --short
.\scripts\check_environment.ps1
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
python -m pip install -r demo_app\requirements.txt
.\scripts\run_demo_dashboard.ps1
```

Browser URL:

```text
http://127.0.0.1:5000
```

If port `5000` is busy:

```powershell
.\scripts\run_demo_dashboard.ps1 -Port 5001
```

Then open:

```text
http://127.0.0.1:5001
```

Recommended live demo cases:

```text
building.png  -> sobel, 3x3, cuda_shared_constant_filter, 16x16
portrait.jpg  -> gaussian, 11x11, cuda_separable, 32x8
portrait.jpg  -> sharpen, 3x3, cuda_shared_constant_filter, 16x16
texture.png   -> sobel, 3x3, cuda_shared_constant_filter, 16x16
```

Interpretation for the presentation:

- Dashboard Mode is the safe fallback because it reads committed CSV and plot files.
- Live Image Demo Mode proves that the built CUDA executable can run on a real uploaded image.
- The performance score should be explained as a function of image dimensions, filter size, CUDA version, block size, GPU model, and transfer overhead. The semantic content of the image changes the visual output, not the convolution workload size.

Troubleshooting notes:

- If Flask or Pillow is missing, run `python -m pip install -r demo_app\requirements.txt`.
- If the CUDA executable is missing, rerun the configure and build scripts.
- If a virtual environment is created but `pip` is unavailable, use the system Python command from the repository root.
- `cuda_separable` is only valid for `box` and `gaussian` filters.

## Browser Error Follow-Up

During a local run, Chrome reported:

```text
app.js:1 Failed to load resource: net::ERR_NO_BUFFER_SPACE
favicon.ico 404
```

The Flask log still showed successful `200` responses for `/`, `/styles.css`, `/app.js`, `/api/summary`, `/api/plots`, and `/api/sample-demo`, so the dashboard server itself was working. The `favicon.ico` request was harmless but noisy, so a `/favicon.ico` route was added to return HTTP `204` instead of `404`.

If `ERR_NO_BUFFER_SPACE` appears again, use this recovery sequence:

```powershell
Ctrl+C
.\scripts\run_demo_dashboard.ps1 -Port 5001
```

Then open:

```text
http://127.0.0.1:5001
```

If Chrome still shows the same network-buffer error, close extra Chrome tabs or use Edge/incognito mode. This error is normally browser/Windows local networking state, not a CUDA or Flask application failure.

## Dashboard Label And Live Demo Interpretation Update

The dashboard was refined after reviewing screenshots from the running UI:

- Direct Kernel Comparison now shows GTX 1650 and RTX 4070 side by side for the same case: `4096x4096`, `11x11`, Sobel-like, `32x16`.
- Summary cards now write the full GPU names: `GTX 1650 best kernel`, `GTX 1650 best total`, `RTX 4070 best kernel`, and `RTX 4070 best total`.
- Live Demo Mode now includes an explanation panel describing which file to upload, what output is expected, and why filtered images can look different from the original.

Important interpretation:

- Sobel output is not expected to look like the original photo. It emphasizes intensity changes and edges, so flat regions can disappear or become gray.
- Gaussian output is expected to be blurred.
- Sharpen output is expected to increase local contrast and may look darker after demo normalization.
- Texture Sobel output can look like a relief map because it highlights grain transitions.
- Numerical correctness still comes from CPU-vs-CUDA max/mean absolute error, not from whether the filtered image looks visually identical to the input.

Recommended live demo file paths:

```text
data\real_images\building.png
data\real_images\portrait.jpg
data\real_images\texture.png
```

## Control Compatibility And Explanation Update

The Live Demo UI was updated so incompatible choices do not appear to the user:

- `cuda_separable` is hidden and disabled when the selected filter is `sobel` or `sharpen`.
- `cuda_separable` remains available for `box` and `gaussian`.

This matches the implementation and the project methodology: separable convolution is only used when the filter is intentionally separable. Sobel and sharpen are benchmarked as direct 2D convolution filters.

New UI explanation panels were added:

- filter meaning
- filter-size meaning
- CUDA version meaning
- block-size meaning
- CPU time vs kernel time vs total GPU time

Important metric interpretation:

- `CPU time` is a single-threaded CPU reference.
- `Kernel time` is only CUDA computation after data is already on the GPU.
- `Total GPU time` includes allocation, host-to-device copy, kernel, device-to-host copy, and free time.
- For small images such as `256x256`, CPU time can be lower than total GPU time because GPU overhead is larger than the actual computation. This does not mean the GPU kernel is slow; the kernel time can still be much faster.

Dashboard plot update:

- GTX 1650 and RTX 4070 plots are now paired side by side when the same plot exists for both GPUs.
- The existing `gpu_comparison_kernel_time.png` is shown as a combined hardware-comparison plot.
- Raw kernel time is the most meaningful hardware comparison. Speedup values depend on each machine's CPU baseline, so GTX-vs-RTX speedup should be interpreted carefully.

## Aspect Ratio And Shared Plot Scale Update

The real-image preparation workflow was fixed because the previous ImageMagick command forced every image into `1024x1024`, which squeezed non-square images. The new command preserves aspect ratio and limits only the longest side to 1024 pixels:

```powershell
magick "data\real_images\portrait.jpg" -colorspace Gray -resize 1024x1024 "data\real_images\portrait_1024.pgm"
```

Updated prepared dimensions:

```text
building_1024.pgm: 1024x808
portrait_1024.pgm: 1024x683
texture_1024.pgm: 768x1024
```

The committed demo outputs were regenerated from these aspect-ratio-preserving inputs:

```text
building_sobel.pgm: 1024x808
portrait_gaussian.pgm: 1024x683
portrait_sharpen.pgm: 1024x683
texture_sobel.pgm: 768x1024
```

The benchmark plot generator was also updated with `--compare-input`. When GTX and RTX plots are generated as a pair, both images now use the same y-axis maximum computed from both CSV files. This makes side-by-side plot comparison fairer because the visual scale is no longer independently stretched per GPU.

Regeneration commands:

```powershell
python .\scripts\plot_results.py --input results\timing_results.csv --compare-input results\timing_results_rtx4070.csv --output-dir results\plots
python .\scripts\plot_results.py --input results\timing_results_rtx4070.csv --compare-input results\timing_results.csv --output-dir results\plots_rtx4070
python .\scripts\plot_real_image_panel.py --output results\plots\real_image_demo_panel.png
```

## Separable Filter Plot Fix And Loading Improvement

The speedup-by-filter-type plot previously showed `cuda_separable` dropping to zero for `sharpen` and `sobel`. This was not a CUDA correctness error. The benchmark intentionally skips separable convolution for sharpen and Sobel because those filters are treated as direct 2D filters in this project.

The issue was in plotting: missing points were drawn as `0.0`. The plot script now uses `NaN` for missing/applicability gaps, so the line stops instead of falsely dropping to zero.

Interpretation for presentation:

- A missing `cuda_separable` point for Sobel or sharpen means "not applicable".
- It does not mean the GPU kernel failed or that speedup is zero.
- Correctness remains validated by the CSV pass/fail rows and CPU-vs-CUDA error metrics.

Dashboard loading was also improved:

- fallback real-image previews are regenerated only if the source image/output changed
- `/api/sample-demo` is loaded only when Live Image Demo Mode is opened
- Dashboard Mode loads benchmark summaries and plots first

## Real-Image Sample Timing Cards

The fallback real-image sample cards were updated to show the timing context for each committed demo output:

```text
Building Sobel: CPU 14.4491 ms, GPU kernel 0.212896 ms, GPU total 1457.27 ms, kernel speedup 67.8693x
Portrait Gaussian: CPU 21.3990 ms, GPU kernel 0.288352 ms, GPU total 1853.0 ms, kernel speedup 74.2114x
Portrait Sharpen: CPU 14.5537 ms, GPU kernel 0.164608 ms, GPU total 1943.04 ms, kernel speedup 88.4143x
Texture Sobel: CPU 12.2333 ms, GPU kernel 0.210944 ms, GPU total 1351.14 ms, kernel speedup 57.9931x
```

These are local presentation-demo timings, not official benchmark claims. The total GPU time is high because each demo is launched as a separate process and can include CUDA context/startup overhead. The cleaner compute comparison is the CUDA kernel time.

## Separable Sobel And Sharpen Clarification

The wording was clarified:

- Box and Gaussian are separable in the implemented benchmark path because each 2D filter is generated as an outer product of one 1D vector.
- Sobel can be implemented separably in theory, for example as a smoothing vector times a derivative vector, but that requires a Sobel-specific two-vector separable path. This project deliberately keeps Sobel in the direct-convolution group to compare naive/shared/shared+constant/register/multi-output kernels.
- The canonical sharpen kernel used here is not a single rank-1 separable filter, so it is treated as direct convolution.
- Therefore missing `cuda_separable` points for Sobel/sharpen mean "not included in this implementation path", not "GPU failed".

## CPU Reference In Live Demo

The live demo wording was updated because the UI looked like it only ran on the GPU. In reality, every live demo run already does both:

1. Run the single-threaded CPU reference convolution.
2. Run the selected CUDA version.
3. Compare CUDA output against CPU output.
4. Report CPU time, CUDA kernel time, total GPU time, speedup, and correctness.

The button now says `Run CPU + CUDA Demo`, and the panel title explains that the CPU reference runs first. A separate CPU-only dropdown is not needed for the presentation because CPU is already used as the correctness oracle and timing baseline in every live demo run.

## Benchmark-Parity Measurement In The Live Demo

The live demo previously measured differently from the official benchmark: the CPU reference ran once, the CUDA kernel ran with 1 warmup but only 1 timed repeat, and for `cuda_separable` the CPU baseline was a single separable CPU run. The demo now follows `run_benchmarks` exactly:

1. CPU reference: 5 timed repeats of the direct 2D convolution via the same `run_cpu_repeats` function the benchmark uses (now exposed in `benchmark.h`). The reported `CPU time ms` is the average; min/max/stddev are printed too.
2. CUDA: 1 untimed warmup launch followed by 5 timed launches measured with CUDA events, exactly as in the benchmark wrappers. `GPU kernel time ms` and `GPU total time ms` are averages with min/max/stddev printed alongside.
3. Speedups: average CPU time divided by average kernel/total time, the same formula as `results/timing_results*.csv`.
4. `cuda_separable`: correctness is compared against the separable CPU output (computed once, untimed) while the speedup baseline stays the direct 2D CPU average, matching how the benchmark produced the official separable speedups.
5. The CPU-only demo version (`--demo-version cpu`, CLI only) also runs 5 timed repeats of the direct 2D convolution now, so its number matches the CPU baseline used in CUDA rows.

New demo CLI flags `--demo-warmups` (default 1) and `--demo-repeats` (default 5) control the counts; `demo_app/server.py` passes `--demo-warmups 1 --demo-repeats 5` explicitly and its subprocess timeout was raised from 60 to 180 seconds because the CPU reference now runs five times. The stdout block additionally reports `Device`, `Warmup runs`, `Timed repeats`, and the min/max/stddev lines; the server parses all of them and the live UI shows averages with min and stddev next to the CPU and kernel cards.

Because the live demo now reports 5-repeat averages, the recorded fallback sample timings (single-run measurements from the GTX 1650 machine) are labeled as indicative single-run values in the UI. The committed PGM outputs are unaffected: repeated kernel launches write the same deterministic result, which was re-verified after the change (`Passed: true`, max abs error 0 for Sobel cases and ~3.6e-7 for separable Gaussian).

The only intended difference between the live demo and the benchmark remains: the image comes from the upload, and filter type, filter size, CUDA version, and block size come from the form controls.
