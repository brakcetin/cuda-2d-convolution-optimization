#include "benchmark.h"
#include "convolution_cpu.h"
#include "convolution_cuda.cuh"
#include "filters.h"
#include "image_io.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <iostream>
#include <sstream>

namespace {

struct DemoOptions {
    bool enabled = false;
    std::string input_path;
    std::string output_path;
    std::string filter_type = "sobel";
    int filter_size = 3;
    std::string version = "cuda_shared_constant_filter";
    BlockSize block_size = {16, 16};
    bool normalize_output = true;
    int warmup_count = 1;
    int repeat_count = 5;
};

struct ProgramOptions {
    BenchmarkOptions benchmark;
    DemoOptions demo;
};

std::vector<std::string> split_csv_strings(const std::string& value) {
    std::vector<std::string> result;
    std::stringstream stream(value);
    std::string item;

    while (std::getline(stream, item, ',')) {
        item.erase(std::remove_if(item.begin(), item.end(),
                                  [](unsigned char ch) { return std::isspace(ch); }),
                   item.end());
        if (!item.empty()) {
            result.push_back(item);
        }
    }

    return result;
}

std::vector<int> split_csv_ints(const std::string& value) {
    std::vector<int> result;
    for (const std::string& item : split_csv_strings(value)) {
        result.push_back(std::stoi(item));
    }
    return result;
}

std::vector<BlockSize> split_csv_block_sizes(const std::string& value) {
    std::vector<BlockSize> result;
    for (const std::string& item : split_csv_strings(value)) {
        const size_t separator = item.find('x');
        if (separator == std::string::npos || separator == 0 || separator + 1 >= item.size()) {
            throw std::invalid_argument("Invalid block size: " + item + ". Expected format WIDTHxHEIGHT.");
        }

        const int width = std::stoi(item.substr(0, separator));
        const int height = std::stoi(item.substr(separator + 1));
        if (width <= 0 || height <= 0 || width * height > 1024) {
            throw std::invalid_argument("Block size must be positive and contain at most 1024 threads: " + item);
        }
        result.push_back({width, height});
    }
    return result;
}

BlockSize parse_block_size(const std::string& value) {
    const std::vector<BlockSize> block_sizes = split_csv_block_sizes(value);
    if (block_sizes.size() != 1) {
        throw std::invalid_argument("Expected exactly one block size for demo mode.");
    }
    return block_sizes.front();
}

std::string normalize_name(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char ch) {
                       return static_cast<char>(std::tolower(ch));
                   });
    return value;
}

void print_usage(const char* executable_name) {
    std::cout << "Usage: " << executable_name << " [options]\n"
              << "Options:\n"
              << "  --image-sizes 512,1024,2048,4096\n"
              << "  --filter-sizes 3,5,7,11\n"
              << "  --filter-types box,gaussian,sharpen,sobel\n"
              << "  --block-sizes 8x8,16x16,32x8,32x16\n"
              << "  --repeats 5\n"
              << "  --warmups 1\n"
              << "  --versions all\n"
              << "\nDemo mode:\n"
              << "  --demo-input input.pgm\n"
              << "  --demo-output output.pgm\n"
              << "  --demo-filter-type sobel\n"
              << "  --demo-filter-size 3\n"
              << "  --demo-version cuda_shared_constant_filter\n"
              << "  --demo-block-size 16x16\n"
              << "  --demo-normalize-output true\n"
              << "  --demo-warmups 1\n"
              << "  --demo-repeats 5\n"
              << "  --help\n";
}

