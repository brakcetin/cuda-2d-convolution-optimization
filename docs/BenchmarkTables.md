# Benchmark Tables

Source files:

- `results/timing_results.csv`
- `results/correctness_results.csv`
- `results/summary_best_versions.csv`
- `results/timing_results_gtx1650_4096_stress.csv`

Official benchmark hardware:

- NVIDIA GeForce GTX 1650 with Max-Q Design

Official benchmark matrix:

- Images: 512x512, 1024x1024, 2048x2048
- Filters: 3x3, 5x5, 7x7, 11x11
- Filter types: box, gaussian, sharpen, sobel
- Block sizes: 8x8, 16x16, 32x8, 32x16
- Repeats: 5
- Warmups: 1
- Rows: 1056
- Failed rows: 0

Supplemental stress matrix:

- Image: 4096x4096
- Filters: 3x3, 5x5, 7x7, 11x11
- Filter types: box, gaussian, sharpen, sobel
- Block sizes: 8x8, 16x16, 32x8, 32x16
- Repeats: 3
- Rows: 352
- Failed rows: 0

## Headline Results

| Metric | Result |
|---|---|
| Best official kernel-only speedup | 449.182x, 2048x2048, 11x11 gaussian, `cuda_separable`, 32x8 block |
| Best official total GPU speedup | 36.267x, 2048x2048, 11x11 sobel, `cuda_shared_constant_filter`, 16x16 block |
| Best direct-convolution kernel-only speedup | 345.862x, 1024x1024, 11x11 sharpen, `cuda_shared_constant_filter`, 32x16 block |
| Best new Phase 4 kernel speedup | 159.010x, 1024x1024, 11x11 sharpen, `cuda_register_tiled`, 32x8 block |
| Best 4096 stress kernel-only speedup | 474.772x, 4096x4096, 11x11 box, `cuda_separable`, 32x8 block |
| Best 4096 stress total GPU speedup | 36.080x, 4096x4096, 11x11 gaussian, `cuda_separable`, 16x16 block |

## Representative Cases

| Image | Filter | Type | CPU avg ms | Best kernel-time version / block / speedup | Best total-time version / block / speedup |
|---|---:|---|---:|---|---|
| 512x512 | 3x3 | box | 3.378 | `cuda_multi_output` / 32x8 / 66.665x | `cuda_naive_global_memory` / 32x8 / 2.154x |
| 1024x1024 | 7x7 | sobel | 53.759 | `cuda_shared_constant_filter` / 32x8 / 178.537x | `cuda_register_tiled` / 16x16 / 11.237x |
| 2048x2048 | 11x11 | gaussian | 482.360 | `cuda_separable` / 32x8 / 449.182x | `cuda_separable` / 16x16 / 32.386x |
| 2048x2048 | 11x11 | sobel | 490.396 | `cuda_shared_constant_filter` / 32x16 / 286.632x | `cuda_shared_constant_filter` / 16x16 / 36.267x |

## Top Kernel-Only Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 2048x2048 | 11x11 | gaussian | `cuda_separable` | 32x8 | 482.360 | 1.074 | 17.929 | 449.182 | 26.904 |
| 2048x2048 | 11x11 | box | `cuda_separable` | 32x8 | 484.750 | 1.082 | 15.903 | 447.964 | 30.481 |
| 1024x1024 | 11x11 | gaussian | `cuda_separable` | 32x8 | 122.103 | 0.273 | 10.426 | 446.543 | 11.712 |
| 2048x2048 | 11x11 | gaussian | `cuda_separable` | 32x16 | 482.360 | 1.195 | 16.109 | 403.745 | 29.944 |
| 2048x2048 | 11x11 | gaussian | `cuda_separable` | 16x16 | 482.360 | 1.198 | 14.894 | 402.660 | 32.386 |
| 2048x2048 | 11x11 | box | `cuda_separable` | 16x16 | 484.750 | 1.206 | 13.844 | 402.014 | 35.015 |

