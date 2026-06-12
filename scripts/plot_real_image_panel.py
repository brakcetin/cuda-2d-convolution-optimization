"""Build the qualitative real-image demo panel for the Submission 2 report.

Reads the committed PGM demo inputs/outputs and arranges them in one figure.
"""
import argparse

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

PANELS = [
    (r"data\real_images\building_1024.pgm", "Building input"),
    (r"results\building_sobel.pgm", "Sobel-like 3x3\ncuda_shared_constant_filter"),
    (r"data\real_images\portrait_1024.pgm", "Portrait input"),
    (r"results\portrait_gaussian.pgm", "Gaussian-like 11x11\ncuda_separable"),
    (r"results\portrait_sharpen.pgm", "Sharpen 3x3\ncuda_shared_constant_filter"),
    (r"results\texture_sobel.pgm", "Texture, Sobel-like 3x3\ncuda_shared_constant_filter"),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default=r"results\plots\real_image_demo_panel.png")
    args = parser.parse_args()

    fig, axes = plt.subplots(2, 3, figsize=(10.5, 7))
    for ax, (path, title) in zip(axes.flat, PANELS):
        ax.imshow(np.asarray(Image.open(path)), cmap="gray")
        ax.set_title(title, fontsize=9)
        ax.axis("off")
    fig.suptitle("Qualitative real-image demo (PGM path), grayscale with aspect ratio preserved")
    fig.tight_layout()
    fig.savefig(args.output, dpi=150)
    print(f"Plot written to {args.output}")


if __name__ == "__main__":
    main()
