#include "filters.h"

#include <random>
#include <stdexcept>

std::vector<float> generate_random_image(int width, int height, unsigned int seed) {
    if (width <= 0 || height <= 0) {
        throw std::invalid_argument("Image dimensions must be positive.");
    }

    std::mt19937 rng(seed);
    std::uniform_real_distribution<float> distribution(0.0f, 1.0f);

    std::vector<float> image(static_cast<size_t>(width * height));
    for (float& value : image) {
        value = distribution(rng);
    }

    return image;
}

std::vector<float> generate_normalized_filter(int filter_size) {
    if (filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Filter size must be a positive odd number.");
    }

    const float value = 1.0f / static_cast<float>(filter_size * filter_size);
    return std::vector<float>(static_cast<size_t>(filter_size * filter_size), value);
}
