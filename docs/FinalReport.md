# Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-Hierarchy-Aware CUDA Implementations

Course: CENG-479 Parallel Programming  
Team: Burak Cetin and Cagri Celik  
Repository: https://github.com/brakcetin/cuda-2d-convolution-optimization  
Language: English

## 1. Introduction

Two-dimensional image convolution is a core operation in image processing and computer vision. It is used for blur, edge detection, sharpening, denoising, feature extraction, and convolutional neural-network layers. For an image of size `W x H` and a square filter of size `k x k`, direct convolution requires each output pixel to read a local neighborhood and multiply it by the filter coefficients. As image size and filter size grow, the total number of operations increases quickly.

This project studies how CUDA can accelerate grayscale 2D convolution compared with a sequential CPU baseline. The implementation starts with a simple global-memory CUDA kernel and then adds memory-hierarchy-aware and algorithmic variants: shared-memory tiling, constant-memory filters, separable convolution, block-size sweeps, multi-output direct convolution, and register-tiled direct convolution.

The final benchmark uses synthetic grayscale images and four filter types: box, Gaussian-like, sharpen, and Sobel-like. All CUDA results are checked against CPU reference outputs before being included in the analysis.

The repository also includes a qualitative real-image demo path using grayscale PGM images. This demo is useful for presentation screenshots and visual inspection, but it is not used for official speedup claims because real-image content is less controlled than synthetic benchmark data.

Real-image conversion was performed with ImageMagick 7.1.2-23 Q16-HDRI on Windows. The project keeps this conversion step outside the official benchmark so image-decoding overhead does not affect the CUDA timing analysis.

### Proposal Alignment

The final implementation follows and extends the original project proposal. The required sequential CPU baseline, naive CUDA implementation, shared-memory tiled implementation, constant-memory filter optimization, separable convolution path, correctness verification, and speedup analysis are all implemented. The benchmark matrix also includes the proposed large image sizes up to 4096x4096, multiple filter sizes from 3x3 to 11x11, and both kernel-only and total GPU timing.

The project also adds stronger comparison dimensions beyond the proposal: filter-type experiments, block-size sweeps, timing statistics, GFLOP/s estimates, GPU transfer/allocation breakdown, multi-output direct convolution, and register-tiled direct convolution. These additions support the project goal of being a performance study rather than a minimal CPU-vs-GPU demo.

## 2. Sequential Baseline Implementation

The sequential baseline is a single-threaded C++ implementation. It uses nested loops over image rows, image columns, filter rows, and filter columns. Boundary handling uses zero-padding semantics: when a filter coordinate falls outside the image, that value contributes zero to the sum.

The CPU baseline serves two roles:

- It is the correctness oracle for direct CUDA convolution versions.
- It provides the baseline time used in speedup calculations.

The baseline intentionally remains single-threaded. This keeps the comparison focused on the benefit of CUDA parallelism rather than mixing GPU acceleration with CPU multi-threading.

## 3. Parallel Implementation

The CUDA implementations all compute the same convolution result for the same input/filter pair, with the exception that separable convolution is used only for filters generated from a 1D separable form.

Implemented versions:

- `cuda_naive_global_memory`: one CUDA thread computes one output pixel. Input pixels and filter coefficients are read directly from global memory.
- `cuda_shared_memory_tiled`: each thread block loads an input tile plus halo into dynamic shared memory, then computes output pixels from the shared tile.
- `cuda_shared_constant_filter`: combines shared-memory input tiling with CUDA constant memory for filter coefficients.
- `cuda_multi_output`: each thread computes two horizontally adjacent direct-convolution outputs.
- `cuda_register_tiled`: each thread computes a 2x1 direct-convolution tile using two register accumulators.
- `cuda_separable`: applies horizontal and vertical 1D convolution passes for box and Gaussian-like filters.

The benchmark also sweeps block shapes: 8x8, 16x16, 32x8, and 32x16. This makes launch configuration part of the experiment rather than a hidden constant.

## 4. Performance Comparison

Official benchmark hardware:

- NVIDIA GeForce GTX 1650 with Max-Q Design

Official benchmark matrix:

