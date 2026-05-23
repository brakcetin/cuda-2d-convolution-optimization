#include "convolution_cuda.cuh"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <numeric>
#include <stdexcept>
#include <vector>

namespace {

constexpr int kMaxConstantFilterElements = 11 * 11;

__constant__ float c_filter[kMaxConstantFilterElements];

enum class KernelKind {
    NaiveGlobalMemory,
    SharedMemoryTiled,
    SharedConstantFilter,
    MultiOutput,
    RegisterTiled,
};

TimingStats compute_timing_stats(const std::vector<double>& samples) {
    if (samples.empty()) {
        return {};
    }

    TimingStats stats;
    stats.min_ms = *std::min_element(samples.begin(), samples.end());
    stats.max_ms = *std::max_element(samples.begin(), samples.end());
    stats.average_ms = std::accumulate(samples.begin(), samples.end(), 0.0) /
                       static_cast<double>(samples.size());

    double variance = 0.0;
    for (const double sample : samples) {
        const double difference = sample - stats.average_ms;
        variance += difference * difference;
    }
    variance /= static_cast<double>(samples.size());
    stats.stddev_ms = std::sqrt(variance);

    return stats;
}

double elapsed_ms(std::chrono::high_resolution_clock::time_point start,
                  std::chrono::high_resolution_clock::time_point stop) {
    return std::chrono::duration<double, std::milli>(stop - start).count();
}

__global__ void convolution_naive_kernel(const float* input,
                                         float* output,
                                         int width,
                                         int height,
                                         const float* filter,
                                         int filter_size) {
    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) {
        return;
    }

    const int radius = filter_size / 2;
    float sum = 0.0f;

    for (int fy = 0; fy < filter_size; ++fy) {
        const int image_y = y + fy - radius;
        if (image_y < 0 || image_y >= height) {
            continue;
        }

        for (int fx = 0; fx < filter_size; ++fx) {
            const int image_x = x + fx - radius;
            if (image_x < 0 || image_x >= width) {
                continue;
            }

            const float image_value = input[image_y * width + image_x];
            const float filter_value = filter[fy * filter_size + fx];
            sum += image_value * filter_value;
        }
    }

    output[y * width + x] = sum;
}

__global__ void convolution_shared_memory_kernel(const float* input,
                                                 float* output,
                                                 int width,
                                                 int height,
                                                 const float* filter,
                                                 int filter_size) {
    extern __shared__ float tile[];

    const int radius = filter_size / 2;
    const int shared_width = blockDim.x + 2 * radius;
    const int shared_height = blockDim.y + 2 * radius;
    const int block_origin_x = blockIdx.x * blockDim.x;
    const int block_origin_y = blockIdx.y * blockDim.y;

    for (int local_y = threadIdx.y; local_y < shared_height; local_y += blockDim.y) {
        const int image_y = block_origin_y + local_y - radius;

        for (int local_x = threadIdx.x; local_x < shared_width; local_x += blockDim.x) {
            const int image_x = block_origin_x + local_x - radius;
            const int shared_index = local_y * shared_width + local_x;

            if (image_x >= 0 && image_x < width && image_y >= 0 && image_y < height) {
                tile[shared_index] = input[image_y * width + image_x];
            } else {
                tile[shared_index] = 0.0f;
            }
        }
    }

    __syncthreads();

    const int x = block_origin_x + threadIdx.x;
    const int y = block_origin_y + threadIdx.y;

    if (x >= width || y >= height) {
        return;
    }

    float sum = 0.0f;
    for (int fy = 0; fy < filter_size; ++fy) {
        for (int fx = 0; fx < filter_size; ++fx) {
            const float image_value = tile[(threadIdx.y + fy) * shared_width + threadIdx.x + fx];
            const float filter_value = filter[fy * filter_size + fx];
            sum += image_value * filter_value;
        }
    }

    output[y * width + x] = sum;
}

