"""Plot GTX 1650 vs RTX 4070 hardware comparison for the Submission 2 report.

Compares raw best kernel times and peak kernel GFLOP/s. Speedup factors are
intentionally not compared across machines because each machine has a
different CPU baseline.
"""
import argparse

import matplotlib.pyplot as plt
import pandas as pd

CASES = [
    (1024, 7, "sobel", "1024x1024\n7x7 Sobel-like\n(direct)"),
    (4096, 11, "sobel", "4096x4096\n11x11 Sobel-like\n(direct)"),
    (4096, 11, "gaussian", "4096x4096\n11x11 Gaussian-like\n(separable)"),
]


def best_kernel_ms(df, size, fsize, ftype):
    case = df[(df["image_width"] == size) & (df["filter_size"] == fsize) & (df["filter_type"] == ftype)]
    return case["gpu_kernel_time_ms"].min()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--gtx", default=r"results\timing_results_gtx1650_official.csv")
    parser.add_argument("--rtx", default=r"results\timing_results_rtx4070.csv")
    parser.add_argument("--output", default=r"results\plots\gpu_comparison_kernel_time.png")
    args = parser.parse_args()

    gtx = pd.read_csv(args.gtx)
    rtx = pd.read_csv(args.rtx)

    labels = [c[3] for c in CASES]
    gtx_ms = [best_kernel_ms(gtx, *c[:3]) for c in CASES]
    rtx_ms = [best_kernel_ms(rtx, *c[:3]) for c in CASES]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    x = range(len(labels))
    width = 0.35
    ax1.bar([i - width / 2 for i in x], gtx_ms, width, label="GTX 1650 Max-Q", color="#1f77b4")
    ax1.bar([i + width / 2 for i in x], rtx_ms, width, label="RTX 4070 Laptop", color="#2ca02c")
    for i, (g, r) in enumerate(zip(gtx_ms, rtx_ms)):
        ax1.text(i - width / 2, g, f"{g:.2f}", ha="center", va="bottom", fontsize=8)
        ax1.text(i + width / 2, r, f"{r:.2f}", ha="center", va="bottom", fontsize=8)
    ax1.set_xticks(list(x))
    ax1.set_xticklabels(labels, fontsize=8)
    ax1.set_ylabel("Best kernel time (ms)")
    ax1.set_title("Best CUDA kernel time per case")
    ax1.legend()

    peak = [gtx["gpu_kernel_gflops"].max(), rtx["gpu_kernel_gflops"].max()]
    bars = ax2.bar(["GTX 1650 Max-Q", "RTX 4070 Laptop"], peak, color=["#1f77b4", "#2ca02c"])
    for bar, value in zip(bars, peak):
        ax2.text(bar.get_x() + bar.get_width() / 2, value, f"{value:.0f}", ha="center", va="bottom", fontsize=9)
    ax2.set_ylabel("Peak CUDA kernel GFLOP/s")
    ax2.set_title("Peak kernel GFLOP/s in the official matrix")

    fig.suptitle("GTX 1650 Max-Q vs RTX 4070 Laptop, same benchmark matrix")
    fig.tight_layout()
    fig.savefig(args.output, dpi=150)
    print(f"Plot written to {args.output}")


if __name__ == "__main__":
    main()
