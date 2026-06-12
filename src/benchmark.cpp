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
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>

namespace {

bool should_run_version(const std::set<std::string>& requested_versions,
                        const std::string& version) {
    return requested_versions.count("all") > 0 ||
           requested_versions.count(version) > 0;
}

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

std::uint64_t estimate_operation_count(const BenchmarkCase& benchmark_case,
                                       const std::string& version) {
    const std::uint64_t pixels = static_cast<std::uint64_t>(benchmark_case.image_width) *
                                 static_cast<std::uint64_t>(benchmark_case.image_height);
    const std::uint64_t filter_size = static_cast<std::uint64_t>(benchmark_case.filter_size);

    if (version == "cuda_separable") {
        return pixels * filter_size * 2ULL * 2ULL;
    }

    return pixels * filter_size * filter_size * 2ULL;
}

double calculate_gflops(std::uint64_t operations, double time_ms) {
    if (operations == 0 || time_ms <= 0.0) {
        return 0.0;
    }

    return static_cast<double>(operations) / (time_ms * 1.0e6);
}

BenchmarkResult make_result(const BenchmarkCase& benchmark_case,
                            const std::string& version,
                            const std::string& device_name,
                            const BlockSize& block_size,
                            int repeat_count,
                            const TimingStats& cpu_stats,
                            const CudaTiming& gpu_timing,
                            const CorrectnessMetrics& correctness) {
    BenchmarkResult result;
    result.image_width = benchmark_case.image_width;
    result.image_height = benchmark_case.image_height;
    result.filter_size = benchmark_case.filter_size;
    result.filter_type = benchmark_case.filter_type;
    result.version = version;
    result.device_name = device_name;
    result.block_width = block_size.width;
    result.block_height = block_size.height;
    result.repeat_count = repeat_count;
    result.estimated_operations = estimate_operation_count(benchmark_case, version);
    result.cpu_time_ms = cpu_stats.average_ms;
    result.cpu_min_time_ms = cpu_stats.min_ms;
    result.cpu_max_time_ms = cpu_stats.max_ms;
    result.cpu_stddev_time_ms = cpu_stats.stddev_ms;
    result.gpu_kernel_time_ms = gpu_timing.kernel_time_ms;
    result.gpu_kernel_min_time_ms = gpu_timing.kernel_stats.min_ms;
    result.gpu_kernel_max_time_ms = gpu_timing.kernel_stats.max_ms;
    result.gpu_kernel_stddev_time_ms = gpu_timing.kernel_stats.stddev_ms;
    result.gpu_total_time_ms = gpu_timing.total_time_ms;
    result.gpu_total_min_time_ms = gpu_timing.total_stats.min_ms;
    result.gpu_total_max_time_ms = gpu_timing.total_stats.max_ms;
    result.gpu_total_stddev_time_ms = gpu_timing.total_stats.stddev_ms;
    result.gpu_allocation_time_ms = gpu_timing.allocation_time_ms;
    result.gpu_host_to_device_time_ms = gpu_timing.host_to_device_time_ms;
    result.gpu_device_to_host_time_ms = gpu_timing.device_to_host_time_ms;
    result.gpu_free_time_ms = gpu_timing.free_time_ms;
    result.kernel_speedup = gpu_timing.kernel_time_ms > 0.0f
                                ? cpu_stats.average_ms / gpu_timing.kernel_time_ms
                                : 0.0;
    result.total_speedup = gpu_timing.total_time_ms > 0.0
                               ? cpu_stats.average_ms / gpu_timing.total_time_ms
                               : 0.0;
    result.cpu_gflops = calculate_gflops(result.estimated_operations, result.cpu_time_ms);
    result.gpu_kernel_gflops = calculate_gflops(result.estimated_operations,
                                                result.gpu_kernel_time_ms);
    result.max_abs_error = correctness.max_abs_error;
    result.mean_abs_error = correctness.mean_abs_error;
    result.passed = correctness.passed;
    return result;
}

void print_result(const BenchmarkResult& result) {
    std::cout << "Image " << result.image_width << "x"
              << result.image_height
              << ", filter " << result.filter_size << "x"
              << result.filter_size
              << " " << result.filter_type
              << ", block " << result.block_width << "x"
              << result.block_height
              << ", version " << result.version
              << ": CPU avg " << result.cpu_time_ms << " ms (stddev "
              << result.cpu_stddev_time_ms << "), CUDA kernel avg "
              << result.gpu_kernel_time_ms << " ms (stddev "
              << result.gpu_kernel_stddev_time_ms << "), CUDA total "
              << result.gpu_total_time_ms << " ms, kernel speedup "
              << result.kernel_speedup << ", total speedup "
              << result.total_speedup << ", CUDA kernel GFLOP/s "
              << result.gpu_kernel_gflops << ", max error "
              << result.max_abs_error << ", mean error "
              << result.mean_abs_error << ", "
              << (result.passed ? "PASSED" : "FAILED")
              << '\n';
}

bool has_version_alias(const std::set<std::string>& requested_versions,
                       const std::string& alias,
                       const std::string& canonical_version) {
    return should_run_version(requested_versions, canonical_version) ||
           requested_versions.count(alias) > 0;
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

TimingStats run_cpu_repeats(const std::vector<float>& input,
                            std::vector<float>& output,
                            int width,
                            int height,
                            const std::vector<float>& filter,
                            int filter_size,
                            int repeat_count) {
    repeat_count = std::max(repeat_count, 1);
    std::vector<double> samples;
    samples.reserve(static_cast<size_t>(repeat_count));

    for (int repeat = 0; repeat < repeat_count; ++repeat) {
        const auto cpu_start = std::chrono::high_resolution_clock::now();
        convolution_cpu(input, output, width, height, filter, filter_size);
        const auto cpu_stop = std::chrono::high_resolution_clock::now();
        samples.push_back(std::chrono::duration<double, std::milli>(
            cpu_stop - cpu_start).count());
    }

    return compute_timing_stats(samples);
}

std::vector<BenchmarkResult> run_benchmarks(const BenchmarkOptions& options) {
    std::vector<BenchmarkCase> cases;
    for (const int image_size : options.image_sizes) {
        for (const int filter_size : options.filter_sizes) {
            for (const std::string& filter_type : options.filter_types) {
                cases.push_back({image_size, image_size, filter_size, filter_type});
            }
        }
    }

    const std::set<std::string> requested_versions(options.versions.begin(),
                                                   options.versions.end());
    const std::string device_name = get_cuda_device_name();

    std::vector<BenchmarkResult> results;
    results.reserve(cases.size() * options.block_sizes.size() * 6);

    for (const BenchmarkCase& benchmark_case : cases) {
        const unsigned int seed = static_cast<unsigned int>(
            benchmark_case.image_width * 31 +
            benchmark_case.image_height * 17 +
            benchmark_case.filter_size);

        const std::vector<float> input = generate_random_image(
            benchmark_case.image_width,
            benchmark_case.image_height,
            seed);
        const FilterSpec filter_spec = generate_filter_spec(benchmark_case.filter_type,
                                                            benchmark_case.filter_size);

        std::vector<float> cpu_output;
        const TimingStats cpu_stats = run_cpu_repeats(input,
                                                      cpu_output,
                                                      benchmark_case.image_width,
                                                      benchmark_case.image_height,
                                                      filter_spec.filter_2d,
                                                      benchmark_case.filter_size,
                                                      options.repeat_count);

        const bool run_separable = filter_spec.separable &&
                                   has_version_alias(requested_versions, "separable", "cuda_separable");
        std::vector<float> cpu_separable_output;
        if (run_separable) {
            convolution_cpu_separable(input,
                                      cpu_separable_output,
                                      benchmark_case.image_width,
                                      benchmark_case.image_height,
                                      filter_spec.filter_1d,
                                      benchmark_case.filter_size);
        }

        for (const BlockSize& block_size : options.block_sizes) {
            if (has_version_alias(requested_versions, "naive", "cuda_naive_global_memory")) {
                std::vector<float> gpu_output;
                CudaTiming gpu_timing;
                convolution_cuda_naive(input,
                                       gpu_output,
                                       benchmark_case.image_width,
                                       benchmark_case.image_height,
                                       filter_spec.filter_2d,
                                       benchmark_case.filter_size,
                                       block_size.width,
                                       block_size.height,
                                       options.warmup_count,
                                       options.repeat_count,
                                       gpu_timing);

                const CorrectnessMetrics correctness = compare_outputs(
                    cpu_output,
                    gpu_output,
                    kCorrectnessTolerance);

                BenchmarkResult result = make_result(benchmark_case,
                                                     "cuda_naive_global_memory",
                                                     device_name,
                                                     block_size,
                                                     options.repeat_count,
                                                     cpu_stats,
                                                     gpu_timing,
                                                     correctness);
                results.push_back(result);
                print_result(result);
            }

            if (has_version_alias(requested_versions, "shared", "cuda_shared_memory_tiled")) {
                std::vector<float> gpu_output;
                CudaTiming gpu_timing;
                convolution_cuda_shared_memory_tiled(input,
                                                     gpu_output,
                                                     benchmark_case.image_width,
                                                     benchmark_case.image_height,
                                                     filter_spec.filter_2d,
                                                     benchmark_case.filter_size,
                                                     block_size.width,
                                                     block_size.height,
                                                     options.warmup_count,
                                                     options.repeat_count,
                                                     gpu_timing);

                const CorrectnessMetrics correctness = compare_outputs(
                    cpu_output,
                    gpu_output,
                    kCorrectnessTolerance);

                BenchmarkResult result = make_result(benchmark_case,
                                                     "cuda_shared_memory_tiled",
                                                     device_name,
                                                     block_size,
                                                     options.repeat_count,
                                                     cpu_stats,
                                                     gpu_timing,
                                                     correctness);
                results.push_back(result);
                print_result(result);
            }

            if (has_version_alias(requested_versions, "constant", "cuda_shared_constant_filter")) {
                std::vector<float> gpu_output;
                CudaTiming gpu_timing;
                convolution_cuda_shared_constant_filter(input,
                                                        gpu_output,
                                                        benchmark_case.image_width,
                                                        benchmark_case.image_height,
                                                        filter_spec.filter_2d,
                                                        benchmark_case.filter_size,
                                                        block_size.width,
                                                        block_size.height,
                                                        options.warmup_count,
                                                        options.repeat_count,
                                                        gpu_timing);

                const CorrectnessMetrics correctness = compare_outputs(
                    cpu_output,
                    gpu_output,
                    kCorrectnessTolerance);

                BenchmarkResult result = make_result(benchmark_case,
                                                     "cuda_shared_constant_filter",
                                                     device_name,
                                                     block_size,
                                                     options.repeat_count,
                                                     cpu_stats,
                                                     gpu_timing,
                                                     correctness);
                results.push_back(result);
                print_result(result);
            }

            if (has_version_alias(requested_versions, "multi", "cuda_multi_output")) {
                std::vector<float> gpu_output;
                CudaTiming gpu_timing;
                convolution_cuda_multi_output(input,
                                              gpu_output,
                                              benchmark_case.image_width,
                                              benchmark_case.image_height,
                                              filter_spec.filter_2d,
                                              benchmark_case.filter_size,
                                              block_size.width,
                                              block_size.height,
                                              options.warmup_count,
                                              options.repeat_count,
                                              gpu_timing);

                const CorrectnessMetrics correctness = compare_outputs(
                    cpu_output,
                    gpu_output,
                    kCorrectnessTolerance);

                BenchmarkResult result = make_result(benchmark_case,
                                                     "cuda_multi_output",
                                                     device_name,
                                                     block_size,
                                                     options.repeat_count,
                                                     cpu_stats,
                                                     gpu_timing,
                                                     correctness);
                results.push_back(result);
                print_result(result);
            }

            if (has_version_alias(requested_versions, "register", "cuda_register_tiled")) {
                std::vector<float> gpu_output;
                CudaTiming gpu_timing;
                convolution_cuda_register_tiled(input,
                                                gpu_output,
                                                benchmark_case.image_width,
                                                benchmark_case.image_height,
                                                filter_spec.filter_2d,
                                                benchmark_case.filter_size,
                                                block_size.width,
                                                block_size.height,
                                                options.warmup_count,
                                                options.repeat_count,
                                                gpu_timing);

                const CorrectnessMetrics correctness = compare_outputs(
                    cpu_output,
                    gpu_output,
                    kCorrectnessTolerance);

                BenchmarkResult result = make_result(benchmark_case,
                                                     "cuda_register_tiled",
                                                     device_name,
                                                     block_size,
                                                     options.repeat_count,
                                                     cpu_stats,
                                                     gpu_timing,
                                                     correctness);
                results.push_back(result);
                print_result(result);
            }

            if (run_separable) {
                std::vector<float> gpu_output;
                CudaTiming gpu_timing;
                convolution_cuda_separable(input,
                                           gpu_output,
                                           benchmark_case.image_width,
                                           benchmark_case.image_height,
                                           filter_spec.filter_1d,
                                           benchmark_case.filter_size,
                                           block_size.width,
                                           block_size.height,
                                           options.warmup_count,
                                           options.repeat_count,
                                           gpu_timing);

                const CorrectnessMetrics correctness = compare_outputs(
                    cpu_separable_output,
                    gpu_output,
                    kCorrectnessTolerance);

                BenchmarkResult result = make_result(benchmark_case,
                                                     "cuda_separable",
                                                     device_name,
                                                     block_size,
                                                     options.repeat_count,
                                                     cpu_stats,
                                                     gpu_timing,
                                                     correctness);
                results.push_back(result);
                print_result(result);
            }
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

    file << "image_width,image_height,filter_size,filter_type,version,device_name,"
         << "block_width,block_height,repeat_count,"
         << "estimated_operations,cpu_time_ms,cpu_min_time_ms,cpu_max_time_ms,"
         << "cpu_stddev_time_ms,gpu_kernel_time_ms,gpu_kernel_min_time_ms,"
         << "gpu_kernel_max_time_ms,gpu_kernel_stddev_time_ms,gpu_total_time_ms,"
         << "gpu_total_min_time_ms,gpu_total_max_time_ms,gpu_total_stddev_time_ms,"
         << "gpu_allocation_time_ms,gpu_host_to_device_time_ms,"
         << "gpu_device_to_host_time_ms,gpu_free_time_ms,kernel_speedup,"
         << "total_speedup,cpu_gflops,gpu_kernel_gflops,max_abs_error,"
         << "mean_abs_error,passed\n";

    file << std::fixed << std::setprecision(6);
    for (const BenchmarkResult& result : results) {
        file << result.image_width << ','
             << result.image_height << ','
             << result.filter_size << ','
             << result.filter_type << ','
             << result.version << ','
             << '"' << result.device_name << '"' << ','
             << result.block_width << ','
             << result.block_height << ','
             << result.repeat_count << ','
             << result.estimated_operations << ','
             << result.cpu_time_ms << ','
             << result.cpu_min_time_ms << ','
             << result.cpu_max_time_ms << ','
             << result.cpu_stddev_time_ms << ','
             << result.gpu_kernel_time_ms << ','
             << result.gpu_kernel_min_time_ms << ','
             << result.gpu_kernel_max_time_ms << ','
             << result.gpu_kernel_stddev_time_ms << ','
             << result.gpu_total_time_ms << ','
             << result.gpu_total_min_time_ms << ','
             << result.gpu_total_max_time_ms << ','
             << result.gpu_total_stddev_time_ms << ','
             << result.gpu_allocation_time_ms << ','
             << result.gpu_host_to_device_time_ms << ','
             << result.gpu_device_to_host_time_ms << ','
             << result.gpu_free_time_ms << ','
             << result.kernel_speedup << ','
             << result.total_speedup << ','
             << result.cpu_gflops << ','
             << result.gpu_kernel_gflops << ','
             << result.max_abs_error << ','
             << result.mean_abs_error << ','
             << (result.passed ? "true" : "false") << '\n';
    }
}

void write_best_versions_csv(const std::string& path,
                             const std::vector<BenchmarkResult>& results) {
    struct BestVersions {
        const BenchmarkResult* kernel = nullptr;
        const BenchmarkResult* total = nullptr;
        bool all_passed = true;
    };

    struct SummaryKey {
        int image_width = 0;
        int filter_size = 0;
        std::string filter_type;

        bool operator<(const SummaryKey& other) const {
            if (image_width != other.image_width) {
                return image_width < other.image_width;
            }
            if (filter_size != other.filter_size) {
                return filter_size < other.filter_size;
            }
            return filter_type < other.filter_type;
        }
    };

    std::map<SummaryKey, BestVersions> grouped;
    for (const BenchmarkResult& result : results) {
        auto& best = grouped[{result.image_width, result.filter_size, result.filter_type}];
        best.all_passed = best.all_passed && result.passed;

        if (result.passed &&
            (best.kernel == nullptr ||
             result.gpu_kernel_time_ms < best.kernel->gpu_kernel_time_ms)) {
            best.kernel = &result;
        }
        if (result.passed &&
            (best.total == nullptr ||
             result.gpu_total_time_ms < best.total->gpu_total_time_ms)) {
            best.total = &result;
        }
    }

    std::ofstream file(path);
    if (!file) {
        throw std::runtime_error("Failed to open CSV output file: " + path);
    }

    file << "image_width,image_height,filter_size,filter_type,best_kernel_time_version,"
         << "best_kernel_block_width,best_kernel_block_height,best_total_time_version,"
         << "best_total_block_width,best_total_block_height,best_kernel_speedup,best_total_speedup,"
         << "correctness_status\n";
    file << std::fixed << std::setprecision(6);

    for (const auto& [key, best] : grouped) {
        const int image_width = key.image_width;
        const int filter_size = key.filter_size;
        const BenchmarkResult* representative = best.kernel != nullptr
                                                    ? best.kernel
                                                    : best.total;
        const int image_height = representative != nullptr
                                     ? representative->image_height
                                     : image_width;

        file << image_width << ','
             << image_height << ','
             << filter_size << ','
             << key.filter_type << ','
             << (best.kernel != nullptr ? best.kernel->version : "none") << ','
             << (best.kernel != nullptr ? best.kernel->block_width : 0) << ','
             << (best.kernel != nullptr ? best.kernel->block_height : 0) << ','
             << (best.total != nullptr ? best.total->version : "none") << ','
             << (best.total != nullptr ? best.total->block_width : 0) << ','
             << (best.total != nullptr ? best.total->block_height : 0) << ','
             << (best.kernel != nullptr ? best.kernel->kernel_speedup : 0.0) << ','
             << (best.total != nullptr ? best.total->total_speedup : 0.0) << ','
             << (best.all_passed ? "passed" : "failed") << '\n';
    }
}
