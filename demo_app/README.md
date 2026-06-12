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
building.png  -> sobel, 3x3, cuda_shared_constant_filter, 16x16
portrait.jpg  -> gaussian, 11x11, cuda_separable, 32x8
portrait.jpg  -> sharpen, 3x3, cuda_shared_constant_filter, 16x16
texture.png   -> sobel, 3x3, cuda_shared_constant_filter, 16x16
```

The live demo runs the executable like this:

```powershell
convolution_benchmark.exe --demo-input input.pgm --demo-output output.pgm --demo-filter-type sobel --demo-filter-size 3 --demo-version cuda_shared_constant_filter --demo-block-size 16x16 --demo-normalize-output true
```

`cuda_separable` is valid only for `box` and `gaussian` filters.

Images larger than 2048 pixels on their longest side are resized for presentation stability.

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
