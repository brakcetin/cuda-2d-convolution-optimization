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
