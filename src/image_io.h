#pragma once

#include <string>
#include <vector>

struct GrayscaleImage {
    int width = 0;
    int height = 0;
    std::vector<float> pixels;
};

GrayscaleImage read_pgm_image(const std::string& path);

void write_pgm_image(const std::string& path,
                     const std::vector<float>& pixels,
                     int width,
                     int height,
                     bool normalize);