__global__ void convolution_shared_constant_filter_kernel(const float* input,
                                                          float* output,
                                                          int width,
                                                          int height,
                                                          int filter_size) {
    extern __shared__ float tile[];

    const int radius = filter_size / 2;
    const int shared_width = blockDim.x + 2 * radius;
    const int shared_height = blockDim.y + 2 * radius;
    const int block_origin_x = blockIdx.x * blockDim.x;
    const int block_origin_y = blockIdx.y * blockDim.y;

    for (int local_y = threadIdx.y; local_y < shared_height; local_y += blockDim.y) {
        const int image_y = block_origin_y + local_y - radius;

        for (int local_x = threadIdx.x; local_x < shared_width; local_x += blockDim.x) {
            const int image_x = block_origin_x + local_x - radius;
            const int shared_index = local_y * shared_width + local_x;

            if (image_x >= 0 && image_x < width && image_y >= 0 && image_y < height) {
                tile[shared_index] = input[image_y * width + image_x];
            } else {
                tile[shared_index] = 0.0f;
            }
        }
    }

    __syncthreads();

    const int x = block_origin_x + threadIdx.x;
    const int y = block_origin_y + threadIdx.y;

    if (x >= width || y >= height) {
        return;
    }

    float sum = 0.0f;
    for (int fy = 0; fy < filter_size; ++fy) {
        for (int fx = 0; fx < filter_size; ++fx) {
            const float image_value = tile[(threadIdx.y + fy) * shared_width + threadIdx.x + fx];
            const float filter_value = c_filter[fy * filter_size + fx];
            sum += image_value * filter_value;
        }
    }

    output[y * width + x] = sum;
}

__device__ float compute_direct_pixel(const float* input,
                                      int width,
                                      int height,
                                      const float* filter,
                                      int filter_size,
                                      int x,
                                      int y) {
    const int radius = filter_size / 2;
    float sum = 0.0f;

    for (int fy = 0; fy < filter_size; ++fy) {
        const int image_y = y + fy - radius;
        if (image_y < 0 || image_y >= height) {
            continue;
        }

        for (int fx = 0; fx < filter_size; ++fx) {
            const int image_x = x + fx - radius;
            if (image_x < 0 || image_x >= width) {
                continue;
            }

            sum += input[image_y * width + image_x] * filter[fy * filter_size + fx];
        }
    }

    return sum;
}

__global__ void convolution_multi_output_kernel(const float* input,
                                                float* output,
                                                int width,
                                                int height,
                                                const float* filter,
                                                int filter_size) {
    const int x0 = (blockIdx.x * blockDim.x + threadIdx.x) * 2;
    const int x1 = x0 + 1;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x0 >= width || y >= height) {
        return;
    }

    output[y * width + x0] = compute_direct_pixel(input, width, height, filter, filter_size, x0, y);
    if (x1 < width) {
        output[y * width + x1] = compute_direct_pixel(input, width, height, filter, filter_size, x1, y);
    }
}

__global__ void convolution_register_tiled_kernel(const float* input,
                                                  float* output,
                                                  int width,
                                                  int height,
                                                  const float* filter,
                                                  int filter_size) {
    const int x0 = (blockIdx.x * blockDim.x + threadIdx.x) * 2;
    const int x1 = x0 + 1;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x0 >= width || y >= height) {
        return;
    }

    const int radius = filter_size / 2;
    float sum0 = 0.0f;
    float sum1 = 0.0f;

    for (int fy = 0; fy < filter_size; ++fy) {
        const int image_y = y + fy - radius;
        if (image_y < 0 || image_y >= height) {
            continue;
        }

        for (int fx = 0; fx < filter_size; ++fx) {
            const float filter_value = filter[fy * filter_size + fx];

            const int image_x0 = x0 + fx - radius;
            if (image_x0 >= 0 && image_x0 < width) {
                sum0 += input[image_y * width + image_x0] * filter_value;
            }

            const int image_x1 = x1 + fx - radius;
            if (x1 < width && image_x1 >= 0 && image_x1 < width) {
                sum1 += input[image_y * width + image_x1] * filter_value;
            }
        }
    }

    output[y * width + x0] = sum0;
    if (x1 < width) {
        output[y * width + x1] = sum1;
    }
}

