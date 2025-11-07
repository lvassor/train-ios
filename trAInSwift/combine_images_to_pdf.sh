#!/bin/bash

# Script to combine all images in current folder into a PDF
# Supports: jpg, jpeg, png, gif, bmp, tiff

OUTPUT_FILE="combined_images.pdf"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed."
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Find all image files in current directory
shopt -s nullglob
images=(*.jpg *.jpeg *.JPG *.JPEG *.png *.PNG *.gif *.GIF *.bmp *.BMP *.tiff *.TIFF)

# Check if any images were found
if [ ${#images[@]} -eq 0 ]; then
    echo "No image files found in current directory."
    exit 1
fi

echo "Found ${#images[@]} image(s):"
printf '%s\n' "${images[@]}"

# Combine images into PDF
echo ""
echo "Creating PDF..."
convert "${images[@]}" "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Success! PDF created: $OUTPUT_FILE"
    ls -lh "$OUTPUT_FILE"
else
    echo "❌ Error creating PDF"
    exit 1
fi