## Top Total GPU Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 2048x2048 | 11x11 | sobel | `cuda_shared_constant_filter` | 16x16 | 490.396 | 2.912 | 13.522 | 168.434 | 36.267 |
| 2048x2048 | 11x11 | box | `cuda_separable` | 32x16 | 484.750 | 1.229 | 13.581 | 394.279 | 35.693 |
| 2048x2048 | 11x11 | box | `cuda_separable` | 16x16 | 484.750 | 1.206 | 13.844 | 402.014 | 35.015 |
| 2048x2048 | 11x11 | sharpen | `cuda_shared_constant_filter` | 16x16 | 535.894 | 3.000 | 15.509 | 178.613 | 34.554 |
| 2048x2048 | 11x11 | sharpen | `cuda_shared_constant_filter` | 32x16 | 535.894 | 1.702 | 15.562 | 314.903 | 34.437 |
| 2048x2048 | 11x11 | sharpen | `cuda_naive_global_memory` | 32x8 | 535.894 | 3.157 | 15.607 | 169.724 | 34.338 |

## Best Direct-Convolution Kernel Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1024x1024 | 11x11 | sharpen | `cuda_shared_constant_filter` | 32x16 | 142.356 | 0.412 | 7.175 | 345.862 | 19.840 |
| 1024x1024 | 11x11 | sharpen | `cuda_shared_constant_filter` | 32x8 | 142.356 | 0.431 | 6.250 | 330.374 | 22.777 |
| 2048x2048 | 11x11 | sharpen | `cuda_shared_constant_filter` | 32x16 | 535.894 | 1.702 | 15.562 | 314.903 | 34.437 |
| 2048x2048 | 11x11 | sharpen | `cuda_shared_constant_filter` | 32x8 | 535.894 | 1.747 | 16.078 | 306.809 | 33.332 |
| 1024x1024 | 11x11 | gaussian | `cuda_shared_constant_filter` | 32x16 | 122.103 | 0.419 | 5.085 | 291.502 | 24.011 |
| 1024x1024 | 11x11 | sobel | `cuda_shared_constant_filter` | 32x16 | 122.732 | 0.424 | 4.857 | 289.139 | 25.268 |

## Best New Phase 4 Kernel Speedups

| Image | Filter | Type | Version | Block | CPU ms | Kernel ms | Total ms | Kernel speedup | Total speedup |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1024x1024 | 11x11 | sharpen | `cuda_register_tiled` | 32x8 | 142.356 | 0.895 | 6.980 | 159.010 | 20.394 |
| 1024x1024 | 11x11 | sharpen | `cuda_register_tiled` | 32x16 | 142.356 | 0.915 | 5.982 | 155.588 | 23.797 |
| 2048x2048 | 7x7 | box | `cuda_register_tiled` | 16x16 | 223.334 | 1.471 | 13.982 | 151.836 | 15.972 |
| 2048x2048 | 7x7 | sharpen | `cuda_register_tiled` | 32x8 | 219.954 | 1.450 | 14.140 | 151.736 | 15.556 |
| 2048x2048 | 7x7 | box | `cuda_register_tiled` | 32x8 | 223.334 | 1.476 | 15.001 | 151.310 | 14.888 |
| 2048x2048 | 5x5 | sharpen | `cuda_register_tiled` | 32x8 | 121.922 | 0.809 | 17.441 | 150.681 | 6.991 |

## Plot Files

- `results/plots/speedup_by_version.png`
- `results/plots/time_by_image_size_3x3.png`
- `results/plots/speedup_by_filter_size_1024.png`
- `results/plots/kernel_vs_total_time.png`
- `results/plots/speedup_by_filter_type_1024_7x7.png`
- `results/plots/speedup_by_block_size_1024_7x7_box.png`
- `results/plots/direct_versions_speedup_1024_7x7_sobel.png`
