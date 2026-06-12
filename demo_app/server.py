import csv
import os
import re
import subprocess
import time
from pathlib import Path
from uuid import uuid4

try:
    from flask import Flask, Response, jsonify, request, send_file, send_from_directory
except ImportError as error:
    raise SystemExit(
        "Flask is not installed. Run: python -m pip install -r demo_app/requirements.txt"
    ) from error

try:
    from PIL import Image
except ImportError as error:
    raise SystemExit(
        "Pillow is not installed. Run: python -m pip install -r demo_app/requirements.txt"
    ) from error


REPO_ROOT = Path(__file__).resolve().parents[1]
DEMO_ROOT = Path(__file__).resolve().parent
UPLOAD_DIR = DEMO_ROOT / "uploads"
OUTPUT_DIR = DEMO_ROOT / "outputs"
FALLBACK_DIR = DEMO_ROOT / "sample_results" / "fallback_images"

ALLOWED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".pgm"}
FILTER_TYPES = {"box", "gaussian", "sharpen", "sobel"}
FILTER_SIZES = {"3", "5", "7", "11"}
CUDA_VERSIONS = {
    "cuda_naive_global_memory",
    "cuda_shared_memory_tiled",
    "cuda_shared_constant_filter",
    "cuda_separable",
}
BLOCK_SIZES = {"8x8", "16x16", "32x8", "32x16"}

app = Flask(__name__, static_folder=str(DEMO_ROOT / "static"), static_url_path="")


def ensure_directories():
    for directory in (UPLOAD_DIR, OUTPUT_DIR, FALLBACK_DIR):
        directory.mkdir(parents=True, exist_ok=True)


def repo_path(*parts):
    return REPO_ROOT.joinpath(*parts)


def find_executable():
    configured = os.environ.get("CONVOLUTION_EXE_PATH")
    candidates = []
    if configured:
        candidates.append(Path(configured))
    candidates.extend([
        repo_path("build", "Release", "convolution_benchmark.exe"),
        repo_path("build", "convolution_benchmark.exe"),
    ])
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def read_csv(path):
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def as_float(row, key):
    try:
        return float(row.get(key, "0") or "0")
    except ValueError:
        return 0.0


def best_by(rows, key):
    if not rows:
        return None
    return max(rows, key=lambda row: as_float(row, key))


def summarize_gpu(label, timing_path, summary_path):
    rows = read_csv(timing_path)
    summary_rows = read_csv(summary_path)
    failed = [row for row in rows if row.get("passed") != "true"]
    best_kernel = best_by(summary_rows, "best_kernel_speedup")
    best_total = best_by(summary_rows, "best_total_speedup")
    direct_versions = {
        "cuda_naive_global_memory",
        "cuda_shared_memory_tiled",
        "cuda_shared_constant_filter",
        "cuda_multi_output",
        "cuda_register_tiled",
    }
    best_direct = best_by(
        [row for row in rows if row.get("version") in direct_versions],
        "kernel_speedup",
    )
    device_name = rows[0].get("device_name", label) if rows else label
    return {
        "label": label,
        "device_name": device_name,
        "timing_rows": len(rows),
        "failed_rows": len(failed),
        "summary_rows": len(summary_rows),
        "best_kernel": best_kernel,
        "best_total": best_total,
        "best_direct": best_direct,
    }


def version_comparison_rows(timing_path):
    rows = read_csv(timing_path)
    selected = [
        row for row in rows
        if row.get("image_width") == "4096"
        and row.get("filter_size") == "11"
        and row.get("filter_type") == "sobel"
        and row.get("block_width") == "32"
        and row.get("block_height") == "16"
        and row.get("version") in {
            "cuda_naive_global_memory",
            "cuda_shared_memory_tiled",
            "cuda_shared_constant_filter",
            "cuda_multi_output",
            "cuda_register_tiled",
        }
    ]
    return sorted(selected, key=lambda row: row.get("version", ""))


