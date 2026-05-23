#include "convolution_cuda.cuh"

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <stdexcept>

namespace {

constexpr int kBlockSizeX = 16;
constexpr int kBlockSizeY = 16;
constexpr int kMaxConstantFilterElements = 11 * 11;

__constant__ float c_filter[kMaxConstantFilterElements];

enum class KernelKind {
    NaiveGlobalMemory,
    SharedMemoryTiled,
    SharedConstantFilter,
};

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
                   int filter_size) {
    const dim3 block(kBlockSizeX, kBlockSizeY);
    const dim3 grid((width + block.x - 1) / block.x,
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
    }
}

void run_convolution(KernelKind kind,
                     const std::vector<float>& input,
                     std::vector<float>& output,
                     int width,
                     int height,
                     const std::vector<float>& filter,
                     int filter_size,
                     int warmup_count,
                     int repeat_count,
                     CudaTiming& timing) {
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
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

    const auto total_start = std::chrono::high_resolution_clock::now();

    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_input), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_output), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_filter), filter_bytes));

    CUDA_CHECK(cudaMemcpy(d_input, input.data(), image_bytes, cudaMemcpyHostToDevice));
    if (kind == KernelKind::SharedConstantFilter) {
        CUDA_CHECK(cudaMemcpyToSymbol(c_filter, filter.data(), filter_bytes));
    } else {
        CUDA_CHECK(cudaMemcpy(d_filter, filter.data(), filter_bytes, cudaMemcpyHostToDevice));
    }

    for (int warmup = 0; warmup < warmup_count; ++warmup) {
        launch_kernel(kind, d_input, d_output, width, height, d_filter, filter_size);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    CUDA_CHECK(cudaEventRecord(start));
    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        launch_kernel(kind, d_input, d_output, width, height, d_filter, filter_size);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));
    CUDA_CHECK(cudaEventElapsedTime(&timing.kernel_time_ms, start, stop));
    timing.kernel_time_ms /= static_cast<float>(repeat_count);

    CUDA_CHECK(cudaMemcpy(output.data(), d_output, image_bytes, cudaMemcpyDeviceToHost));

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_filter));
    CUDA_CHECK(cudaFree(d_output));
    CUDA_CHECK(cudaFree(d_input));

    const auto total_stop = std::chrono::high_resolution_clock::now();
    timing.total_time_ms = std::chrono::duration<double, std::milli>(
        total_stop - total_start).count();
}

void launch_separable_kernels(const float* d_input,
                              float* d_intermediate,
                              float* d_output,
                              int width,
                              int height,
                              const float* d_filter_1d,
                              int filter_size) {
    const dim3 block(kBlockSizeX, kBlockSizeY);
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
                    warmup_count,
                    repeat_count,
                    timing);
}

void convolution_cuda_separable(const std::vector<float>& input,
                                std::vector<float>& output,
                                int width,
                                int height,
                                int filter_size,
                                int warmup_count,
                                int repeat_count,
                                CudaTiming& timing) {
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
    }
    if (input.size() != static_cast<size_t>(width * height)) {
        throw std::invalid_argument("Input image size does not match width * height.");
    }

    output.assign(static_cast<size_t>(width * height), 0.0f);
    timing = {};
    warmup_count = std::max(warmup_count, 0);
    repeat_count = std::max(repeat_count, 1);

    const size_t image_bytes = input.size() * sizeof(float);
    const size_t filter_bytes = static_cast<size_t>(filter_size) * sizeof(float);
    const std::vector<float> filter_1d(static_cast<size_t>(filter_size),
                                       1.0f / static_cast<float>(filter_size));

    float* d_input = nullptr;
    float* d_intermediate = nullptr;
    float* d_output = nullptr;
    float* d_filter_1d = nullptr;
    cudaEvent_t start = nullptr;
    cudaEvent_t stop = nullptr;

    const auto total_start = std::chrono::high_resolution_clock::now();

    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_input), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_intermediate), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_output), image_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&d_filter_1d), filter_bytes));

    CUDA_CHECK(cudaMemcpy(d_input, input.data(), image_bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_filter_1d, filter_1d.data(), filter_bytes, cudaMemcpyHostToDevice));

    for (int warmup = 0; warmup < warmup_count; ++warmup) {
        launch_separable_kernels(d_input, d_intermediate, d_output, width, height, d_filter_1d, filter_size);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    CUDA_CHECK(cudaEventRecord(start));
    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        launch_separable_kernels(d_input, d_intermediate, d_output, width, height, d_filter_1d, filter_size);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));
    CUDA_CHECK(cudaEventElapsedTime(&timing.kernel_time_ms, start, stop));
    timing.kernel_time_ms /= static_cast<float>(repeat_count);

    CUDA_CHECK(cudaMemcpy(output.data(), d_output, image_bytes, cudaMemcpyDeviceToHost));

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_filter_1d));
    CUDA_CHECK(cudaFree(d_output));
    CUDA_CHECK(cudaFree(d_intermediate));
    CUDA_CHECK(cudaFree(d_input));

    const auto total_stop = std::chrono::high_resolution_clock::now();
    timing.total_time_ms = std::chrono::duration<double, std::milli>(
        total_stop - total_start).count();
}

std::string get_cuda_device_name() {
    int device = 0;
    CUDA_CHECK(cudaGetDevice(&device));

    cudaDeviceProp properties{};
    CUDA_CHECK(cudaGetDeviceProperties(&properties, device));
    return properties.name;
}
