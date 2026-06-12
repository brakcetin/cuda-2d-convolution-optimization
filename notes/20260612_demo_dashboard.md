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
