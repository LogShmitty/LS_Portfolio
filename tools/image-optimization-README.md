# Image Optimization Scripts

This repository contains two shell scripts for optimizing images for web use:

1. `optimize-images.sh` - A simple script to compress JPG and PNG images
2. `optimize-images-advanced.sh` - An advanced script with more options for resizing and customizing optimization

## Requirements

Both scripts require the following tools to be installed:

- **ImageMagick** - For image manipulation and resizing
- **pngquant** - For PNG compression
- **jpegoptim** - For JPEG compression

### Installation Instructions

#### macOS (using Homebrew)

```bash
brew install imagemagick pngquant jpegoptim
```

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install imagemagick pngquant jpegoptim
```

#### CentOS/RHEL

```bash
sudo yum install imagemagick pngquant jpegoptim
```

## Basic Script: optimize-images.sh

### Usage

```bash
./optimize-images.sh [directory]
```

If no directory is specified, the script will process images in the current directory.

### Example

```bash
# Optimize all images in the Images directory
./optimize-images.sh Images

# Optimize all images in the current directory
./optimize-images.sh
```

## Advanced Script: optimize-images-advanced.sh

### Usage

```bash
./optimize-images-advanced.sh [options] [directory]
```

### Options

- `-w, --max-width WIDTH` - Resize images to have a maximum width of WIDTH pixels
- `-h, --max-height HEIGHT` - Resize images to have a maximum height of HEIGHT pixels
- `-q, --quality QUALITY` - JPEG/PNG quality (0-100, default: 85)
- `-r, --recursive` - Process directories recursively
- `-b, --backup` - Create backups of original files
- `-s, --suffix SUFFIX` - Add suffix to optimized files instead of replacing them
- `--help` - Display help message

### Examples

```bash
# Resize all images to a maximum width of 1200px with 80% quality
./optimize-images-advanced.sh -w 1200 -q 80 ./Images

# Process all images recursively and create backups
./optimize-images-advanced.sh -r -b ./Images

# Create web-optimized versions with a suffix instead of replacing originals
./optimize-images-advanced.sh -w 1600 -s '-web' ./Images

# Resize images to fit within 1200x800px while maintaining aspect ratio
./optimize-images-advanced.sh -w 1200 -h 800 ./Images
```

## How It Works

Both scripts:

1. Find all JPG and PNG files in the specified directory
2. For JPG files:
   - Strip metadata (EXIF, etc.)
   - Compress using jpegoptim
3. For PNG files:
   - Compress using pngquant with appropriate quality settings
   - Only use the optimized version if it's smaller than the original

The advanced script additionally:
- Can resize images to specified dimensions while maintaining aspect ratio
- Can process directories recursively
- Can create backups of original files
- Can create new files with a suffix instead of replacing originals

## Tips for Best Results

1. For most web images, a quality setting of 80-85 provides a good balance between file size and visual quality
2. Consider using the `-s` option with the advanced script to create web-optimized versions while keeping originals
3. Common maximum widths for responsive web images:
   - Thumbnails: 200-400px
   - Content images: 800-1200px
   - Full-width/hero images: 1600-2000px
4. For even better optimization of critical images, consider using online services like TinyPNG or Squoosh

## Troubleshooting

If you encounter any issues:

1. Make sure all required tools are installed
2. Check that you have write permissions for the target directory
3. For very large images, you may need to increase available memory for ImageMagick

## License

These scripts are provided under the MIT License. Feel free to modify and distribute them as needed.
