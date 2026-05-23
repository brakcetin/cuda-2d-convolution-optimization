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
#include <set>
#include <stdexcept>

namespace {

bool should_run_version(const std::set<std::string>& requested_versions,
                        const std::string& version) {
    return requested_versions.count("all") > 0 ||
           requested_versions.count(version) > 0 ||
           requested_versions.count("naive") > 0;
}

double run_cpu_average(const std::vector<float>& input,
                       std::vector<float>& output,
                       int width,
                       int height,
                       const std::vector<float>& filter,
                       int filter_size,
                       int repeat_count) {
    repeat_count = std::max(repeat_count, 1);
    double total_time_ms = 0.0;

    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        const auto cpu_start = std::chrono::high_resolution_clock::now();
        convolution_cpu(input, output, width, height, filter, filter_size);
        const auto cpu_stop = std::chrono::high_resolution_clock::now();
        total_time_ms += std::chrono::duration<double, std::milli>(
            cpu_stop - cpu_start).count();
    }

    return total_time_ms / static_cast<double>(repeat_count);
}

}  // namespace

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

std::vector<BenchmarkResult> run_benchmarks(const BenchmarkOptions& options) {
    std::vector<BenchmarkCase> cases;
    for (const int image_size : options.image_sizes) {
        for (const int filter_size : options.filter_sizes) {
            cases.push_back({image_size, image_size, filter_size});
        }
    }

    const std::set<std::string> requested_versions(options.versions.begin(),
                                                   options.versions.end());
    const std::string device_name = get_cuda_device_name();

    std::vector<BenchmarkResult> results;
    results.reserve(cases.size() * 4);

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
        const double cpu_time_ms = run_cpu_average(input,
                                                   cpu_output,
                                                   benchmark_case.image_width,
                                                   benchmark_case.image_height,
                                                   filter,
                                                   benchmark_case.filter_size,
                                                   options.repeat_count);

        if (should_run_version(requested_versions, "cuda_naive_global_memory")) {
            std::vector<float> gpu_output;
            CudaTiming gpu_timing;
            convolution_cuda_naive(input,
                                   gpu_output,
                                   benchmark_case.image_width,
                                   benchmark_case.image_height,
                                   filter,
                                   benchmark_case.filter_size,
                                   options.warmup_count,
                                   options.repeat_count,
                                   gpu_timing);

            const CorrectnessMetrics correctness = compare_outputs(
                cpu_output,
                gpu_output,
                kCorrectnessTolerance);

            BenchmarkResult result;
            result.image_width = benchmark_case.image_width;
            result.image_height = benchmark_case.image_height;
            result.filter_size = benchmark_case.filter_size;
            result.version = "cuda_naive_global_memory";
            result.device_name = device_name;
            result.repeat_count = options.repeat_count;
            result.cpu_time_ms = cpu_time_ms;
            result.gpu_kernel_time_ms = gpu_timing.kernel_time_ms;
            result.gpu_total_time_ms = gpu_timing.total_time_ms;
            result.kernel_speedup = gpu_timing.kernel_time_ms > 0.0f
                                        ? cpu_time_ms / static_cast<double>(gpu_timing.kernel_time_ms)
                                        : 0.0;
            result.total_speedup = gpu_timing.total_time_ms > 0.0
                                       ? cpu_time_ms / gpu_timing.total_time_ms
                                       : 0.0;
            result.max_abs_error = correctness.max_abs_error;
            result.mean_abs_error = correctness.mean_abs_error;
            result.passed = correctness.passed;
            results.push_back(result);

            std::cout << "Image " << benchmark_case.image_width << "x"
                      << benchmark_case.image_height
                      << ", filter " << benchmark_case.filter_size << "x"
                      << benchmark_case.filter_size
                      << ", version " << result.version
                      << ": CPU avg " << cpu_time_ms << " ms, CUDA kernel avg "
                      << gpu_timing.kernel_time_ms << " ms, CUDA total "
                      << gpu_timing.total_time_ms << " ms, kernel speedup "
                      << result.kernel_speedup << ", total speedup "
                      << result.total_speedup << ", max error "
                      << correctness.max_abs_error << ", mean error "
                      << correctness.mean_abs_error << ", "
                      << (correctness.passed ? "PASSED" : "FAILED")
                      << '\n';
        }
    }

    return results;
}

void write_results_csv(const std::string& path,
                       const std::vector<BenchmarkResult>& results) {
    std::ofstream file(path);
    if (!file) {
        throw std::runtime_error("Failed to open CSV output file: " + path);
    }

    file << "image_width,image_height,filter_size,version,device_name,repeat_count,"
         << "cpu_time_ms,gpu_kernel_time_ms,gpu_total_time_ms,kernel_speedup,"
         << "total_speedup,max_abs_error,mean_abs_error,passed\n";

    file << std::fixed << std::setprecision(6);
    for (const BenchmarkResult& result : results) {
        file << result.image_width << ','
             << result.image_height << ','
             << result.filter_size << ','
             << result.version << ','
             << '"' << result.device_name << '"' << ','
             << result.repeat_count << ','
             << result.cpu_time_ms << ','
             << result.gpu_kernel_time_ms << ','
             << result.gpu_total_time_ms << ','
             << result.kernel_speedup << ','
             << result.total_speedup << ','
             << result.max_abs_error << ','
             << result.mean_abs_error << ','
             << (result.passed ? "true" : "false") << '\n';
    }
}
