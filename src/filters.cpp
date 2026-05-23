#include "filters.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <numeric>
#include <random>
#include <stdexcept>
#include <string>

namespace {

void validate_filter_size(int filter_size) {
    if (filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Filter size must be a positive odd number.");
    }
}

std::string normalize_filter_type(std::string filter_type) {
    std::transform(filter_type.begin(), filter_type.end(), filter_type.begin(),
                   [](unsigned char ch) {
                       return static_cast<char>(std::tolower(ch));
                   });
    return filter_type;
}

FilterSpec generate_box_filter(int filter_size) {
    const float value_1d = 1.0f / static_cast<float>(filter_size);
    const float value_2d = 1.0f / static_cast<float>(filter_size * filter_size);

    FilterSpec spec;
    spec.type = "box";
    spec.filter_1d.assign(static_cast<size_t>(filter_size), value_1d);
    spec.filter_2d.assign(static_cast<size_t>(filter_size * filter_size), value_2d);
    spec.separable = true;
    return spec;
}

FilterSpec generate_gaussian_filter(int filter_size) {
    const int radius = filter_size / 2;
    const float sigma = std::max(1.0f, static_cast<float>(filter_size) / 3.0f);
    const float denominator = 2.0f * sigma * sigma;

    FilterSpec spec;
    spec.type = "gaussian";
    spec.filter_1d.resize(static_cast<size_t>(filter_size));

    for (int i = 0; i < filter_size; ++i) {
        const int distance = i - radius;
        spec.filter_1d[static_cast<size_t>(i)] =
            std::exp(-static_cast<float>(distance * distance) / denominator);
    }

    const float sum = std::accumulate(spec.filter_1d.begin(), spec.filter_1d.end(), 0.0f);
    for (float& value : spec.filter_1d) {
        value /= sum;
    }

    spec.filter_2d.assign(static_cast<size_t>(filter_size * filter_size), 0.0f);
    for (int y = 0; y < filter_size; ++y) {
        for (int x = 0; x < filter_size; ++x) {
            spec.filter_2d[static_cast<size_t>(y * filter_size + x)] =
                spec.filter_1d[static_cast<size_t>(y)] *
                spec.filter_1d[static_cast<size_t>(x)];
        }
    }

    spec.separable = true;
    return spec;
}

FilterSpec generate_sharpen_filter(int filter_size) {
    const int center = filter_size / 2;

    FilterSpec spec;
    spec.type = "sharpen";
    spec.filter_2d.assign(static_cast<size_t>(filter_size * filter_size), 0.0f);
    spec.filter_2d[static_cast<size_t>(center * filter_size + center)] = 5.0f;
    spec.filter_2d[static_cast<size_t>((center - 1) * filter_size + center)] = -1.0f;
    spec.filter_2d[static_cast<size_t>((center + 1) * filter_size + center)] = -1.0f;
    spec.filter_2d[static_cast<size_t>(center * filter_size + center - 1)] = -1.0f;
    spec.filter_2d[static_cast<size_t>(center * filter_size + center + 1)] = -1.0f;
    spec.separable = false;
    return spec;
}

FilterSpec generate_sobel_filter(int filter_size) {
    const int center = filter_size / 2;
    const float sobel[3][3] = {
        {-1.0f, 0.0f, 1.0f},
        {-2.0f, 0.0f, 2.0f},
        {-1.0f, 0.0f, 1.0f},
    };

    FilterSpec spec;
    spec.type = "sobel";
    spec.filter_2d.assign(static_cast<size_t>(filter_size * filter_size), 0.0f);
    for (int y = 0; y < 3; ++y) {
        for (int x = 0; x < 3; ++x) {
            const int target_y = center + y - 1;
            const int target_x = center + x - 1;
            spec.filter_2d[static_cast<size_t>(target_y * filter_size + target_x)] =
                sobel[y][x];
        }
    }
    spec.separable = false;
    return spec;
}

}  // namespace

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
    validate_filter_size(filter_size);

    const float value = 1.0f / static_cast<float>(filter_size * filter_size);
    return std::vector<float>(static_cast<size_t>(filter_size * filter_size), value);
}

FilterSpec generate_filter_spec(const std::string& filter_type, int filter_size) {
    validate_filter_size(filter_size);
    const std::string normalized_type = normalize_filter_type(filter_type);

    if (normalized_type == "box") {
        return generate_box_filter(filter_size);
    }
    if (normalized_type == "gaussian") {
        return generate_gaussian_filter(filter_size);
    }
    if (normalized_type == "sharpen") {
        return generate_sharpen_filter(filter_size);
    }
    if (normalized_type == "sobel") {
        return generate_sobel_filter(filter_size);
    }

    throw std::invalid_argument("Unknown filter type: " + filter_type);
}
