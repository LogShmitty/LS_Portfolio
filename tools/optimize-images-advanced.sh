#!/bin/bash

# optimize-images-advanced.sh
# A script to compress, resize, and optimize JPG and PNG images for web use
# Usage: ./optimize-images-advanced.sh [options] [directory]
#
# Options:
#   -w, --max-width WIDTH    Resize images to have a maximum width of WIDTH pixels
#   -h, --max-height HEIGHT  Resize images to have a maximum height of HEIGHT pixels
#   -q, --quality QUALITY    JPEG/PNG quality (0-100, default: 85 for JPEG, 85 for PNG)
#   -r, --recursive          Process directories recursively
#   -b, --backup             Create backups of original files
#   -s, --suffix SUFFIX      Add suffix to optimized files instead of replacing them
#   --help                   Display this help message

# Default values
TARGET_DIR="."
MAX_WIDTH=""
MAX_HEIGHT=""
JPEG_QUALITY=85
PNG_QUALITY=85
RECURSIVE=false
BACKUP=false
SUFFIX=""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo "Usage: $0 [options] [directory]"
    echo ""
    echo "Options:"
    echo "  -w, --max-width WIDTH    Resize images to have a maximum width of WIDTH pixels"
    echo "  -h, --max-height HEIGHT  Resize images to have a maximum height of HEIGHT pixels"
    echo "  -q, --quality QUALITY    JPEG/PNG quality (0-100, default: 85)"
    echo "  -r, --recursive          Process directories recursively"
    echo "  -b, --backup             Create backups of original files"
    echo "  -s, --suffix SUFFIX      Add suffix to optimized files instead of replacing them"
    echo "  --help                   Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -w 1200 -q 80 ./Images"
    echo "  $0 -h 800 -r -b ./Images"
    echo "  $0 -w 1600 -s '-web' ./Images"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--max-width)
            MAX_WIDTH="$2"
            shift 2
            ;;
        -h|--max-height)
            MAX_HEIGHT="$2"
            shift 2
            ;;
        -q|--quality)
            JPEG_QUALITY="$2"
            PNG_QUALITY="$2"
            shift 2
            ;;
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        -s|--suffix)
            SUFFIX="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            if [[ -d "$1" ]]; then
                TARGET_DIR="$1"
            else
                echo -e "${RED}Error: Unknown option or invalid directory: $1${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Function to check if a command is available
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed.${NC}"
        echo "Please install it using one of the following commands:"
        
        if command -v brew &> /dev/null; then
            echo "  brew install $2"
        elif command -v apt-get &> /dev/null; then
            echo "  sudo apt-get install $3"
        elif command -v yum &> /dev/null; then
            echo "  sudo yum install $4"
        else
            echo "  Please install $1 using your package manager."
        fi
        
        return 1
    fi
    return 0
}

# Check for required tools
echo -e "${YELLOW}Checking for required tools...${NC}"

# Check for ImageMagick (convert)
check_command "convert" "imagemagick" "imagemagick" "imagemagick" || MISSING_TOOLS=1

# Check for pngquant
check_command "pngquant" "pngquant" "pngquant" "pngquant" || MISSING_TOOLS=1

# Check for jpegoptim
check_command "jpegoptim" "jpegoptim" "jpegoptim" "jpegoptim" || MISSING_TOOLS=1

# Exit if any tools are missing
if [ -n "$MISSING_TOOLS" ]; then
    echo -e "${RED}Please install the missing tools and try again.${NC}"
    exit 1
fi

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist.${NC}"
    exit 1
fi

echo -e "${GREEN}All required tools are installed.${NC}"
echo -e "${YELLOW}Starting image optimization in '$TARGET_DIR'...${NC}"

# Create a temporary directory for storing original file sizes
TEMP_DIR=$(mktemp -d)

# Initialize counters
TOTAL_FILES=0
TOTAL_ORIGINAL_SIZE=0
TOTAL_OPTIMIZED_SIZE=0

# Build find command based on recursion option
if [ "$RECURSIVE" = true ]; then
    FIND_DEPTH=""
else
    FIND_DEPTH="-maxdepth 1"
fi

