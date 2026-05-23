#pragma once

#include <string>
#include <vector>

#include "common.h"

CorrectnessMetrics compare_outputs(const std::vector<float>& reference,
                                   const std::vector<float>& candidate,
                                   float tolerance);

std::vector<BenchmarkResult> run_benchmarks();

void write_results_csv(const std::string& path,
                       const std::vector<BenchmarkResult>& results);
