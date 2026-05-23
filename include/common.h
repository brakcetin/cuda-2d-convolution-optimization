#pragma once

#include <string>

constexpr float kCorrectnessTolerance = 1.0e-4f;

struct CorrectnessMetrics {
    float max_abs_error = 0.0f;
    double mean_abs_error = 0.0;
    bool passed = false;
};

struct BenchmarkCase {
    int image_width = 0;
    int image_height = 0;
    int filter_size = 0;
};

struct BenchmarkResult {
    int image_width = 0;
    int image_height = 0;
    int filter_size = 0;
    std::string version;
    std::string device_name;
    int repeat_count = 0;
    double cpu_time_ms = 0.0;
    float gpu_kernel_time_ms = 0.0f;
    double gpu_total_time_ms = 0.0;
    double kernel_speedup = 0.0;
    double total_speedup = 0.0;
    float max_abs_error = 0.0f;
    double mean_abs_error = 0.0;
    bool passed = false;
};

struct CudaTiming {
    float kernel_time_ms = 0.0f;
    double total_time_ms = 0.0;
};