# Process JPG files
echo -e "${YELLOW}Processing JPEG files...${NC}"
find "$TARGET_DIR" $FIND_DEPTH -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | while IFS= read -r -d '' file; do
    # Get original file size
    ORIGINAL_SIZE=$(stat -f %z "$file")
    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + ORIGINAL_SIZE))
    
    echo -e "${BLUE}Optimizing: $file${NC}"
    
    # Determine output filename
    if [ -n "$SUFFIX" ]; then
        filename=$(basename "$file")
        extension="${filename##*.}"
        filename="${filename%.*}"
        directory=$(dirname "$file")
        output_file="$directory/$filename$SUFFIX.$extension"
    else
        output_file="$file"
    fi
    
    # Create backup if requested
    if [ "$BACKUP" = true ] && [ "$output_file" = "$file" ]; then
        cp "$file" "$file.bak"
        echo "  Created backup: $file.bak"
    fi
    
    # Create a temporary file for processing
    TEMP_FILE="$TEMP_DIR/$(basename "$file")"
    cp "$file" "$TEMP_FILE"
    
    # Resize image if requested
    if [ -n "$MAX_WIDTH" ] || [ -n "$MAX_HEIGHT" ]; then
        resize_options=""
        
        if [ -n "$MAX_WIDTH" ]; then
            resize_options="$resize_options -resize ${MAX_WIDTH}x"
        fi
        
        if [ -n "$MAX_HEIGHT" ]; then
            if [ -n "$resize_options" ]; then
                # If both width and height are specified, use the > operator to maintain aspect ratio
                resize_options="${resize_options%x}x$MAX_HEIGHT>"
            else
                resize_options="$resize_options -resize x${MAX_HEIGHT}"
            fi
        fi
        
        # Add '>' to ensure we only resize if the image is larger than the specified dimensions
        if [[ ! "$resize_options" == *">"* ]]; then
            resize_options="$resize_options>"
        fi
        
        echo "  Resizing with options: $resize_options"
        convert "$TEMP_FILE" $resize_options "$TEMP_FILE"
    fi
    
    # Optimize JPEG
    jpegoptim --strip-all --max="$JPEG_QUALITY" --stdout "$TEMP_FILE" > "$output_file" 2>/dev/null
    
    # Get new file size
    NEW_SIZE=$(stat -f %z "$output_file")
    TOTAL_OPTIMIZED_SIZE=$((TOTAL_OPTIMIZED_SIZE + NEW_SIZE))
    
    # Calculate savings
    SAVED=$((ORIGINAL_SIZE - NEW_SIZE))
    PERCENT=$(awk "BEGIN {printf \"%.2f\", ($SAVED / $ORIGINAL_SIZE) * 100}")
    
    echo -e "  ${GREEN}Reduced from $(numfmt --to=iec-i --suffix=B $ORIGINAL_SIZE) to $(numfmt --to=iec-i --suffix=B $NEW_SIZE) (${PERCENT}% savings)${NC}"
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
done

