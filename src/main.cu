#include "benchmark.h"

#include <algorithm>
#include <exception>
#include <filesystem>
#include <iostream>

int main() {
    try {
        std::filesystem::create_directories("results");

        const std::vector<BenchmarkResult> results = run_benchmarks();
        write_results_csv("results/timing_results.csv", results);
        write_results_csv("results/correctness_results.csv", results);

        const bool all_passed = std::all_of(results.begin(), results.end(),
                                           [](const BenchmarkResult& result) {
                                               return result.passed;
                                           });

        std::cout << "\nResults written to:\n"
                  << "  results/timing_results.csv\n"
                  << "  results/correctness_results.csv\n";
        std::cout << "Correctness summary: "
                  << (all_passed ? "all CUDA runs passed" : "one or more CUDA runs failed")
                  << '\n';

        return all_passed ? 0 : 1;
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return 1;
    }
}
