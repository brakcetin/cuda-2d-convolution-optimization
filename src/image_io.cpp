#include "image_io.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {

std::string read_token(std::istream& stream) {
    std::string token;
    char ch = '\0';

    while (stream.get(ch)) {
        if (std::isspace(static_cast<unsigned char>(ch))) {
            continue;
        }
        if (ch == '#') {
            std::string ignored;
            std::getline(stream, ignored);
            continue;
        }
        token.push_back(ch);
        break;
    }

    while (stream.get(ch)) {
        if (std::isspace(static_cast<unsigned char>(ch))) {
            break;
        }
        if (ch == '#') {
            std::string ignored;
            std::getline(stream, ignored);
            break;
        }
        token.push_back(ch);
    }

    if (token.empty()) {
        throw std::runtime_error("Unexpected end of PGM file.");
    }
    return token;
}

float clamp01(float value) {
    return std::max(0.0f, std::min(1.0f, value));
}

}  // namespace

GrayscaleImage read_pgm_image(const std::string& path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) {
        throw std::runtime_error("Could not open input image: " + path);
    }

    const std::string magic = read_token(input);
    if (magic != "P2" && magic != "P5") {
        throw std::runtime_error("Unsupported PGM format. Expected P2 or P5.");
    }

    const int width = std::stoi(read_token(input));
    const int height = std::stoi(read_token(input));
    const int max_value = std::stoi(read_token(input));
    if (width <= 0 || height <= 0 || max_value <= 0 || max_value > 255) {
        throw std::runtime_error("Invalid PGM dimensions or max value.");
    }

    GrayscaleImage image;
    image.width = width;
    image.height = height;
    image.pixels.resize(static_cast<size_t>(width * height));

    if (magic == "P2") {
        for (float& pixel : image.pixels) {
            const int value = std::stoi(read_token(input));
            pixel = static_cast<float>(value) / static_cast<float>(max_value);
        }
    } else {
        std::vector<unsigned char> bytes(static_cast<size_t>(width * height));
        input.read(reinterpret_cast<char*>(bytes.data()),
                   static_cast<std::streamsize>(bytes.size()));
        if (input.gcount() != static_cast<std::streamsize>(bytes.size())) {
            throw std::runtime_error("PGM file ended before all pixels were read.");
        }
        for (size_t i = 0; i < bytes.size(); ++i) {
            image.pixels[i] = static_cast<float>(bytes[i]) / static_cast<float>(max_value);
        }
    }

    return image;
}

void write_pgm_image(const std::string& path,
                     const std::vector<float>& pixels,
                     int width,
                     int height,
                     bool normalize) {
    if (width <= 0 || height <= 0 ||
        pixels.size() != static_cast<size_t>(width * height)) {
        throw std::runtime_error("Output image dimensions do not match pixel count.");
    }

    std::ofstream output(path, std::ios::binary);
    if (!output) {
        throw std::runtime_error("Could not open output image: " + path);
    }

    float min_value = 0.0f;
    float max_value = 1.0f;
    if (normalize) {
        const auto [min_it, max_it] = std::minmax_element(pixels.begin(), pixels.end());
        min_value = *min_it;
        max_value = *max_it;
        if (max_value - min_value < std::numeric_limits<float>::epsilon()) {
            max_value = min_value + 1.0f;
        }
    }

    output << "P2\n" << width << ' ' << height << "\n255\n";
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float value = pixels[static_cast<size_t>(y * width + x)];
            if (normalize) {
                value = (value - min_value) / (max_value - min_value);
            }
            const int byte_value = static_cast<int>(clamp01(value) * 255.0f + 0.5f);
            output << byte_value;
            if (x + 1 < width) {
                output << ' ';
            }
        }
        output << '\n';
    }
}