# Process PNG files
echo -e "${YELLOW}Processing PNG files...${NC}"
find "$TARGET_DIR" $FIND_DEPTH -type f \( -iname "*.png" \) -print0 | while IFS= read -r -d '' file; do
    # Get original file size
    ORIGINAL_SIZE=$(stat -f %z "$file")
    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + ORIGINAL_SIZE))
    
    echo -e "${BLUE}Optimizing: $file${NC}"
    
    # Determine output filename
    if [ -n "$SUFFIX" ]; then
        filename=$(basename "$file")
        extension="${filename##*.}"
        filename="${filename%.*}"
        directory=$(dirname "$file")
        output_file="$directory/$filename$SUFFIX.$extension"
    else
        output_file="$file"
    fi
    
    # Create backup if requested
    if [ "$BACKUP" = true ] && [ "$output_file" = "$file" ]; then
        cp "$file" "$file.bak"
        echo "  Created backup: $file.bak"
    fi
    
    # Create a temporary file for processing
    TEMP_FILE="$TEMP_DIR/$(basename "$file")"
    cp "$file" "$TEMP_FILE"
    
    # Resize image if requested
    if [ -n "$MAX_WIDTH" ] || [ -n "$MAX_HEIGHT" ]; then
        resize_options=""
        
        if [ -n "$MAX_WIDTH" ]; then
            resize_options="$resize_options -resize ${MAX_WIDTH}x"
        fi
        
        if [ -n "$MAX_HEIGHT" ]; then
            if [ -n "$resize_options" ]; then
                # If both width and height are specified, use the > operator to maintain aspect ratio
                resize_options="${resize_options%x}x$MAX_HEIGHT>"
            else
                resize_options="$resize_options -resize x${MAX_HEIGHT}"
            fi
        fi
        
        # Add '>' to ensure we only resize if the image is larger than the specified dimensions
        if [[ ! "$resize_options" == *">"* ]]; then
            resize_options="$resize_options>"
        fi
        
        echo "  Resizing with options: $resize_options"
        convert "$TEMP_FILE" $resize_options "$TEMP_FILE"
    fi
    
    # Optimize PNG with pngquant
    min_quality=$((PNG_QUALITY - 10))
    if [ $min_quality -lt 0 ]; then
        min_quality=0
    fi
    
    pngquant --force --quality=$min_quality-$PNG_QUALITY --output "$TEMP_FILE-optimized" "$TEMP_FILE"
    
    # Check if optimization was successful and the file is smaller
    if [ -f "$TEMP_FILE-optimized" ]; then
        TEMP_SIZE=$(stat -f %z "$TEMP_FILE-optimized")
        ORIGINAL_TEMP_SIZE=$(stat -f %z "$TEMP_FILE")
        
        # Only use the optimized version if it's smaller
        if [ "$TEMP_SIZE" -lt "$ORIGINAL_TEMP_SIZE" ]; then
            mv "$TEMP_FILE-optimized" "$output_file"
            NEW_SIZE=$TEMP_SIZE
        else
            # If pngquant didn't produce a smaller file, use the resized but not pngquant-optimized version
            mv "$TEMP_FILE" "$output_file"
            NEW_SIZE=$ORIGINAL_TEMP_SIZE
            echo -e "  ${YELLOW}Note: pngquant optimization skipped (would have increased file size)${NC}"
        fi
    else
        # If pngquant failed, use the resized version
        mv "$TEMP_FILE" "$output_file"
        NEW_SIZE=$(stat -f %z "$output_file")
        echo -e "  ${YELLOW}Note: pngquant failed, using resized version only${NC}"
    fi
    
    TOTAL_OPTIMIZED_SIZE=$((TOTAL_OPTIMIZED_SIZE + NEW_SIZE))
    
    # Calculate savings
    SAVED=$((ORIGINAL_SIZE - NEW_SIZE))
    PERCENT=$(awk "BEGIN {printf \"%.2f\", ($SAVED / $ORIGINAL_SIZE) * 100}")
    
    echo -e "  ${GREEN}Reduced from $(numfmt --to=iec-i --suffix=B $ORIGINAL_SIZE) to $(numfmt --to=iec-i --suffix=B $NEW_SIZE) (${PERCENT}% savings)${NC}"
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
done

# Calculate total savings
TOTAL_SAVED=$((TOTAL_ORIGINAL_SIZE - TOTAL_OPTIMIZED_SIZE))
if [ $TOTAL_ORIGINAL_SIZE -gt 0 ]; then
    TOTAL_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($TOTAL_SAVED / $TOTAL_ORIGINAL_SIZE) * 100}")
else
    TOTAL_PERCENT="0.00"
fi

# Print summary
echo -e "\n${GREEN}Optimization complete!${NC}"
echo -e "Processed $TOTAL_FILES files"
echo -e "Total size reduction: $(numfmt --to=iec-i --suffix=B $TOTAL_SAVED) (${TOTAL_PERCENT}% savings)"
echo -e "Original size: $(numfmt --to=iec-i --suffix=B $TOTAL_ORIGINAL_SIZE)"
echo -e "New size: $(numfmt --to=iec-i --suffix=B $TOTAL_OPTIMIZED_SIZE)"

# Clean up
rm -rf "$TEMP_DIR"

echo -e "\n${YELLOW}Tip: For even better optimization, consider using a service like TinyPNG or Squoosh for critical images.${NC}"
