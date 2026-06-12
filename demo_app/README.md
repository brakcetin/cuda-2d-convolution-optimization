# CUDA Convolution Demo Dashboard

This local web app provides a presentation-safe dashboard and a live image convolution demo for the CUDA 2D convolution project.

## Modes

- **Dashboard Mode:** shows committed GTX 1650 and RTX 4070 benchmark summaries, correctness status, comparison tables, and plots.
- **Live Image Demo Mode:** accepts a PNG, JPG, JPEG, or PGM image, converts it to grayscale PGM, runs the CUDA executable, and displays the filtered output plus timing/correctness metrics.

The dashboard is the safe presentation fallback. The live demo depends on the CUDA executable and local GPU runtime.

## Setup

Run from the repository root in Windows PowerShell:

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

Open:

```text
http://127.0.0.1:5000
```

The shorter form, if the repository is already pulled and built, is:

```powershell
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
python -m pip install -r demo_app\requirements.txt
.\scripts\run_demo_dashboard.ps1
```

Manual form:

```powershell
.\scripts\configure_release.ps1
.\scripts\build_release.ps1
cd demo_app
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python server.py
```

Manual Flask form:

```powershell
cd C:\Users\Burak\Burak\Projects\cuda-2d-convolution-optimization
python -m pip install -r demo_app\requirements.txt
cd demo_app
python server.py
```

Then open:

```text
http://127.0.0.1:5000
```

If port `5000` is already busy:

```powershell
.\scripts\run_demo_dashboard.ps1 -Port 5001
```

Then open:

```text
http://127.0.0.1:5001
```

## Optional Executable Path

By default the backend looks for:

```text
build\Release\convolution_benchmark.exe
build\convolution_benchmark.exe
```

To override:

```powershell
$env:CONVOLUTION_EXE_PATH="C:\path\to\convolution_benchmark.exe"
python server.py
```

## Live Demo Notes

Recommended presentation cases:

```text
data\real_images\building.png  -> sobel, 3x3, cuda_shared_constant_filter, 16x16
data\real_images\portrait.jpg  -> gaussian, 11x11, cuda_separable, 32x8
data\real_images\portrait.jpg  -> sharpen, 3x3, cuda_shared_constant_filter, 16x16
data\real_images\texture.png   -> sobel, 3x3, cuda_shared_constant_filter, 16x16
```

Expected visual meaning:

- **Sobel / building:** the output should emphasize building edges and facade texture. Flat sky or wall regions may become gray and less recognizable because Sobel highlights intensity changes, not full image brightness.
- **Gaussian / portrait:** the output should look like a blurred portrait. This is expected because Gaussian convolution smooths high-frequency detail.
- **Sharpen / portrait:** the output should increase local contrast. With normalized demo output it can look darker or different from the original, but the facial structure should remain visible.
- **Sobel / texture:** the output should look relief-like because strong wood-grain transitions become edge structures.

The output image is not expected to be identical to the input image. Correctness is judged numerically against the CPU reference using max/mean absolute error; the visual output shows what the selected filter does.

The UI hides incompatible CUDA choices. In this project, `cuda_separable` is only shown for `box` and `gaussian` because Sobel and sharpen are treated as direct 2D filters.

Control meanings:

- **Filter:** selects the convolution kernel. Box and Gaussian blur smooth the image, Sobel extracts edges, and sharpen increases local contrast.
- **Filter size:** selects the neighborhood width and height. Small filters such as `3x3` do less work and have a weaker spatial effect; larger filters such as `11x11` inspect more neighboring pixels, increase arithmetic work, and make blur/context effects stronger.
- **CUDA version:** selects the kernel implementation. Naive is the basic global-memory kernel, shared memory reuses input tiles, shared + constant also caches filter coefficients, and separable uses two cheaper 1D passes when mathematically valid.
- **Block size:** selects CUDA thread-block shape. There is no universal winner; `16x16` is the safe default, `32x8` is often good for row-major access, and `32x16` can help some direct kernels but depends on occupancy, memory access, and workload.

Metric meanings:

- **CPU time:** single-threaded CPU reference time.
- **Kernel time:** CUDA computation time only.
- **Total GPU time:** allocation, host-to-device copy, kernel, device-to-host copy, and free time.
- **Speedup:** CPU time divided by CUDA time. Kernel speedup can be high while total GPU time is worse for small images because GPU setup and transfer overhead dominate.

The live demo runs the executable like this:

```powershell
convolution_benchmark.exe --demo-input input.pgm --demo-output output.pgm --demo-filter-type sobel --demo-filter-size 3 --demo-version cuda_shared_constant_filter --demo-block-size 16x16 --demo-normalize-output true
```

`cuda_separable` is valid only for `box` and `gaussian` filters.

Images larger than 2048 pixels on their longest side are resized for presentation stability.

Committed real-image PGM inputs are prepared with aspect ratio preserved and longest side limited to 1024 pixels. They are not forced into a square, so portraits and building photos should not look horizontally or vertically squeezed.

The first live CUDA subprocess can include CUDA context initialization cost in total GPU time. For presentation, emphasize kernel time and correctness first, then explain that total time includes setup and transfer overhead.

## Benchmark Interpretation

Uploaded image dimensions determine most of the convolution workload. Timing depends mainly on image size, filter size, CUDA version, block size, GPU model, and CPU/GPU transfer overhead; not on the semantic content of the image.

Official performance claims should still come from the committed synthetic benchmark CSV files. The live demo is for visual and interactive presentation evidence.

## Troubleshooting

- **Flask or Pillow missing:** run `pip install -r requirements.txt`.
- **CUDA executable not found:** run `scripts/configure_release.ps1` and `scripts/build_release.ps1`.
- **Live demo fails:** use Dashboard Mode and fallback sample outputs; the committed benchmark evidence remains available.
- **Separable error:** choose `box` or `gaussian` when using `cuda_separable`.
- **Virtual environment has no pip:** return to the repository root and run `python -m pip install -r demo_app\requirements.txt`.
- **Port 5000 is busy:** run `scripts/run_demo_dashboard.ps1 -Port 5001`.
- **Chrome shows `ERR_NO_BUFFER_SPACE` for `app.js`:** stop the Flask server with `Ctrl+C`, close extra browser tabs, restart on another port with `scripts/run_demo_dashboard.ps1 -Port 5001`, and open `http://127.0.0.1:5001`. If needed, use Edge or an incognito Chrome window.
