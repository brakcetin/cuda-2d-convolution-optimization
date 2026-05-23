#include "convolution_cpu.h"

#include <stdexcept>

void convolution_cpu(const std::vector<float>& input,
                     std::vector<float>& output,
                     int width,
                     int height,
                     const std::vector<float>& filter,
                     int filter_size) {
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
    }
    if (input.size() != static_cast<size_t>(width * height)) {
        throw std::invalid_argument("Input image size does not match width * height.");
    }
    if (filter.size() != static_cast<size_t>(filter_size * filter_size)) {
        throw std::invalid_argument("Filter size does not match filter_size * filter_size.");
    }

    output.assign(static_cast<size_t>(width * height), 0.0f);
    const int radius = filter_size / 2;

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float sum = 0.0f;

            for (int fy = 0; fy < filter_size; ++fy) {
                const int image_y = y + fy - radius;
                if (image_y < 0 || image_y >= height) {
                    continue;
                }

                for (int fx = 0; fx < filter_size; ++fx) {
                    const int image_x = x + fx - radius;
                    if (image_x < 0 || image_x >= width) {
                        continue;
                    }

                    const float image_value = input[static_cast<size_t>(image_y * width + image_x)];
                    const float filter_value = filter[static_cast<size_t>(fy * filter_size + fx)];
                    sum += image_value * filter_value;
                }
            }

            output[static_cast<size_t>(y * width + x)] = sum;
        }
    }
}

void convolution_cpu_separable(const std::vector<float>& input,
                               std::vector<float>& output,
                               int width,
                               int height,
                               const std::vector<float>& filter_1d,
                               int filter_size) {
    if (width <= 0 || height <= 0 || filter_size <= 0 || filter_size % 2 == 0) {
        throw std::invalid_argument("Image dimensions must be positive and filter size must be odd.");
    }
    if (input.size() != static_cast<size_t>(width * height)) {
        throw std::invalid_argument("Input image size does not match width * height.");
    }
    if (filter_1d.size() != static_cast<size_t>(filter_size)) {
        throw std::invalid_argument("1D filter size does not match filter_size.");
    }

    std::vector<float> intermediate(static_cast<size_t>(width * height), 0.0f);
    output.assign(static_cast<size_t>(width * height), 0.0f);
    const int radius = filter_size / 2;

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float sum = 0.0f;
            for (int fx = 0; fx < filter_size; ++fx) {
                const int image_x = x + fx - radius;
                if (image_x >= 0 && image_x < width) {
                    sum += input[static_cast<size_t>(y * width + image_x)] *
                           filter_1d[static_cast<size_t>(fx)];
                }
            }
            intermediate[static_cast<size_t>(y * width + x)] = sum;
        }
    }

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float sum = 0.0f;
            for (int fy = 0; fy < filter_size; ++fy) {
                const int image_y = y + fy - radius;
                if (image_y >= 0 && image_y < height) {
                    sum += intermediate[static_cast<size_t>(image_y * width + x)] *
                           filter_1d[static_cast<size_t>(fy)];
                }
            }
            output[static_cast<size_t>(y * width + x)] = sum;
        }
    }
}