ProgramOptions parse_arguments(int argc, char** argv) {
    ProgramOptions options;

    for (int i = 1; i < argc; ++i) {
        const std::string argument = argv[i];

        if (argument == "--help" || argument == "-h") {
            print_usage(argv[0]);
            std::exit(0);
        }

        if (i + 1 >= argc) {
            throw std::invalid_argument("Missing value for argument: " + argument);
        }

        const std::string value = argv[++i];
        if (argument == "--image-sizes") {
            options.benchmark.image_sizes = split_csv_ints(value);
        } else if (argument == "--filter-sizes") {
            options.benchmark.filter_sizes = split_csv_ints(value);
        } else if (argument == "--filter-types") {
            options.benchmark.filter_types = split_csv_strings(value);
        } else if (argument == "--block-sizes") {
            options.benchmark.block_sizes = split_csv_block_sizes(value);
        } else if (argument == "--repeats") {
            options.benchmark.repeat_count = std::stoi(value);
        } else if (argument == "--warmups") {
            options.benchmark.warmup_count = std::stoi(value);
        } else if (argument == "--versions") {
            options.benchmark.versions = split_csv_strings(value);
        } else if (argument == "--demo-input") {
            options.demo.enabled = true;
            options.demo.input_path = value;
        } else if (argument == "--demo-output") {
            options.demo.enabled = true;
            options.demo.output_path = value;
        } else if (argument == "--demo-filter-type") {
            options.demo.enabled = true;
            options.demo.filter_type = value;
        } else if (argument == "--demo-filter-size") {
            options.demo.enabled = true;
            options.demo.filter_size = std::stoi(value);
        } else if (argument == "--demo-version") {
            options.demo.enabled = true;
            options.demo.version = value;
        } else if (argument == "--demo-block-size") {
            options.demo.enabled = true;
            options.demo.block_size = parse_block_size(value);
        } else if (argument == "--demo-normalize-output") {
            options.demo.enabled = true;
            const std::string normalized = normalize_name(value);
            options.demo.normalize_output = normalized == "true" || normalized == "1" ||
                                            normalized == "yes";
        } else if (argument == "--demo-warmups") {
            options.demo.enabled = true;
            options.demo.warmup_count = std::stoi(value);
        } else if (argument == "--demo-repeats") {
            options.demo.enabled = true;
            options.demo.repeat_count = std::stoi(value);
        } else {
            throw std::invalid_argument("Unknown argument: " + argument);
        }
    }

    if (options.demo.enabled) {
        if (options.demo.input_path.empty() || options.demo.output_path.empty()) {
            throw std::invalid_argument("Demo mode requires --demo-input and --demo-output.");
        }
        return options;
    }

    if (options.benchmark.image_sizes.empty() || options.benchmark.filter_sizes.empty() ||
        options.benchmark.filter_types.empty() || options.benchmark.block_sizes.empty() ||
        options.benchmark.versions.empty()) {
        throw std::invalid_argument("Image sizes, filter sizes, filter types, block sizes, and versions must not be empty.");
    }
    if (options.benchmark.repeat_count <= 0) {
        throw std::invalid_argument("Repeat count must be positive.");
    }
    if (options.benchmark.warmup_count < 0) {
        throw std::invalid_argument("Warm-up count must not be negative.");
    }

    return options;
}