__global__ void convolution_separable_horizontal_kernel(const float* input,
                                                        float* intermediate,
                                                        int width,
                                                        int height,
                                                        const float* filter_1d,
                                                        int filter_size) {
    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) {
        return;
    }

    const int radius = filter_size / 2;
    float sum = 0.0f;

    for (int fx = 0; fx < filter_size; ++fx) {
        const int image_x = x + fx - radius;
        if (image_x >= 0 && image_x < width) {
            sum += input[y * width + image_x] * filter_1d[fx];
        }
    }

    intermediate[y * width + x] = sum;
}

__global__ void convolution_separable_vertical_kernel(const float* intermediate,
                                                      float* output,
                                                      int width,
                                                      int height,
                                                      const float* filter_1d,
                                                      int filter_size) {
    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) {
        return;
    }

    const int radius = filter_size / 2;
    float sum = 0.0f;

    for (int fy = 0; fy < filter_size; ++fy) {
        const int image_y = y + fy - radius;
        if (image_y >= 0 && image_y < height) {
            sum += intermediate[image_y * width + x] * filter_1d[fy];
        }
    }

    output[y * width + x] = sum;
}

void launch_kernel(KernelKind kind,
                   const float* d_input,
                   float* d_output,
                   int width,
                   int height,
                   const float* d_filter,
                   int filter_size,
                   int block_width,
                   int block_height) {
    const dim3 block(block_width, block_height);
    const int outputs_per_thread_x = (kind == KernelKind::MultiOutput ||
                                      kind == KernelKind::RegisterTiled)
                                         ? 2
                                         : 1;
    const dim3 grid((width + block.x * outputs_per_thread_x - 1) /
                        (block.x * outputs_per_thread_x),
                    (height + block.y - 1) / block.y);

    switch (kind) {
        case KernelKind::NaiveGlobalMemory:
            convolution_naive_kernel<<<grid, block>>>(d_input, d_output, width, height, d_filter, filter_size);
            break;
        case KernelKind::SharedMemoryTiled: {
            const int radius = filter_size / 2;
            const int shared_width = static_cast<int>(block.x) + 2 * radius;
            const int shared_height = static_cast<int>(block.y) + 2 * radius;
            const size_t shared_bytes = static_cast<size_t>(shared_width * shared_height) * sizeof(float);
            convolution_shared_memory_kernel<<<grid, block, shared_bytes>>>(
                d_input, d_output, width, height, d_filter, filter_size);
            break;
        }
        case KernelKind::SharedConstantFilter: {
            const int radius = filter_size / 2;
            const int shared_width = static_cast<int>(block.x) + 2 * radius;
            const int shared_height = static_cast<int>(block.y) + 2 * radius;
            const size_t shared_bytes = static_cast<size_t>(shared_width * shared_height) * sizeof(float);
            convolution_shared_constant_filter_kernel<<<grid, block, shared_bytes>>>(
                d_input, d_output, width, height, filter_size);
            break;
        }
        case KernelKind::MultiOutput:
            convolution_multi_output_kernel<<<grid, block>>>(
                d_input, d_output, width, height, d_filter, filter_size);
            break;
        case KernelKind::RegisterTiled:
            convolution_register_tiled_kernel<<<grid, block>>>(
                d_input, d_output, width, height, d_filter, filter_size);
            break;
    }
}

