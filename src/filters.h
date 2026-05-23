#pragma once

#include <string>
#include <vector>

struct FilterSpec {
    std::string type;
    std::vector<float> filter_2d;
    std::vector<float> filter_1d;
    bool separable = false;
};

std::vector<float> generate_random_image(int width, int height, unsigned int seed);
std::vector<float> generate_normalized_filter(int filter_size);
FilterSpec generate_filter_spec(const std::string& filter_type, int filter_size);
