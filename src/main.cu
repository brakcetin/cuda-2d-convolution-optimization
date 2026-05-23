#include "benchmark.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <iostream>
#include <sstream>

namespace {

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

void print_usage(const char* executable_name) {
    std::cout << "Usage: " << executable_name << " [options]\n"
              << "Options:\n"
              << "  --image-sizes 512,1024,2048\n"
              << "  --filter-sizes 3,5,7,11\n"
              << "  --filter-types box,gaussian,sharpen,sobel\n"
              << "  --block-sizes 8x8,16x16,32x8,32x16\n"
              << "  --repeats 5\n"
              << "  --warmups 1\n"
              << "  --versions all\n"
              << "  --help\n";
}

BenchmarkOptions parse_arguments(int argc, char** argv) {
    BenchmarkOptions options;

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
            options.image_sizes = split_csv_ints(value);
        } else if (argument == "--filter-sizes") {
            options.filter_sizes = split_csv_ints(value);
        } else if (argument == "--filter-types") {
            options.filter_types = split_csv_strings(value);
        } else if (argument == "--block-sizes") {
            options.block_sizes = split_csv_block_sizes(value);
        } else if (argument == "--repeats") {
            options.repeat_count = std::stoi(value);
        } else if (argument == "--warmups") {
            options.warmup_count = std::stoi(value);
        } else if (argument == "--versions") {
            options.versions = split_csv_strings(value);
        } else {
            throw std::invalid_argument("Unknown argument: " + argument);
        }
    }

    if (options.image_sizes.empty() || options.filter_sizes.empty() ||
        options.filter_types.empty() || options.block_sizes.empty() || options.versions.empty()) {
        throw std::invalid_argument("Image sizes, filter sizes, filter types, block sizes, and versions must not be empty.");
    }
    if (options.repeat_count <= 0) {
        throw std::invalid_argument("Repeat count must be positive.");
    }
    if (options.warmup_count < 0) {
        throw std::invalid_argument("Warm-up count must not be negative.");
    }

    return options;
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const BenchmarkOptions options = parse_arguments(argc, argv);
        std::filesystem::create_directories("results");

        const std::vector<BenchmarkResult> results = run_benchmarks(options);
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
