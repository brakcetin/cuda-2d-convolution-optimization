#pragma once

#include <cstdint>
#include <string>

constexpr float kCorrectnessTolerance = 1.0e-4f;

struct TimingStats {
    double average_ms = 0.0;
    double min_ms = 0.0;
    double max_ms = 0.0;
    double stddev_ms = 0.0;
};

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
    std::uint64_t estimated_operations = 0;
    double cpu_time_ms = 0.0;
    double cpu_min_time_ms = 0.0;
    double cpu_max_time_ms = 0.0;
    double cpu_stddev_time_ms = 0.0;
    double gpu_kernel_time_ms = 0.0;
    double gpu_kernel_min_time_ms = 0.0;
    double gpu_kernel_max_time_ms = 0.0;
    double gpu_kernel_stddev_time_ms = 0.0;
    double gpu_total_time_ms = 0.0;
    double gpu_total_min_time_ms = 0.0;
    double gpu_total_max_time_ms = 0.0;
    double gpu_total_stddev_time_ms = 0.0;
    double gpu_allocation_time_ms = 0.0;
    double gpu_host_to_device_time_ms = 0.0;
    double gpu_device_to_host_time_ms = 0.0;
    double gpu_free_time_ms = 0.0;
    double kernel_speedup = 0.0;
    double total_speedup = 0.0;
    double cpu_gflops = 0.0;
    double gpu_kernel_gflops = 0.0;
    float max_abs_error = 0.0f;
    double mean_abs_error = 0.0;
    bool passed = false;
};

struct CudaTiming {
    double allocation_time_ms = 0.0;
    double host_to_device_time_ms = 0.0;
    double kernel_time_ms = 0.0;
    double device_to_host_time_ms = 0.0;
    double free_time_ms = 0.0;
    double total_time_ms = 0.0;
    TimingStats kernel_stats;
    TimingStats total_stats;
};