void run_convolution(KernelKind kind,
                     const std::vector<float>& input,
                     std::vector<float>& output,
                     int width,
                     int height,
                     const std::vector<float>& filter,
                     int filter_size,
                     int block_width,
                     int block_height,
                     int warmup_count,
                     int repeat_count,
                     CudaTiming& timing) {
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
    }
    if (block_width <= 0 || block_height <= 0 || block_width * block_height > 1024) {
        throw std::invalid_argument("Block dimensions must be positive and contain at most 1024 threads.");
    }
    if (input.size() != static_cast<size_t>(width * height)) {
        throw std::invalid_argument("Input image size does not match width * height.");
    }
    if (filter.size() != static_cast<size_t>(filter_size * filter_size)) {
        throw std::invalid_argument("Filter size does not match filter_size * filter_size.");
    }
    if (kind == KernelKind::SharedConstantFilter &&
        filter.size() > static_cast<size_t>(kMaxConstantFilterElements)) {
        throw std::invalid_argument("Constant-memory filter version supports filters up to 11x11.");
    }

    output.assign(static_cast<size_t>(width * height), 0.0f);
    timing = {};
    warmup_count = std::max(warmup_count, 0);
    repeat_count = std::max(repeat_count, 1);

    const size_t image_bytes = input.size() * sizeof(float);
    const size_t filter_bytes = filter.size() * sizeof(float);

    float* d_input = nullptr;
    float* d_output = nullptr;
    float* d_filter = nullptr;
    cudaEvent_t start = nullptr;
    cudaEvent_t stop = nullptr;

    auto phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_input), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_output), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_filter), filter_bytes));
    auto phase_stop = std::chrono::high_resolution_clock::now();
    timing.allocation_time_ms = elapsed_ms(phase_start, phase_stop);

    phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(d_input, input.data(), image_bytes, cudaMemcpyHostToDevice));
    if (kind == KernelKind::SharedConstantFilter) {
        CUDA_CHECK(cudaMemcpyToSymbol(c_filter, filter.data(), filter_bytes));
    } else {
        CUDA_CHECK(cudaMemcpy(d_filter, filter.data(), filter_bytes, cudaMemcpyHostToDevice));
    }
    phase_stop = std::chrono::high_resolution_clock::now();
    timing.host_to_device_time_ms = elapsed_ms(phase_start, phase_stop);

    for (int warmup = 0; warmup < warmup_count; ++warmup) {
        launch_kernel(kind, d_input, d_output, width, height, d_filter, filter_size, block_width, block_height);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    std::vector<double> kernel_samples;
    kernel_samples.reserve(static_cast<size_t>(repeat_count));
    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        CUDA_CHECK(cudaEventRecord(start));
        launch_kernel(kind, d_input, d_output, width, height, d_filter, filter_size, block_width, block_height);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));

        float sample_ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&sample_ms, start, stop));
        kernel_samples.push_back(static_cast<double>(sample_ms));
    }
    timing.kernel_stats = compute_timing_stats(kernel_samples);
    timing.kernel_time_ms = timing.kernel_stats.average_ms;

    phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(output.data(), d_output, image_bytes, cudaMemcpyDeviceToHost));
    phase_stop = std::chrono::high_resolution_clock::now();
    timing.device_to_host_time_ms = elapsed_ms(phase_start, phase_stop);

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));

    phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaFree(d_filter));
    CUDA_CHECK(cudaFree(d_output));
    CUDA_CHECK(cudaFree(d_input));
    phase_stop = std::chrono::high_resolution_clock::now();
    timing.free_time_ms = elapsed_ms(phase_start, phase_stop);

    const double fixed_overhead_ms = timing.allocation_time_ms +
                                     timing.host_to_device_time_ms +
                                     timing.device_to_host_time_ms +
                                     timing.free_time_ms;
    std::vector<double> total_samples;
    total_samples.reserve(kernel_samples.size());
    for (const double kernel_sample : kernel_samples) {
        total_samples.push_back(fixed_overhead_ms + kernel_sample);
    }

    timing.total_stats = compute_timing_stats(total_samples);
    timing.total_time_ms = timing.total_stats.average_ms;
}

