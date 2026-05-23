#!/usr/bin/env python3
"""Generate benchmark plots from results/timing_results.csv."""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path


def read_rows(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def require_matplotlib():
    try:
        import matplotlib.pyplot as plt  # type: ignore
    except ImportError as exc:
        raise SystemExit(
            "matplotlib is required for plotting. Install it with: python -m pip install matplotlib"
        ) from exc
    return plt


def group_by(rows: list[dict[str, str]], key: str) -> dict[str, list[dict[str, str]]]:
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        grouped[row[key]].append(row)
    return grouped


def plot_speedup_by_version(rows: list[dict[str, str]], output_dir: Path) -> None:
    plt = require_matplotlib()
    grouped = group_by(rows, "version")

    plt.figure(figsize=(10, 6))
    for version, version_rows in sorted(grouped.items()):
        version_rows = sorted(version_rows, key=lambda row: (int(row["filter_size"]), int(row["image_width"])))
        labels = [f'{row["image_width"]}x{row["filter_size"]}' for row in version_rows]
        values = [float(row["kernel_speedup"]) for row in version_rows]
        plt.plot(labels, values, marker="o", label=version)

    plt.xticks(rotation=45, ha="right")
    plt.ylabel("Kernel speedup vs CPU")
    plt.xlabel("Image width x filter size")
    plt.title("CUDA Kernel Speedup by Version")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "speedup_by_version.png", dpi=160)
    plt.close()


def plot_time_by_image_size(rows: list[dict[str, str]], output_dir: Path) -> None:
    plt = require_matplotlib()
    grouped = group_by(rows, "version")

    plt.figure(figsize=(10, 6))
    cpu_by_size: dict[int, float] = {}
    for row in rows:
        if row["filter_size"] == "3":
            cpu_by_size[int(row["image_width"])] = float(row["cpu_time_ms"])

    if cpu_by_size:
        sizes = sorted(cpu_by_size)
        plt.plot(sizes, [cpu_by_size[size] for size in sizes], marker="o", label="cpu_sequential")

    for version, version_rows in sorted(grouped.items()):
        filtered = [row for row in version_rows if row["filter_size"] == "3"]
        filtered = sorted(filtered, key=lambda row: int(row["image_width"]))
        if filtered:
            plt.plot(
                [int(row["image_width"]) for row in filtered],
                [float(row["gpu_kernel_time_ms"]) for row in filtered],
                marker="o",
                label=version,
            )

    plt.ylabel("Time (ms)")
    plt.xlabel("Image width, square image")
    plt.title("CPU vs CUDA Kernel Time for 3x3 Filter")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "time_by_image_size_3x3.png", dpi=160)
    plt.close()


def plot_speedup_by_filter_size(rows: list[dict[str, str]], output_dir: Path) -> None:
    plt = require_matplotlib()
    grouped = group_by(rows, "version")

    plt.figure(figsize=(10, 6))
    for version, version_rows in sorted(grouped.items()):
        filtered = [row for row in version_rows if row["image_width"] == "1024"]
        filtered = sorted(filtered, key=lambda row: int(row["filter_size"]))
        if filtered:
            plt.plot(
                [int(row["filter_size"]) for row in filtered],
                [float(row["kernel_speedup"]) for row in filtered],
                marker="o",
                label=version,
            )

    plt.ylabel("Kernel speedup vs CPU")
    plt.xlabel("Filter size")
    plt.title("Speedup by Filter Size for 1024x1024 Image")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "speedup_by_filter_size_1024.png", dpi=160)
    plt.close()


def plot_kernel_vs_total(rows: list[dict[str, str]], output_dir: Path) -> None:
    plt = require_matplotlib()
    selected = [row for row in rows if row["filter_size"] == "3" and row["image_width"] == "1024"]
    selected = sorted(selected, key=lambda row: row["version"])
    if not selected:
        return

    labels = [row["version"] for row in selected]
    kernel_times = [float(row["gpu_kernel_time_ms"]) for row in selected]
    total_times = [float(row["gpu_total_time_ms"]) for row in selected]
    positions = range(len(selected))

    plt.figure(figsize=(10, 6))
    plt.bar([position - 0.2 for position in positions], kernel_times, width=0.4, label="kernel")
    plt.bar([position + 0.2 for position in positions], total_times, width=0.4, label="total")
    plt.xticks(list(positions), labels, rotation=30, ha="right")
    plt.ylabel("Time (ms)")
    plt.title("CUDA Kernel-only vs Total Time, 1024x1024 3x3")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "kernel_vs_total_time.png", dpi=160)
    plt.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate benchmark plots.")
    parser.add_argument("--input", default="results/timing_results.csv", type=Path)
    parser.add_argument("--output-dir", default="results/plots", type=Path)
    args = parser.parse_args()

    rows = read_rows(args.input)
    if not rows:
        raise SystemExit(f"No benchmark rows found in {args.input}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    plot_speedup_by_version(rows, args.output_dir)
    plot_time_by_image_size(rows, args.output_dir)
    plot_speedup_by_filter_size(rows, args.output_dir)
    plot_kernel_vs_total(rows, args.output_dir)
    print(f"Plots written to {args.output_dir}")


if __name__ == "__main__":
    main()