def direct_comparison(label, timing_path):
    rows = version_comparison_rows(timing_path)
    device_name = rows[0].get("device_name", label) if rows else label
    return {
        "label": label,
        "device_name": device_name,
        "case": "4096x4096, 11x11 Sobel-like, 32x16 block",
        "rows": rows,
    }


def plot_entries():
    grouped = {}
    combined = []
    for label, folder in (("GTX 1650", "plots"), ("RTX 4070", "plots_rtx4070")):
        path = repo_path("results", folder)
        if not path.exists():
            continue
        for image in sorted(path.glob("*.png")):
            entry = {
                "filename": image.name,
                "gpu": label,
                "title": image.stem.replace("_", " ").title(),
                "url": f"/repo/results/{folder}/{image.name}",
            }
            if image.name.startswith("gpu_comparison_"):
                combined.append(entry)
                continue
            grouped.setdefault(image.name, {
                "filename": image.name,
                "title": image.stem.replace("_", " ").title(),
                "gtx": None,
                "rtx": None,
            })
            key = "gtx" if label.startswith("GTX") else "rtx"
            grouped[image.name][key] = entry
    return {
        "combined": combined,
        "paired": [value for _, value in sorted(grouped.items())],
    }


def save_pgm_l(image, path):
    image = image.convert("L")
    with path.open("wb") as handle:
        handle.write(f"P5\n{image.width} {image.height}\n255\n".encode("ascii"))
        handle.write(image.tobytes())


def image_to_png(source_path, destination_path):
    image = Image.open(source_path).convert("L")
    image.save(destination_path, format="PNG")
    return image.width, image.height


def prepare_upload(file_storage):
    extension = Path(file_storage.filename or "").suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise ValueError("Please upload PNG, JPG, JPEG, or PGM.")

    run_id = f"{int(time.time())}_{uuid4().hex[:8]}"
    upload_original = UPLOAD_DIR / f"{run_id}{extension}"
    file_storage.save(upload_original)

    original = Image.open(upload_original)
    if original.mode not in ("L", "RGB", "RGBA"):
        original = original.convert("RGB")
    image = original.convert("L")
    resized = False

    preview_path = OUTPUT_DIR / f"{run_id}_original.png"
    input_pgm_path = UPLOAD_DIR / f"{run_id}_input.pgm"
    original.save(preview_path, format="PNG")
    save_pgm_l(image, input_pgm_path)
    return run_id, image.width, image.height, resized, preview_path, input_pgm_path


def parse_demo_stdout(stdout):
    metrics = {}
    for line in stdout.splitlines():
        if line.startswith("Demo output written to"):
            metrics["output_message"] = line.strip()
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip().lower().replace("-", " ").replace(" ", "_")
        metrics[key] = value.strip()

    image_match = re.match(r"(\d+)x(\d+)", metrics.get("image", ""))
    if image_match:
        metrics["width"] = int(image_match.group(1))
        metrics["height"] = int(image_match.group(2))

    for key in (
        "cpu_time_ms",
        "gpu_kernel_time_ms",
        "gpu_total_time_ms",
        "kernel_speedup",
        "total_speedup",
        "gpu_allocation_time_ms",
        "gpu_host_to_device_time_ms",
        "gpu_device_to_host_time_ms",
        "gpu_free_time_ms",
        "kernel_time_ms",
        "max_abs_error",
        "mean_abs_error",
    ):
        if key in metrics:
            try:
                metrics[key] = float(metrics[key])
            except ValueError:
                pass
    if "passed" in metrics:
        metrics["passed"] = metrics["passed"].lower() == "true"
    return metrics


