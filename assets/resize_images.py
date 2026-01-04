#!/usr/bin/env python3
"""
Resize images for Claude API compatibility.

When submitting 20+ images, Claude requires max 2000x2000 px per image.
This script resizes all images in a folder to fit within that limit.
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

SUPPORTED_FORMATS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
MAX_DIMENSION = 1990  # Max pixels for 20+ image submissions


def resize_image(input_path: Path, output_path: Path, max_dim: int) -> bool:
    """Resize image to fit within max_dim x max_dim, preserving aspect ratio."""
    try:
        with Image.open(input_path) as img:
            original_size = img.size

            # Check if resizing is needed
            if img.width <= max_dim and img.height <= max_dim:
                # Just copy if already within limits
                img.save(output_path, quality=95)
                print(f"  {input_path.name}: {original_size} (no resize needed)")
                return True

            # Calculate new dimensions preserving aspect ratio
            ratio = min(max_dim / img.width, max_dim / img.height)
            new_size = (int(img.width * ratio), int(img.height * ratio))

            # Resize using high-quality Lanczos filter
            resized = img.resize(new_size, Image.Resampling.LANCZOS)

            # Preserve format, handle RGBA for JPEG
            if output_path.suffix.lower() in {".jpg", ".jpeg"} and resized.mode == "RGBA":
                resized = resized.convert("RGB")

            resized.save(output_path, quality=95)
            print(f"  {input_path.name}: {original_size} -> {new_size}")
            return True

    except Exception as e:
        print(f"  ERROR: {input_path.name}: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Resize images for Claude API (max 2000x2000 for 20+ images)"
    )
    parser.add_argument("input_folder", type=Path, help="Folder containing images")
    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=None,
        help="Output folder (default: input_folder/resized)"
    )
    parser.add_argument(
        "-m", "--max-dimension",
        type=int,
        default=MAX_DIMENSION,
        help=f"Max pixel dimension (default: {MAX_DIMENSION})"
    )

    args = parser.parse_args()

    if not args.input_folder.is_dir():
        print(f"Error: '{args.input_folder}' is not a directory", file=sys.stderr)
        sys.exit(1)

    output_folder = args.output or args.input_folder / "resized"
    output_folder.mkdir(parents=True, exist_ok=True)

    # Find all supported images
    images = [
        f for f in args.input_folder.iterdir()
        if f.is_file() and f.suffix.lower() in SUPPORTED_FORMATS
    ]

    if not images:
        print(f"No supported images found in '{args.input_folder}'")
        print(f"Supported formats: {', '.join(SUPPORTED_FORMATS)}")
        sys.exit(1)

    print(f"Found {len(images)} images")
    print(f"Max dimension: {args.max_dimension}px")
    print(f"Output folder: {output_folder}\n")

    success = 0
    failed = 0

    for img_path in sorted(images):
        output_path = output_folder / img_path.name
        if resize_image(img_path, output_path, args.max_dimension):
            success += 1
        else:
            failed += 1

    print(f"\nComplete: {success} resized, {failed} failed")


if __name__ == "__main__":
    main()