void launch_separable_kernels(const float* d_input,
                              float* d_intermediate,
                              float* d_output,
                              int width,
                              int height,
                              const float* d_filter_1d,
                              int filter_size,
                              int block_width,
                              int block_height) {
    const dim3 block(block_width, block_height);
    const dim3 grid((width + block.x - 1) / block.x,
                    (height + block.y - 1) / block.y);

    convolution_separable_horizontal_kernel<<<grid, block>>>(
        d_input, d_intermediate, width, height, d_filter_1d, filter_size);
    convolution_separable_vertical_kernel<<<grid, block>>>(
        d_intermediate, d_output, width, height, d_filter_1d, filter_size);
}

}  // namespace

void convolution_cuda_naive(const std::vector<float>& input,
                            std::vector<float>& output,
                            int width,
                            int height,
                            const std::vector<float>& filter,
                            int filter_size,
                            int block_width,
                            int block_height,
                            int warmup_count,
                            int repeat_count,
                            CudaTiming& timing) {
    run_convolution(KernelKind::NaiveGlobalMemory,
                    input,
                    output,
                    width,
                    height,
                    filter,
                    filter_size,
                    block_width,
                    block_height,
                    warmup_count,
                    repeat_count,
                    timing);
}

void convolution_cuda_shared_memory_tiled(const std::vector<float>& input,
                                          std::vector<float>& output,
                                          int width,
                                          int height,
                                          const std::vector<float>& filter,
                                          int filter_size,
                                          int block_width,
                                          int block_height,
                                          int warmup_count,
                                          int repeat_count,
                                          CudaTiming& timing) {
    run_convolution(KernelKind::SharedMemoryTiled,
                    input,
                    output,
                    width,
                    height,
                    filter,
                    filter_size,
                    block_width,
                    block_height,
                    warmup_count,
                    repeat_count,
                    timing);
}

void convolution_cuda_shared_constant_filter(const std::vector<float>& input,
                                             std::vector<float>& output,
                                             int width,
                                             int height,
                                             const std::vector<float>& filter,
                                             int filter_size,
                                             int block_width,
                                             int block_height,
                                             int warmup_count,
                                             int repeat_count,
                                             CudaTiming& timing) {
    run_convolution(KernelKind::SharedConstantFilter,
                    input,
                    output,
                    width,
                    height,
                    filter,
                    filter_size,
                    block_width,
                    block_height,
                    warmup_count,
                    repeat_count,
                    timing);
}

void convolution_cuda_multi_output(const std::vector<float>& input,
                                   std::vector<float>& output,
                                   int width,
                                   int height,
                                   const std::vector<float>& filter,
                                   int filter_size,
                                   int block_width,
                                   int block_height,
                                   int warmup_count,
                                   int repeat_count,
                                   CudaTiming& timing) {
    run_convolution(KernelKind::MultiOutput,
                    input,
                    output,
                    width,
                    height,
                    filter,
                    filter_size,
                    block_width,
                    block_height,
                    warmup_count,
                    repeat_count,
                    timing);
}

void convolution_cuda_register_tiled(const std::vector<float>& input,
                                     std::vector<float>& output,
                                     int width,
                                     int height,
                                     const std::vector<float>& filter,
                                     int filter_size,
                                     int block_width,
                                     int block_height,
                                     int warmup_count,
                                     int repeat_count,
                                     CudaTiming& timing) {
    run_convolution(KernelKind::RegisterTiled,
                    input,
                    output,
                    width,
                    height,
                    filter,
                    filter_size,
                    block_width,
                    block_height,
                    warmup_count,
                    repeat_count,
                    timing);
}