def run_cuda_demo(input_pgm, output_pgm, filter_type, filter_size, version, block_size,
                  normalize_output="true", warmups=1, repeats=5):
    executable = find_executable()
    if executable is None:
        raise FileNotFoundError(
            "CUDA executable not found. Run scripts/configure_release.ps1 and scripts/build_release.ps1 first."
        )

    command = [
        str(executable),
        "--demo-input", str(input_pgm),
        "--demo-output", str(output_pgm),
        "--demo-filter-type", filter_type,
        "--demo-filter-size", str(filter_size),
        "--demo-version", version,
        "--demo-block-size", block_size,
        "--demo-normalize-output", normalize_output,
        "--demo-warmups", str(warmups),
        "--demo-repeats", str(repeats),
    ]
    completed = subprocess.run(
        command,
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        timeout=300,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError((completed.stderr or completed.stdout or "CUDA demo failed.").strip())
    return command, completed.stdout


def ensure_fallback_previews():
    def refresh_preview(source, destination):
        if not source.exists():
            return
        if destination.exists() and destination.stat().st_mtime >= source.stat().st_mtime:
            return
        image = Image.open(source)
        if image.mode not in ("L", "RGB", "RGBA"):
            image = image.convert("RGB")
        image.save(destination, format="PNG")

    pairs = [
        (
            "building",
            repo_path("data", "real_images", "building.png"),
            repo_path("results", "building_sobel.pgm"),
            {
                "dimensions": "1024x808",
                "filter": "sobel 3x3",
                "version": "cuda_shared_constant_filter",
                "cpu_time_ms": 13.3066,
                "gpu_kernel_time_ms": 0.194534,
                "gpu_total_time_ms": 6.49893,
                "kernel_speedup": 68.4023,
                "passed": True,
            },
        ),
        (
            "portrait_gaussian",
            repo_path("data", "real_images", "portrait.jpg"),
            repo_path("results", "portrait_gaussian.pgm"),
            {
                "dimensions": "1024x683",
                "filter": "gaussian 11x11",
                "version": "cuda_separable",
                "cpu_time_ms": 20.8574,
                "gpu_kernel_time_ms": 0.297184,
                "gpu_total_time_ms": 4.42648,
                "kernel_speedup": 70.1835,
                "passed": True,
            },
        ),
        (
            "portrait_sharpen",
            repo_path("data", "real_images", "portrait.jpg"),
            repo_path("results", "portrait_sharpen.pgm"),
            {
                "dimensions": "1024x683",
                "filter": "sharpen 3x3",
                "version": "cuda_shared_constant_filter",
                "cpu_time_ms": 11.9257,
                "gpu_kernel_time_ms": 0.172109,
                "gpu_total_time_ms": 6.30681,
                "kernel_speedup": 69.2916,
                "passed": True,
            },
        ),
        (
            "texture",
            repo_path("data", "real_images", "texture.png"),
            repo_path("results", "texture_sobel.pgm"),
            {
                "dimensions": "768x1024",
                "filter": "sobel 3x3",
                "version": "cuda_shared_constant_filter",
                "cpu_time_ms": 16.5221,
                "gpu_kernel_time_ms": 0.185235,
                "gpu_total_time_ms": 4.40544,
                "kernel_speedup": 89.1952,
                "passed": True,
            },
        ),
    ]
    items = []
    for name, original, output, metrics in pairs:
        original_png = FALLBACK_DIR / f"{name}_original.png"
        output_png = FALLBACK_DIR / f"{name}_output.png"
        refresh_preview(original, original_png)
        refresh_preview(output, output_png)
        if original_png.exists() and output_png.exists():
            items.append({
                "name": name.replace("_", " ").title(),
                "original_url": f"/generated/{original_png.name}",
                "output_url": f"/generated/{output_png.name}",
                "metrics": metrics,
            })
    return items


@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/favicon.ico")
def favicon():
    return Response(status=204)


@app.route("/api/summary")
def api_summary():
    gtx = summarize_gpu(
        "GTX 1650",
        repo_path("results", "timing_results.csv"),
        repo_path("results", "summary_best_versions.csv"),
    )
    rtx = summarize_gpu(
        "RTX 4070",
        repo_path("results", "timing_results_rtx4070.csv"),
        repo_path("results", "summary_best_versions_rtx4070.csv"),
    )
    return jsonify({
        "gpus": [gtx, rtx],
        "version_comparison": version_comparison_rows(repo_path("results", "timing_results.csv")),
        "direct_comparisons": [
            direct_comparison("GTX 1650", repo_path("results", "timing_results.csv")),
            direct_comparison("RTX 4070", repo_path("results", "timing_results_rtx4070.csv")),
        ],
        "method_note": (
            "Uploaded image dimensions determine most of the convolution workload. "
            "Timing depends mainly on image size, filter size, CUDA version, block size, "
            "GPU model, and CPU/GPU transfer overhead; not on the semantic content of the image."
        ),
    })


@app.route("/api/plots")
def api_plots():
    return jsonify({"plots": plot_entries()})


@app.route("/api/sample-demo")
def api_sample_demo():
    return jsonify({"samples": ensure_fallback_previews()})


@app.route("/api/run-demo", methods=["POST"])
def api_run_demo():
    ensure_directories()
    uploaded = request.files.get("image")
    if not uploaded:
        return jsonify({"ok": False, "error": "Please choose an image file first."}), 400

    filter_type = request.form.get("filter_type", "sobel").lower()
    filter_size = request.form.get("filter_size", "3")
    version = request.form.get("version", "cuda_shared_constant_filter")
    block_size = request.form.get("block_size", "16x16")

    if filter_type not in FILTER_TYPES:
        return jsonify({"ok": False, "error": "Unknown filter type."}), 400
    if filter_size not in FILTER_SIZES:
        return jsonify({"ok": False, "error": "Filter size must be 3, 5, 7, or 11."}), 400
    if version not in CUDA_VERSIONS:
        return jsonify({"ok": False, "error": "Unknown CUDA version."}), 400
    if block_size not in BLOCK_SIZES:
        return jsonify({"ok": False, "error": "Unknown CUDA block size."}), 400
    if version == "cuda_separable" and filter_type not in {"box", "gaussian"}:
        return jsonify({
            "ok": False,
            "error": "Separable convolution is only valid for box and Gaussian filters.",
        }), 400

    try:
        run_id, width, height, resized, preview_path, input_pgm = prepare_upload(uploaded)
        output_pgm = OUTPUT_DIR / f"{run_id}_output.pgm"
        output_png = OUTPUT_DIR / f"{run_id}_output.png"
        normalize_output = "false" if filter_type == "sharpen" else "true"
        command, stdout = run_cuda_demo(
            input_pgm,
            output_pgm,
            filter_type,
            filter_size,
            version,
            block_size,
            normalize_output=normalize_output,
            warmups=1,
            repeats=5,
        )
        out_width, out_height = image_to_png(output_pgm, output_png)
        metrics = parse_demo_stdout(stdout)
        return jsonify({
            "ok": True,
            "resized": resized,
            "width": width,
            "height": height,
            "filter_type": filter_type,
            "filter_size": int(filter_size),
            "version": version,
            "block_size": block_size,
            "original_url": f"/generated/{preview_path.name}",
            "output_url": f"/generated/{output_png.name}",
            "metrics": metrics,
            "command": " ".join(f'"{part}"' if " " in part else part for part in command),
            "stdout": stdout,
        })
    except subprocess.TimeoutExpired:
        return jsonify({"ok": False, "error": "CUDA demo timed out after 60 seconds."}), 504
    except Exception as error:
        return jsonify({"ok": False, "error": str(error)}), 500


@app.route("/repo/<path:relative_path>")
def serve_repo_file(relative_path):
    path = (REPO_ROOT / relative_path).resolve()
    if not str(path).startswith(str(REPO_ROOT)) or not path.exists():
        return jsonify({"error": "File not found."}), 404
    return send_file(path)


@app.route("/generated/<path:filename>")
def serve_generated(filename):
    for directory in (OUTPUT_DIR, FALLBACK_DIR):
        candidate = (directory / filename).resolve()
        if str(candidate).startswith(str(directory.resolve())) and candidate.exists():
            return send_file(candidate)
    return jsonify({"error": "Generated file not found."}), 404


if __name__ == "__main__":
    ensure_directories()
    port = int(os.environ.get("FLASK_RUN_PORT", "5000"))
    app.run(host="127.0.0.1", port=port, debug=False)
