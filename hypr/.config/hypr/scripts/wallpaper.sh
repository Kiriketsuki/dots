#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/backgrounds"
CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"

# Kill hyprpaper if running
pkill hyprpaper

# Wait a moment to ensure it's dead
sleep 0.5

# Get list of monitors
# We use hyprctl to get connected monitors. 
# If hyprctl isn't ready or returns nothing, we might need a fallback, 
# but usually exec-once runs when hyprctl is ready.
MONITORS=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')

# Start generating config
# ipc = on allows controlling hyprpaper at runtime if needed later
echo "ipc = on" > "$CONFIG_FILE"
echo "splash = false" >> "$CONFIG_FILE"

# Keep track of preloaded wallpapers to avoid duplicates in config
declare -A PRELOADED

for monitor in $MONITORS; do
    # Select random wallpaper
    # We filter for common image formats
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
    
    if [ -n "$WALLPAPER" ]; then
        # Preload if not already preloaded
        if [ -z "${PRELOADED[$WALLPAPER]}" ]; then
            echo "preload = $WALLPAPER" >> "$CONFIG_FILE"
            PRELOADED[$WALLPAPER]=1
        fi
        
        # Set wallpaper for monitor
        echo "wallpaper = $monitor,$WALLPAPER" >> "$CONFIG_FILE"
    fi
done

# Start hyprpaper as a daemon
hyprpaper &
