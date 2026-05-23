# Benchmark Tables

Source files:

- `results/timing_results.csv`
- `results/correctness_results.csv`
- `results/summary_best_versions.csv`
- `results/timing_results_gtx1650_official.csv`
- `results/correctness_results_gtx1650_official.csv`
- `results/summary_best_versions_gtx1650_official.csv`

Official benchmark hardware:

- NVIDIA GeForce GTX 1650 with Max-Q Design

Official benchmark matrix:

- Images: 512x512, 1024x1024, 2048x2048, 4096x4096
- Filters: 3x3, 5x5, 7x7, 11x11
- Filter types: box, gaussian, sharpen, sobel
- Block sizes: 8x8, 16x16, 32x8, 32x16
- Repeats: 5
- Warmups: 1
- Rows: 1408
- Failed rows: 0

Historical supplemental files:

- The older `results/*_gtx1650_4096_stress.csv` files are preserved as lower-repeat 4096-only artifacts.
- The official analysis now uses the 4096x4096 rows in the 5-repeat matrix above.

These tables are intended for report and presentation use. The full raw matrix should remain in CSV form because the official timing file contains 1408 rows.

## Headline Results

| Metric | Result |
|---|---|
| Best official kernel-only speedup | 744.216x, 4096x4096, 11x11 gaussian, `cuda_separable`, 32x8 block |
| Best official total GPU speedup | 56.205x, 4096x4096, 11x11 gaussian, `cuda_separable`, 32x8 block |
| Best direct-convolution kernel-only speedup | 432.778x, 4096x4096, 11x11 sobel, `cuda_shared_constant_filter`, 32x16 block |
| Best new Phase 4 kernel speedup | 409.608x, 512x512, 3x3 sobel, `cuda_register_tiled`, 16x16 block |

## Representative Cases

| Image | Filter | Type | CPU avg ms | Best kernel-time version / block / speedup | Best total-time version / block / speedup |
|---|---:|---|---:|---|---|
| 512x512 | 3x3 | box | 5.864 | `cuda_register_tiled` / 32x8 / 117.800x | `cuda_shared_memory_tiled` / 8x8 / 2.831x |
| 1024x1024 | 7x7 | sobel | 60.089 | `cuda_shared_constant_filter` / 32x16 / 146.015x | `cuda_shared_constant_filter` / 32x16 / 13.634x |
| 2048x2048 | 11x11 | sobel | 609.550 | `cuda_shared_constant_filter` / 32x16 / 355.709x | `cuda_shared_constant_filter` / 32x16 / 47.434x |
| 4096x4096 | 11x11 | gaussian | 3170.441 | `cuda_separable` / 32x8 / 744.216x | `cuda_separable` / 32x8 / 56.205x |
| 4096x4096 | 11x11 | sobel | 3063.866 | `cuda_shared_constant_filter` / 32x16 / 432.778x | `cuda_register_tiled` / 32x8 / 46.974x |

## Top Kernel-Only Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 32x8 | 3170.441 | 4.260 | 56.408 | 744.216 | 56.205 |
| 4096x4096 | 11x11 | box | `cuda_separable` | 32x8 | 3053.739 | 4.240 | 62.314 | 720.194 | 49.005 |
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 16x16 | 3170.441 | 4.553 | 61.512 | 696.349 | 51.542 |
| 4096x4096 | 11x11 | box | `cuda_separable` | 16x16 | 3053.739 | 4.504 | 84.459 | 678.066 | 36.156 |
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 32x16 | 3170.441 | 4.823 | 60.923 | 657.378 | 52.040 |
| 4096x4096 | 11x11 | box | `cuda_separable` | 32x16 | 3053.739 | 4.899 | 78.219 | 623.318 | 39.041 |

## Top Total GPU Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 32x8 | 3170.441 | 4.260 | 56.408 | 744.216 | 56.205 |
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 32x16 | 3170.441 | 4.823 | 60.923 | 657.378 | 52.040 |
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 16x16 | 3170.441 | 4.553 | 61.512 | 696.349 | 51.542 |
| 4096x4096 | 11x11 | gaussian | `cuda_shared_constant_filter` | 32x8 | 3170.441 | 7.572 | 62.202 | 418.731 | 50.970 |
| 4096x4096 | 11x11 | gaussian | `cuda_separable` | 8x8 | 3170.441 | 6.218 | 62.512 | 509.849 | 50.717 |
| 4096x4096 | 11x11 | gaussian | `cuda_naive_global_memory` | 32x16 | 3170.441 | 15.542 | 62.820 | 203.991 | 50.468 |

## Best Direct-Convolution Kernel Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 4096x4096 | 11x11 | sobel | `cuda_shared_constant_filter` | 32x16 | 3063.866 | 7.080 | 83.690 | 432.778 | 36.610 |
| 4096x4096 | 11x11 | gaussian | `cuda_shared_constant_filter` | 32x16 | 3170.441 | 7.396 | 71.242 | 428.675 | 44.502 |
| 4096x4096 | 11x11 | box | `cuda_shared_constant_filter` | 32x16 | 3053.739 | 7.262 | 71.375 | 420.535 | 42.785 |
| 4096x4096 | 11x11 | sobel | `cuda_shared_constant_filter` | 32x8 | 3063.866 | 7.298 | 69.592 | 419.809 | 44.026 |
| 4096x4096 | 11x11 | gaussian | `cuda_shared_constant_filter` | 32x8 | 3170.441 | 7.572 | 62.202 | 418.731 | 50.970 |
| 4096x4096 | 11x11 | box | `cuda_shared_constant_filter` | 32x8 | 3053.739 | 7.370 | 83.124 | 414.364 | 36.737 |

## Best New Phase 4 Kernel Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 512x512 | 3x3 | sobel | `cuda_register_tiled` | 16x16 | 19.973 | 0.049 | 2.944 | 409.608 | 6.784 |
| 512x512 | 3x3 | sobel | `cuda_multi_output` | 32x8 | 19.973 | 0.055 | 2.826 | 363.857 | 7.067 |
| 512x512 | 3x3 | sobel | `cuda_multi_output` | 32x16 | 19.973 | 0.056 | 8.853 | 358.260 | 2.256 |
| 512x512 | 5x5 | gaussian | `cuda_register_tiled` | 32x8 | 27.168 | 0.095 | 2.324 | 287.059 | 11.688 |
| 512x512 | 3x3 | sobel | `cuda_register_tiled` | 8x8 | 19.973 | 0.071 | 3.270 | 282.681 | 6.108 |
| 512x512 | 5x5 | gaussian | `cuda_register_tiled` | 32x16 | 27.168 | 0.097 | 2.617 | 281.314 | 10.381 |

## Plot Files

- `results/plots/speedup_by_version.png`
- `results/plots/time_by_image_size_3x3.png`
- `results/plots/speedup_by_filter_size_1024.png`
- `results/plots/kernel_vs_total_time.png`
- `results/plots/speedup_by_filter_type_1024_7x7.png`
- `results/plots/speedup_by_block_size_1024_7x7_box.png`
- `results/plots/direct_versions_speedup_1024_7x7_sobel.png`
