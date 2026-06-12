"""Extract headline numbers from benchmark CSVs for the Submission 2 report."""
import sys

import pandas as pd

REPRESENTATIVE = [
    (512, 3, "box"),
    (1024, 7, "sobel"),
    (2048, 11, "sobel"),
    (4096, 11, "gaussian"),
    (4096, 11, "sobel"),
]


def best_row(df, metric):
    return df.loc[df[metric].idxmax()]


def fmt(row, metric):
    return (
        f"{row[metric]:.3f}x | {row['version']} | "
        f"{int(row['image_width'])}x{int(row['image_height'])} "
        f"{int(row['filter_size'])}x{int(row['filter_size'])} {row['filter_type']} | "
        f"block {int(row['block_width'])}x{int(row['block_height'])} | "
        f"cpu {row['cpu_time_ms']:.3f} ms kernel {row['gpu_kernel_time_ms']:.4f} ms "
        f"total {row['gpu_total_time_ms']:.3f} ms"
    )


def analyze(path, label):
    df = pd.read_csv(path)
    print(f"\n================ {label} ================")
    print("device:", df["device_name"].iloc[0])
    print("rows:", len(df), "| failed:", (df["passed"] != True).sum() if df["passed"].dtype == bool else (df["passed"].astype(str).str.lower() != "true").sum())
    print("max abs error overall: %.3e" % df["max_abs_error"].max())

    direct = df[df["version"] != "cuda_separable"]
    new_kernels = df[df["version"].isin(["cuda_multi_output", "cuda_register_tiled"])]

    print("\n-- headline --")
    print("best kernel speedup:        ", fmt(best_row(df, "kernel_speedup"), "kernel_speedup"))
    print("best total speedup:         ", fmt(best_row(df, "total_speedup"), "total_speedup"))
    print("best direct kernel speedup: ", fmt(best_row(direct, "kernel_speedup"), "kernel_speedup"))
    print("best new-kernel speedup:    ", fmt(best_row(new_kernels, "kernel_speedup"), "kernel_speedup"))
    print("best kernel GFLOP/s:        ", fmt(best_row(df, "gpu_kernel_gflops"), "gpu_kernel_gflops"), "->", f"{df['gpu_kernel_gflops'].max():.1f} GFLOP/s")

    print("\n-- representative cases --")
    for size, fsize, ftype in REPRESENTATIVE:
        case = df[(df["image_width"] == size) & (df["filter_size"] == fsize) & (df["filter_type"] == ftype)]
        bk = best_row(case, "kernel_speedup")
        bt = best_row(case, "total_speedup")
        print(
            f"{size}x{size} {fsize}x{fsize} {ftype}: cpu {case['cpu_time_ms'].iloc[0]:.3f} ms | "
            f"kernel-best {bk['version']} {int(bk['block_width'])}x{int(bk['block_height'])} {bk['kernel_speedup']:.3f}x | "
            f"total-best {bt['version']} {int(bt['block_width'])}x{int(bt['block_height'])} {bt['total_speedup']:.3f}x"
        )

    print("\n-- per-version best kernel speedup at 4096 11x11 sobel (direct showcase) --")
    case = df[(df["image_width"] == 4096) & (df["filter_size"] == 11) & (df["filter_type"] == "sobel")]
    for ver, gr in case.groupby("version"):
        b = best_row(gr, "kernel_speedup")
        print(
            f"{ver:>30}: kernel {b['gpu_kernel_time_ms']:.4f} ms | {b['kernel_speedup']:.3f}x kernel | "
            f"{b['total_speedup']:.3f}x total | block {int(b['block_width'])}x{int(b['block_height'])}"
        )

    print("\n-- per-version best kernel speedup at 4096 11x11 gaussian (separable showcase) --")
    case = df[(df["image_width"] == 4096) & (df["filter_size"] == 11) & (df["filter_type"] == "gaussian")]
    for ver, gr in case.groupby("version"):
        b = best_row(gr, "kernel_speedup")
        print(
            f"{ver:>30}: kernel {b['gpu_kernel_time_ms']:.4f} ms | {b['kernel_speedup']:.3f}x kernel | "
            f"{b['total_speedup']:.3f}x total | block {int(b['block_width'])}x{int(b['block_height'])}"
        )

    print("\n-- block shape winners (kernel-time) --")
    summary = df.loc[df.groupby(["image_width", "filter_size", "filter_type"])["kernel_speedup"].idxmax()]
    print(summary.groupby(["block_width", "block_height"]).size().to_string())

    print("\n-- cpu time range --")
    print(f"min cpu {df['cpu_time_ms'].min():.3f} ms (512 small) | max cpu {df['cpu_time_ms'].max():.3f} ms")


analyze(sys.argv[1] if len(sys.argv) > 1 else r"results\timing_results_gtx1650_official.csv", "GTX 1650 Max-Q (official)")
analyze(sys.argv[2] if len(sys.argv) > 2 else r"results\timing_results_rtx4070.csv", "RTX 4070 Laptop (secondary)")