void convolution_cuda_separable(const std::vector<float>& input,
                                std::vector<float>& output,
                                int width,
                                int height,
                                const std::vector<float>& filter_1d,
                                int filter_size,
                                int block_width,
                                int block_height,
                                int warmup_count,
                                int repeat_count,
                                CudaTiming& timing) {
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
    }
    if (block_width <= 0 || block_height <= 0 || block_width * block_height > 1024) {
        throw std::invalid_argument("Block dimensions must be positive and contain at most 1024 threads.");
    }
    if (input.size() != static_cast<size_t>(width * height)) {
        throw std::invalid_argument("Input image size does not match width * height.");
    }
    if (filter_1d.size() != static_cast<size_t>(filter_size)) {
        throw std::invalid_argument("1D filter size does not match filter_size.");
    }

    output.assign(static_cast<size_t>(width * height), 0.0f);
    timing = {};
    warmup_count = std::max(warmup_count, 0);
    repeat_count = std::max(repeat_count, 1);

    const size_t image_bytes = input.size() * sizeof(float);
    const size_t filter_bytes = static_cast<size_t>(filter_size) * sizeof(float);

    float* d_input = nullptr;
    float* d_intermediate = nullptr;
    float* d_output = nullptr;
    float* d_filter_1d = nullptr;
    cudaEvent_t start = nullptr;
    cudaEvent_t stop = nullptr;

    auto phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_input), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_intermediate), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_output), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_filter_1d), filter_bytes));
    auto phase_stop = std::chrono::high_resolution_clock::now();
    timing.allocation_time_ms = elapsed_ms(phase_start, phase_stop);

    phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(d_input, input.data(), image_bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_filter_1d, filter_1d.data(), filter_bytes, cudaMemcpyHostToDevice));
    phase_stop = std::chrono::high_resolution_clock::now();
    timing.host_to_device_time_ms = elapsed_ms(phase_start, phase_stop);

    for (int warmup = 0; warmup < warmup_count; ++warmup) {
        launch_separable_kernels(d_input, d_intermediate, d_output, width, height, d_filter_1d, filter_size, block_width, block_height);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    std::vector<double> kernel_samples;
    kernel_samples.reserve(static_cast<size_t>(repeat_count));
    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        CUDA_CHECK(cudaEventRecord(start));
        launch_separable_kernels(d_input, d_intermediate, d_output, width, height, d_filter_1d, filter_size, block_width, block_height);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));

        float sample_ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&sample_ms, start, stop));
        kernel_samples.push_back(static_cast<double>(sample_ms));
    }
    timing.kernel_stats = compute_timing_stats(kernel_samples);
    timing.kernel_time_ms = timing.kernel_stats.average_ms;

    phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaMemcpy(output.data(), d_output, image_bytes, cudaMemcpyDeviceToHost));
    phase_stop = std::chrono::high_resolution_clock::now();
    timing.device_to_host_time_ms = elapsed_ms(phase_start, phase_stop);

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));

    phase_start = std::chrono::high_resolution_clock::now();
    CUDA_CHECK(cudaFree(d_filter_1d));
    CUDA_CHECK(cudaFree(d_output));
    CUDA_CHECK(cudaFree(d_intermediate));
    CUDA_CHECK(cudaFree(d_input));
    phase_stop = std::chrono::high_resolution_clock::now();
    timing.free_time_ms = elapsed_ms(phase_start, phase_stop);

    const double fixed_overhead_ms = timing.allocation_time_ms +
                                     timing.host_to_device_time_ms +
                                     timing.device_to_host_time_ms +
                                     timing.free_time_ms;
    std::vector<double> total_samples;
    total_samples.reserve(kernel_samples.size());
    for (const double kernel_sample : kernel_samples) {
        total_samples.push_back(fixed_overhead_ms + kernel_sample);
    }

    timing.total_stats = compute_timing_stats(total_samples);
    timing.total_time_ms = timing.total_stats.average_ms;
}

std::string get_cuda_device_name() {
    int device = 0;
    CUDA_CHECK(cudaGetDevice(&device));

    cudaDeviceProp properties{};
    CUDA_CHECK(cudaGetDeviceProperties(&properties, device));
    CUDA_CHECK(cudaFree(nullptr));
    return properties.name;
}
