#include "convolution_cuda.cuh"

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <stdexcept>

namespace {

constexpr int kBlockSizeX = 16;
constexpr int kBlockSizeY = 16;

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

void launch_naive_kernel(const float* d_input,
                         float* d_output,
                         int width,
                         int height,
                         const float* d_filter,
                         int filter_size) {
    const dim3 block(kBlockSizeX, kBlockSizeY);
    const dim3 grid((width + block.x - 1) / block.x,
                    (height + block.y - 1) / block.y);

    convolution_naive_kernel<<<grid, block>>>(d_input, d_output, width, height, d_filter, filter_size);
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
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
    }
    if (input.size() != static_cast<size_t>(width * height)) {
        throw std::invalid_argument("Input image size does not match width * height.");
    }
    if (filter.size() != static_cast<size_t>(filter_size * filter_size)) {
        throw std::invalid_argument("Filter size does not match filter_size * filter_size.");
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
    CUDA_CHECK(cudaMemcpy(d_filter, filter.data(), filter_bytes, cudaMemcpyHostToDevice));

    for (int warmup = 0; warmup < warmup_count; ++warmup) {
        launch_naive_kernel(d_input, d_output, width, height, d_filter, filter_size);
        CUDA_CHECK(cudaGetLastError());
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    CUDA_CHECK(cudaEventRecord(start));
    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        launch_naive_kernel(d_input, d_output, width, height, d_filter, filter_size);
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

std::string get_cuda_device_name() {
    int device = 0;
    CUDA_CHECK(cudaGetDevice(&device));

    cudaDeviceProp properties{};
    CUDA_CHECK(cudaGetDeviceProperties(&properties, device));
    return properties.name;
}
