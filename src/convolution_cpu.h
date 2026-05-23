#pragma once

#include <vector>

void convolution_cpu(const std::vector<float>& input,
                     std::vector<float>& output,
                     int width,
                     int height,
                     const std::vector<float>& filter,
                     int filter_size);

void convolution_cpu_separable(const std::vector<float>& input,
                               std::vector<float>& output,
                               int width,
                               int height,
                               const std::vector<float>& filter_1d,
                               int filter_size);
