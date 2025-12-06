#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/backgrounds"

# Check if hyprpaper is running, start it if not
if ! pgrep -x "hyprpaper" > /dev/null; then
    echo "Starting hyprpaper..."
    hyprpaper &
    sleep 1
fi

# Get list of monitors
MONITORS=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')

if [ -z "$MONITORS" ]; then
    echo "Error: No monitors found!"
    exit 1
fi

for monitor in $MONITORS; do
    # Select random wallpaper
    # Use -L to follow symlinks if WALLPAPER_DIR is a symlink
    WALLPAPER=$(find -L "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
    
    if [ -n "$WALLPAPER" ]; then
        echo "Setting wallpaper for $monitor to $WALLPAPER"
        
        # Preload the new wallpaper
        hyprctl hyprpaper preload "$WALLPAPER"
        
        # Set the wallpaper
        hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER"

        # Update current wallpaper symlink for Rofi
        ln -sf "$WALLPAPER" "$HOME/.config/backgrounds/.current_wallpaper"
    else
        echo "Warning: No wallpapers found in $WALLPAPER_DIR"
    fi
done

# Unload unused wallpapers to save memory
# This removes preloads for wallpapers not currently in use
hyprctl hyprpaper unload unused