- Image sizes: 512x512, 1024x1024, 2048x2048, 4096x4096
- Filter sizes: 3x3, 5x5, 7x7, 11x11
- Filter types: box, Gaussian-like, sharpen, Sobel-like
- Block sizes: 8x8, 16x16, 32x8, 32x16
- Repeats: 5
- Warmups: 1
- Rows: 1408
- Failed correctness rows: 0

Historical supplemental files:

- The older `*_gtx1650_4096_stress.csv` files are preserved as lower-repeat 4096-only artifacts.
- The official analysis now uses 4096x4096 in the 5-repeat matrix above.

### Headline Results

| Metric | Result |
|---|---|
| Best official kernel-only speedup | 744.216x, 4096x4096, 11x11 Gaussian-like, `cuda_separable`, 32x8 block |
| Best official total GPU speedup | 56.205x, 4096x4096, 11x11 Gaussian-like, `cuda_separable`, 32x8 block |
| Best direct-convolution kernel-only speedup | 432.778x, 4096x4096, 11x11 Sobel-like, `cuda_shared_constant_filter`, 32x16 block |
| Best new Phase 4 kernel speedup | 409.608x, 512x512, 3x3 Sobel-like, `cuda_register_tiled`, 16x16 block |

### Representative Cases

| Image | Filter | Type | CPU avg ms | Best kernel-time version / block / speedup | Best total-time version / block / speedup |
|---|---:|---|---:|---|---|
| 512x512 | 3x3 | box | 5.864 | `cuda_register_tiled` / 32x8 / 117.800x | `cuda_shared_memory_tiled` / 8x8 / 2.831x |
| 1024x1024 | 7x7 | sobel | 60.089 | `cuda_shared_constant_filter` / 32x16 / 146.015x | `cuda_shared_constant_filter` / 32x16 / 13.634x |
| 2048x2048 | 11x11 | sobel | 609.550 | `cuda_shared_constant_filter` / 32x16 / 355.709x | `cuda_shared_constant_filter` / 32x16 / 47.434x |
| 4096x4096 | 11x11 | gaussian | 3170.441 | `cuda_separable` / 32x8 / 744.216x | `cuda_separable` / 32x8 / 56.205x |
| 4096x4096 | 11x11 | sobel | 3063.866 | `cuda_shared_constant_filter` / 32x16 / 432.778x | `cuda_register_tiled` / 32x8 / 46.974x |

The most important observation is that kernel-only speedup and total GPU speedup answer different questions. Kernel-only speedup measures the computational advantage of the CUDA kernel after data is available on the GPU. Total GPU speedup includes allocation and host/device transfer overhead, making it closer to application-level performance.

`cuda_separable` wins the strongest kernel-only and total-time cases because it reduces an 11x11 direct convolution from 121 filter operations per pixel to two 11-element 1D passes. However, `cuda_separable` is used only for box and Gaussian-like filters. For direct filters such as sharpen and Sobel-like kernels, `cuda_shared_constant_filter` remains the strongest kernel-time method in the official results.

## 5. Academic Background

The project follows the memory-hierarchy theme found in GPU convolution literature. Direct convolution has high arithmetic intensity for larger filters, but it also repeatedly reads overlapping input neighborhoods. This makes memory movement and data reuse central to performance.

Shared-memory tiling is motivated by the fact that neighboring output pixels reuse many of the same input pixels. Loading a tile plus halo into shared memory can reduce redundant global-memory reads. The implementation also measures the cost of halo loading and block shape because tile geometry can change the amount of useful work per loaded value.

Constant memory is suitable for small read-only filters because many threads access the same coefficients. The results support this: the shared+constant implementation is the strongest direct-convolution version in several 11x11 sharpen and Sobel-like cases.

Separable convolution is an algorithmic optimization rather than only a memory optimization. For box and Gaussian-like filters, replacing a `k x k` convolution with two 1D convolutions changes the operation count from `k^2` to `2k` per pixel. This explains why the separable version dominates the largest separable-filter cases.

The block-size sweep connects to adaptive tiling work. The winning block shape changes by workload, so a fixed 16x16 launch is not always the best choice. In this project, 32x8 frequently performs well for kernel-only speedup, while total-time winners sometimes differ.

