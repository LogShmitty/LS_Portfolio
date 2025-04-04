#!/bin/bash

# optimize-images.sh
# A script to compress and optimize JPG and PNG images for web use
# Usage: ./optimize-images.sh [directory]

# Set default directory to current directory if not provided
TARGET_DIR="${1:-.}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
echo "Original sizes stored in $TEMP_DIR/sizes.txt"

# Initialize counters
TOTAL_FILES=0
TOTAL_ORIGINAL_SIZE=0
TOTAL_OPTIMIZED_SIZE=0

# Process JPG files
echo -e "${YELLOW}Processing JPEG files...${NC}"
find "$TARGET_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | while IFS= read -r -d '' file; do
    # Get original file size
    ORIGINAL_SIZE=$(stat -f %z "$file")
    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + ORIGINAL_SIZE))
    
    echo "Optimizing: $file"
    
    # Optimize JPEG
    jpegoptim --strip-all --max=85 "$file"
    
    # Get new file size
    NEW_SIZE=$(stat -f %z "$file")
    TOTAL_OPTIMIZED_SIZE=$((TOTAL_OPTIMIZED_SIZE + NEW_SIZE))
    
    # Calculate savings
    SAVED=$((ORIGINAL_SIZE - NEW_SIZE))
    PERCENT=$(awk "BEGIN {printf \"%.2f\", ($SAVED / $ORIGINAL_SIZE) * 100}")
    
    echo -e "  ${GREEN}Reduced from $(numfmt --to=iec-i --suffix=B $ORIGINAL_SIZE) to $(numfmt --to=iec-i --suffix=B $NEW_SIZE) (${PERCENT}% savings)${NC}"
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
done

# Process PNG files
echo -e "${YELLOW}Processing PNG files...${NC}"
find "$TARGET_DIR" -type f -iname "*.png" -print0 | while IFS= read -r -d '' file; do
    # Get original file size
    ORIGINAL_SIZE=$(stat -f %z "$file")
    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + ORIGINAL_SIZE))
    
    echo "Optimizing: $file"
    
    # Create a temporary file for the optimized version
    TEMP_FILE="${file%.png}-optimized.png"
    
    # Optimize PNG with pngquant
    pngquant --force --quality=65-85 --output "$TEMP_FILE" "$file"
    
    # Check if optimization was successful and the file is smaller
    if [ -f "$TEMP_FILE" ]; then
        TEMP_SIZE=$(stat -f %z "$TEMP_FILE")
        
        # Only replace if the new file is smaller
        if [ "$TEMP_SIZE" -lt "$ORIGINAL_SIZE" ]; then
            mv "$TEMP_FILE" "$file"
            NEW_SIZE=$TEMP_SIZE
        else
            rm "$TEMP_FILE"
            NEW_SIZE=$ORIGINAL_SIZE
            echo -e "  ${YELLOW}Skipped: Optimized version was not smaller${NC}"
        fi
    else
        NEW_SIZE=$ORIGINAL_SIZE
        echo -e "  ${RED}Error: pngquant failed to process this file${NC}"
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
