#pragma once

#include <string>
#include <vector>

#include "common.h"

struct BenchmarkOptions {
    std::vector<int> image_sizes = {512, 1024, 2048};
    std::vector<int> filter_sizes = {3, 5, 7, 11};
    std::vector<std::string> versions = {"all"};
    int repeat_count = 5;
    int warmup_count = 1;
};

CorrectnessMetrics compare_outputs(const std::vector<float>& reference,
                                   const std::vector<float>& candidate,
                                   float tolerance);

std::vector<BenchmarkResult> run_benchmarks(const BenchmarkOptions& options);

void write_results_csv(const std::string& path,
                       const std::vector<BenchmarkResult>& results);

void write_best_versions_csv(const std::string& path,
                             const std::vector<BenchmarkResult>& results);
