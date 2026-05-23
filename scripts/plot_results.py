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


def default_filter_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    if rows and "filter_type" in rows[0]:
        box_rows = [row for row in rows if row["filter_type"] == "box"]
        if box_rows:
            rows = box_rows
    if rows and "block_width" in rows[0] and "block_height" in rows[0]:
        default_block_rows = [
            row for row in rows
            if row["block_width"] == "16" and row["block_height"] == "16"
        ]
        if default_block_rows:
            return default_block_rows
    return rows


def plot_speedup_by_version(rows: list[dict[str, str]], output_dir: Path) -> None:
    plt = require_matplotlib()
    rows = default_filter_rows(rows)
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
    rows = default_filter_rows(rows)
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
    rows = default_filter_rows(rows)
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
    rows = default_filter_rows(rows)
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


def plot_speedup_by_filter_type(rows: list[dict[str, str]], output_dir: Path) -> None:
    if not rows or "filter_type" not in rows[0]:
        return
    if "block_width" in rows[0] and "block_height" in rows[0]:
        rows = [
            row for row in rows
            if row["block_width"] == "16" and row["block_height"] == "16"
        ]

    plt = require_matplotlib()
    selected = [
        row
        for row in rows
        if row["image_width"] == "1024" and row["filter_size"] == "7"
    ]
    selected = sorted(selected, key=lambda row: (row["version"], row["filter_type"]))
    if not selected:
        return

    grouped = group_by(selected, "version")
    filter_types = sorted({row["filter_type"] for row in selected})

    plt.figure(figsize=(10, 6))
    for version, version_rows in sorted(grouped.items()):
        by_type = {row["filter_type"]: float(row["kernel_speedup"]) for row in version_rows}
        values = [by_type.get(filter_type, 0.0) for filter_type in filter_types]
        plt.plot(filter_types, values, marker="o", label=version)

    plt.ylabel("Kernel speedup vs CPU")
    plt.xlabel("Filter type")
    plt.title("Speedup by Filter Type, 1024x1024 7x7")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "speedup_by_filter_type_1024_7x7.png", dpi=160)
    plt.close()


def plot_speedup_by_block_size(rows: list[dict[str, str]], output_dir: Path) -> None:
    if not rows or "block_width" not in rows[0] or "block_height" not in rows[0]:
        return

    plt = require_matplotlib()
    selected = [
        row
        for row in rows
        if row.get("filter_type", "box") == "box"
        and row["image_width"] == "1024"
        and row["filter_size"] == "7"
    ]
    selected = sorted(
        selected,
        key=lambda row: (row["version"], int(row["block_width"]), int(row["block_height"])),
    )
    if not selected:
        return

    grouped = group_by(selected, "version")
    block_labels = sorted(
        {f'{row["block_width"]}x{row["block_height"]}' for row in selected},
        key=lambda label: (int(label.split("x")[0]), int(label.split("x")[1])),
    )

    plt.figure(figsize=(10, 6))
    for version, version_rows in sorted(grouped.items()):
        by_block = {
            f'{row["block_width"]}x{row["block_height"]}': float(row["kernel_speedup"])
            for row in version_rows
        }
        values = [by_block.get(block_label, 0.0) for block_label in block_labels]
        plt.plot(block_labels, values, marker="o", label=version)

    plt.ylabel("Kernel speedup vs CPU")
    plt.xlabel("CUDA block size")
    plt.title("Speedup by Block Size, 1024x1024 7x7 Box Filter")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "speedup_by_block_size_1024_7x7_box.png", dpi=160)
    plt.close()


def plot_direct_versions_sobel(rows: list[dict[str, str]], output_dir: Path) -> None:
    if not rows or "filter_type" not in rows[0]:
        return

    plt = require_matplotlib()
    direct_versions = {
        "cuda_naive_global_memory",
        "cuda_shared_memory_tiled",
        "cuda_shared_constant_filter",
        "cuda_multi_output",
        "cuda_register_tiled",
    }
    selected = [
        row
        for row in rows
        if row["image_width"] == "1024"
        and row["filter_size"] == "7"
        and row["filter_type"] == "sobel"
        and row["version"] in direct_versions
    ]
    if not selected:
        return

    grouped = group_by(selected, "version")
    block_labels = sorted(
        {f'{row["block_width"]}x{row["block_height"]}' for row in selected},
        key=lambda label: (int(label.split("x")[0]), int(label.split("x")[1])),
    )

    plt.figure(figsize=(10, 6))
    for version, version_rows in sorted(grouped.items()):
        by_block = {
            f'{row["block_width"]}x{row["block_height"]}': float(row["kernel_speedup"])
            for row in version_rows
        }
        values = [by_block.get(block_label, 0.0) for block_label in block_labels]
        plt.plot(block_labels, values, marker="o", label=version)

    plt.ylabel("Kernel speedup vs CPU")
    plt.xlabel("CUDA block size")
    plt.title("Direct CUDA Versions, 1024x1024 7x7 Sobel")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "direct_versions_speedup_1024_7x7_sobel.png", dpi=160)
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
    plot_speedup_by_filter_type(rows, args.output_dir)
    plot_speedup_by_block_size(rows, args.output_dir)
    plot_direct_versions_sobel(rows, args.output_dir)
    print(f"Plots written to {args.output_dir}")


if __name__ == "__main__":
    main()