void run_demo(const DemoOptions& options) {
    const GrayscaleImage image = read_pgm_image(options.input_path);
    const FilterSpec filter = generate_filter_spec(options.filter_type, options.filter_size);
    const std::string version = normalize_name(options.version);

    std::vector<float> cpu_output;
    if (version == "cpu" || version == "cpu_sequential") {
        const auto cpu_start = std::chrono::high_resolution_clock::now();
        if (filter.separable && filter.type != "sharpen" && filter.type != "sobel") {
            convolution_cpu_separable(image.pixels,
                                      cpu_output,
                                      image.width,
                                      image.height,
                                      filter.filter_1d,
                                      options.filter_size);
        } else {
            convolution_cpu(image.pixels,
                            cpu_output,
                            image.width,
                            image.height,
                            filter.filter_2d,
                            options.filter_size);
        }
        const auto cpu_stop = std::chrono::high_resolution_clock::now();
        const double cpu_time_ms =
            std::chrono::duration<double, std::milli>(cpu_stop - cpu_start).count();
        write_pgm_image(options.output_path,
                        cpu_output,
                        image.width,
                        image.height,
                        options.normalize_output);
        std::cout << "Demo output written to " << options.output_path << '\n'
                  << "Version: " << options.version << '\n'
                  << "Image: " << image.width << "x" << image.height << '\n'
                  << "Filter: " << filter.type << " " << options.filter_size << "x"
                  << options.filter_size << '\n'
                  << "Block size: " << options.block_size.width << "x"
                  << options.block_size.height << '\n'
                  << "CPU time ms: " << cpu_time_ms << '\n'
                  << "GPU kernel time ms: 0\n"
                  << "GPU total time ms: 0\n"
                  << "Kernel speedup: 0\n"
                  << "Total speedup: 0\n"
                  << "Max abs error: 0\n"
                  << "Mean abs error: 0\n"
                  << "Passed: true\n";
        return;
    }

    std::vector<float> reference;
    std::vector<float> gpu_output;
    CudaTiming timing;
    double cpu_time_ms = 0.0;

    // Initialize CUDA context before timing, matching benchmark behavior.
    // In benchmarks, get_cuda_device_name() calls cudaFree(nullptr) before any
    // timing starts. Without this, the first cudaMalloc bears ~1000ms of
    // one-time CUDA runtime initialization that inflates allocation_time.
    CUDA_CHECK(cudaFree(nullptr));

    const auto cpu_start = std::chrono::high_resolution_clock::now();
    convolution_cpu(image.pixels,
                    reference,
                    image.width,
                    image.height,
                    filter.filter_2d,
                    options.filter_size);
    const auto cpu_stop = std::chrono::high_resolution_clock::now();
    cpu_time_ms =
        std::chrono::duration<double, std::milli>(cpu_stop - cpu_start).count();

    if (version == "naive" || version == "cuda_naive_global_memory") {
        convolution_cuda_naive(image.pixels, gpu_output, image.width, image.height,
                               filter.filter_2d, options.filter_size,
                               options.block_size.width, options.block_size.height, options.warmup_count, options.repeat_count, timing);
    } else if (version == "shared" || version == "cuda_shared_memory_tiled") {
        convolution_cuda_shared_memory_tiled(image.pixels, gpu_output, image.width, image.height,
                                             filter.filter_2d, options.filter_size,
                                             options.block_size.width, options.block_size.height, options.warmup_count, options.repeat_count, timing);
    } else if (version == "constant" || version == "cuda_shared_constant_filter") {
        convolution_cuda_shared_constant_filter(image.pixels, gpu_output, image.width, image.height,
                                                filter.filter_2d, options.filter_size,
                                                options.block_size.width, options.block_size.height, options.warmup_count, options.repeat_count, timing);
    } else if (version == "multi" || version == "cuda_multi_output") {
        convolution_cuda_multi_output(image.pixels, gpu_output, image.width, image.height,
                                      filter.filter_2d, options.filter_size,
                                      options.block_size.width, options.block_size.height, options.warmup_count, options.repeat_count, timing);
    } else if (version == "register" || version == "cuda_register_tiled") {
        convolution_cuda_register_tiled(image.pixels, gpu_output, image.width, image.height,
                                        filter.filter_2d, options.filter_size,
                                        options.block_size.width, options.block_size.height, options.warmup_count, options.repeat_count, timing);
    } else if (version == "separable" || version == "cuda_separable") {
        if (!filter.separable) {
            throw std::invalid_argument("Demo version cuda_separable requires a separable filter type.");
        }
        const auto separable_cpu_start = std::chrono::high_resolution_clock::now();
        convolution_cpu_separable(image.pixels,
                                  reference,
                                  image.width,
                                  image.height,
                                  filter.filter_1d,
                                  options.filter_size);
        const auto separable_cpu_stop = std::chrono::high_resolution_clock::now();
        cpu_time_ms = std::chrono::duration<double, std::milli>(
            separable_cpu_stop - separable_cpu_start).count();
        convolution_cuda_separable(image.pixels, gpu_output, image.width, image.height,
                                   filter.filter_1d, options.filter_size,
                                   options.block_size.width, options.block_size.height, options.warmup_count, options.repeat_count, timing);
    } else {
        throw std::invalid_argument("Unknown demo version: " + options.version);
    }

    const CorrectnessMetrics metrics =
        compare_outputs(reference, gpu_output, kCorrectnessTolerance);
    write_pgm_image(options.output_path,
                    gpu_output,
                    image.width,
                    image.height,
                    options.normalize_output);

    std::cout << "Demo output written to " << options.output_path << '\n'
              << "Version: " << options.version << '\n'
              << "Image: " << image.width << "x" << image.height << '\n'
              << "Filter: " << filter.type << " " << options.filter_size << "x"
              << options.filter_size << '\n'
              << "Block size: " << options.block_size.width << "x"
              << options.block_size.height << '\n'
              << "CPU time ms: " << cpu_time_ms << '\n'
              << "GPU kernel time ms: " << timing.kernel_time_ms << '\n'
              << "GPU total time ms: " << timing.total_time_ms << '\n'
              << "Kernel speedup: "
              << (timing.kernel_time_ms > 0.0 ? cpu_time_ms / timing.kernel_time_ms : 0.0)
              << '\n'
              << "Total speedup: "
              << (timing.total_time_ms > 0.0 ? cpu_time_ms / timing.total_time_ms : 0.0)
              << '\n'
              << "GPU allocation time ms: " << timing.allocation_time_ms << '\n'
              << "GPU host-to-device time ms: " << timing.host_to_device_time_ms << '\n'
              << "GPU device-to-host time ms: " << timing.device_to_host_time_ms << '\n'
              << "GPU free time ms: " << timing.free_time_ms << '\n'
              << "Max abs error: " << metrics.max_abs_error << '\n'
              << "Mean abs error: " << metrics.mean_abs_error << '\n'
              << "Passed: " << (metrics.passed ? "true" : "false") << '\n';
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const ProgramOptions options = parse_arguments(argc, argv);
        if (options.demo.enabled) {
            run_demo(options.demo);
            return 0;
        }

        std::filesystem::create_directories("results");

        const std::vector<BenchmarkResult> results = run_benchmarks(options.benchmark);
        write_results_csv("results/timing_results.csv", results);
        write_results_csv("results/correctness_results.csv", results);
        write_best_versions_csv("results/summary_best_versions.csv", results);

        const bool all_passed = std::all_of(results.begin(), results.end(),
                                           [](const BenchmarkResult& result) {
                                               return result.passed;
                                           });

        std::cout << "\nResults written to:\n"
                  << "  results/timing_results.csv\n"
                  << "  results/correctness_results.csv\n"
                  << "  results/summary_best_versions.csv\n";
        std::cout << "Correctness summary: "
                  << (all_passed ? "all CUDA runs passed" : "one or more CUDA runs failed")
                  << '\n';

        return all_passed ? 0 : 1;
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return 1;
    }
}
