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

# Get all wallpapers into an array, shuffled
mapfile -t WALLPAPERS < <(find -L "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf)

COUNT=${#WALLPAPERS[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "Warning: No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Assign wallpapers for Lock and Rofi
WP_LOCK="${WALLPAPERS[0]}"
WP_ROFI="${WALLPAPERS[$((1 % COUNT))]}"

echo "Setting Lock wallpaper: $WP_LOCK"
ln -sf "$WP_LOCK" "$HOME/.config/backgrounds/.current_lock"

echo "Setting Rofi wallpaper: $WP_ROFI"
ln -sf "$WP_ROFI" "$HOME/.config/backgrounds/.current_rofi"

# Start picking monitor wallpapers from index 2
IDX=2

for monitor in $MONITORS; do
    # Select wallpaper for this monitor
    WP_INDEX=$((IDX % COUNT))
    WALLPAPER="${WALLPAPERS[$WP_INDEX]}"
    
    if [ -n "$WALLPAPER" ]; then
        echo "Setting wallpaper for $monitor to $WALLPAPER"
        
        # Preload the new wallpaper
        hyprctl hyprpaper preload "$WALLPAPER"
        
        # Set the wallpaper
        hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER"

        # Update current wallpaper symlink (will point to the last monitor processed)
        ln -sf "$WALLPAPER" "$HOME/.config/backgrounds/.current_wallpaper"
        
        IDX=$((IDX + 1))
    fi
done

# Unload unused wallpapers to save memory
# This removes preloads for wallpapers not currently in use
hyprctl hyprpaper unload unused

# Generate and apply palette from the current wallpaper
echo "Generating palette from wallpaper..."
"$HOME/dots/hypr/.config/hypr/scripts/generate_and_apply_palette.sh"