## 6. Challenges and Solutions

Boundary handling was a correctness risk because CPU and CUDA kernels must agree on image edges. The solution was to use zero-padding semantics consistently and compare every CUDA output against a CPU reference.

Shared-memory halo indexing was another risk. The implementation loads a full tile of size `(block_width + 2 * radius) x (block_height + 2 * radius)` and then computes from local shared-memory coordinates. Correctness testing across multiple filter sizes helps catch tile-boundary mistakes.

Timing methodology required care. CPU time is measured with `std::chrono`; CUDA kernel time is measured with CUDA events. The benchmark records average, minimum, maximum, and standard deviation. It also separates kernel-only time from total GPU time, including allocation, host-to-device copy, device-to-host copy, and free time.

Interpreting the new multi-output and register-tiled kernels also required care. These kernels change thread work assignment and local accumulator reuse, but they do not reduce the mathematical operation count. Therefore, they are best discussed as direct-convolution scheduling experiments, not as algorithmic reductions.

Real-image demonstration was kept separate from official benchmarking. The project supports PGM input/output so that Sobel, sharpen, and Gaussian results can be shown visually, while the official performance matrix remains synthetic and reproducible.

## 7. Conclusion and Future Improvements

The project successfully implements and benchmarks a sequential CPU baseline and multiple CUDA convolution variants. All official CUDA benchmark rows pass correctness verification. The final results show substantial speedups on the GTX 1650, especially for larger images and filters.

The strongest kernel-only result comes from separable convolution on a 4096x4096, 11x11 Gaussian-like filter, reaching 744.216x speedup. The strongest total-time result is the same separable case, reaching 56.205x speedup. The strongest direct-convolution kernel result comes from shared+constant filtering on a 4096x4096, 11x11 Sobel-like filter, reaching 432.778x speedup. This shows that both algorithmic structure and memory hierarchy matter.

Future improvements could include Nsight Compute profiling, automated report table generation, RTX 4070 comparison, RGB image support, and richer image-format support. A simple dependency-free PGM path is included for demonstration, while the official benchmark remains synthetic for reproducibility. More advanced convolution methods such as FFT, Winograd, cuDNN, and OpenCV/GpuCV integration remain outside the current project scope.

No graphical UI is required for this project. The course deliverables focus on source code, GitHub repository link, implementation report, benchmark tables/graphs, and a 10-minute presentation. For that reason, the implementation prioritizes reproducible command-line benchmarking and clear CSV/plot outputs.

## 8. References

Allusse, Y., Horain, P., Agarwal, A., & Saipriyadarshan, C. (2008). GpuCV: A GPU-accelerated framework for image processing and computer vision. *Lecture Notes in Computer Science*, 5359, 430-439. https://doi.org/10.1007/978-3-540-89646-3_42

Iandola, F. N., Sheffield, D., Anderson, M. J., Phothilimthana, P. M., & Keutzer, K. (2013). Communication-minimizing 2D convolution in GPU registers. *2013 IEEE International Conference on Image Processing (ICIP)*, 2116-2120. https://doi.org/10.1109/ICIP.2013.6738436

Jorda, M., Valero-Lara, P., & Pena, A. J. (2019). Performance evaluation of cuDNN convolution algorithms on NVIDIA Volta GPUs. *IEEE Access, 7*, 70461-70473. https://doi.org/10.1109/ACCESS.2019.2918851

Lu, G., Zhang, W., & Wang, Z. (2020). Optimizing GPU memory transactions for convolution operations. *2020 IEEE International Conference on Cluster Computing (CLUSTER)*, 399-403. https://doi.org/10.1109/CLUSTER49012.2020.00050

Perrot, G., Domas, S., & Couturier, R. (2016). An optimized GPU-based 2D convolution implementation. *Concurrency and Computation: Practice and Experience, 28*(16), 4291-4304. https://doi.org/10.1002/cpe.3752

Van Werkhoven, B., Maassen, J., Bal, H. E., & Seinstra, F. J. (2014). Optimizing convolution operations on GPUs using adaptive tiling. *Future Generation Computer Systems, 30*(1), 14-26. https://doi.org/10.1016/j.future.2013.09.003
