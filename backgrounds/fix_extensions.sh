#!/bin/bash

# Directory containing backgrounds
DIR="$HOME/dots/backgrounds/.config/backgrounds"

# Navigate to directory
cd "$DIR" || { echo "Directory not found"; exit 1; }

echo "Scanning $DIR for incorrect file extensions..."

# Loop through all files
for file in *; do
    # Skip if not a file
    [ -f "$file" ] || continue

    # Get file type
    type=$(file -b --mime-type "$file")
    
    # Get current extension (lowercase)
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    base="${file%.*}"

    case "$type" in
        "image/jpeg")
            if [[ "$ext" != "jpg" && "$ext" != "jpeg" ]]; then
                echo "Fixing $file -> $base.jpg"
                mv "$file" "$base.jpg"
            fi
            ;;
        "image/png")
            if [[ "$ext" != "png" ]]; then
                echo "Fixing $file -> $base.png"
                mv "$file" "$base.png"
            fi
            ;;
    esac
done

echo "Extension fix complete."
