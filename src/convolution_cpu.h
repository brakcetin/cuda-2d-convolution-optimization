#pragma once

#include <vector>

void convolution_cpu(const std::vector<float>& input,
                     std::vector<float>& output,
                     int width,
                     int height,
                     const std::vector<float>& filter,
                     int filter_size);
