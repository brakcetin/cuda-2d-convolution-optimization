#include "benchmark.h"

#include "convolution_cpu.h"
#include "convolution_cuda.cuh"
#include "filters.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>

CorrectnessMetrics compare_outputs(const std::vector<float>& reference,
                                   const std::vector<float>& candidate,
                                   float tolerance) {
    if (reference.size() != candidate.size()) {
        throw std::invalid_argument("Output vectors must have the same size.");
    }

    CorrectnessMetrics metrics;
    double total_abs_error = 0.0;

    for (size_t i = 0; i < reference.size(); ++i) {
        const float abs_error = std::fabs(reference[i] - candidate[i]);
        metrics.max_abs_error = std::max(metrics.max_abs_error, abs_error);
        total_abs_error += static_cast<double>(abs_error);
    }

    metrics.mean_abs_error = reference.empty()
                                 ? 0.0
                                 : total_abs_error / static_cast<double>(reference.size());
    metrics.passed = metrics.max_abs_error <= tolerance;
    return metrics;
}

std::vector<BenchmarkResult> run_benchmarks() {
    const std::vector<BenchmarkCase> cases = {
        {512, 512, 3},
        {512, 512, 5},
        {1024, 1024, 3},
        {1024, 1024, 5},
    };

    std::vector<BenchmarkResult> results;
    results.reserve(cases.size());

    for (const BenchmarkCase& benchmark_case : cases) {
        const unsigned int seed = static_cast<unsigned int>(
            benchmark_case.image_width * 31 +
            benchmark_case.image_height * 17 +
            benchmark_case.filter_size);

        const std::vector<float> input = generate_random_image(
            benchmark_case.image_width,
            benchmark_case.image_height,
            seed);
        const std::vector<float> filter = generate_normalized_filter(benchmark_case.filter_size);

        std::vector<float> cpu_output;
        const auto cpu_start = std::chrono::high_resolution_clock::now();
        convolution_cpu(input,
                        cpu_output,
                        benchmark_case.image_width,
                        benchmark_case.image_height,
                        filter,
                        benchmark_case.filter_size);
        const auto cpu_stop = std::chrono::high_resolution_clock::now();

        const double cpu_time_ms = std::chrono::duration<double, std::milli>(
            cpu_stop - cpu_start).count();

        std::vector<float> gpu_output;
        float gpu_kernel_time_ms = 0.0f;
        convolution_cuda_naive(input,
                               gpu_output,
                               benchmark_case.image_width,
                               benchmark_case.image_height,
                               filter,
                               benchmark_case.filter_size,
                               gpu_kernel_time_ms);

        const CorrectnessMetrics correctness = compare_outputs(
            cpu_output,
            gpu_output,
            kCorrectnessTolerance);

        BenchmarkResult result;
        result.image_width = benchmark_case.image_width;
        result.image_height = benchmark_case.image_height;
        result.filter_size = benchmark_case.filter_size;
        result.version = "cuda_naive_global_memory";
        result.cpu_time_ms = cpu_time_ms;
        result.gpu_kernel_time_ms = gpu_kernel_time_ms;
        result.speedup = gpu_kernel_time_ms > 0.0f
                             ? cpu_time_ms / static_cast<double>(gpu_kernel_time_ms)
                             : 0.0;
        result.max_abs_error = correctness.max_abs_error;
        result.mean_abs_error = correctness.mean_abs_error;
        result.passed = correctness.passed;
        results.push_back(result);

        std::cout << "Image " << benchmark_case.image_width << "x"
                  << benchmark_case.image_height
                  << ", filter " << benchmark_case.filter_size << "x"
                  << benchmark_case.filter_size
                  << ": CPU " << cpu_time_ms << " ms, CUDA kernel "
                  << gpu_kernel_time_ms << " ms, speedup " << result.speedup
                  << ", max error " << correctness.max_abs_error
                  << ", mean error " << correctness.mean_abs_error
                  << ", " << (correctness.passed ? "PASSED" : "FAILED")
                  << '\n';
    }

    return results;
}

void write_results_csv(const std::string& path,
                       const std::vector<BenchmarkResult>& results) {
    std::ofstream file(path);
    if (!file) {
        throw std::runtime_error("Failed to open CSV output file: " + path);
    }

    file << "image_width,image_height,filter_size,version,cpu_time_ms,"
         << "gpu_kernel_time_ms,speedup,max_abs_error,mean_abs_error,passed\n";

    file << std::fixed << std::setprecision(6);
    for (const BenchmarkResult& result : results) {
        file << result.image_width << ','
             << result.image_height << ','
             << result.filter_size << ','
             << result.version << ','
             << result.cpu_time_ms << ','
             << result.gpu_kernel_time_ms << ','
             << result.speedup << ','
             << result.max_abs_error << ','
             << result.mean_abs_error << ','
             << (result.passed ? "true" : "false") << '\n';
    }
}
