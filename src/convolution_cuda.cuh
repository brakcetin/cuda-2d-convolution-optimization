#pragma once

#include <cstdio>
#include <cstdlib>
#include <vector>

#include <cuda_runtime.h>

#define CUDA_CHECK(call)                                                                  \
    do {                                                                                  \
        cudaError_t status = (call);                                                      \
        if (status != cudaSuccess) {                                                      \
            fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,             \
                    cudaGetErrorString(status));                                          \
            std::exit(EXIT_FAILURE);                                                      \
        }                                                                                 \
    } while (0)

void convolution_cuda_naive(const std::vector<float>& input,
                            std::vector<float>& output,
                            int width,
                            int height,
                            const std::vector<float>& filter,
                            int filter_size,
                            float& kernel_time_ms);
