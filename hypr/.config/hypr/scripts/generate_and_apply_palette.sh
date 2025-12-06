#!/bin/bash

# Get the current wallpaper
CURRENT_WALLPAPER="$HOME/.config/backgrounds/.current_wallpaper"

if [ ! -f "$CURRENT_WALLPAPER" ]; then
    echo "Error: No current wallpaper found at $CURRENT_WALLPAPER"
    exit 1
fi

echo "Generating palette from current wallpaper: $(readlink -f "$CURRENT_WALLPAPER")"

# Generate palette.css using KiColour
# Assumes KiColour binary is in PATH or provide full path
KiColour -c "$CURRENT_WALLPAPER" "$HOME/dots/styles/palette.css"

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate palette"
    exit 1
fi

echo "Palette generated successfully at ~/dots/styles/palette.css"

# Now apply the palette using the theme switcher logic
DIR="$HOME/dots/styles"
THEME="palette.css"

echo "Applying palette theme..."

# Update the theme.css by generating GTK CSS from the palette
python3 "$HOME/.config/waybar/scripts/ensure_contrast.py" "$DIR/$THEME" > "$HOME/.config/theme/theme.css"

# Update Hyprland colors
python3 "$HOME/.config/hypr/scripts/update_colors.py" "$HOME/.config/theme/theme.css" "$HOME/.config/hypr/colors.conf"

# Update SwayNC colors
python3 "$HOME/dots/swaync/scripts/update_colors.py"
swaync-client -rs

# Update Rofi colors
python3 "$HOME/dots/rofi/scripts/update_colors.py"

# Reload waybar style
pkill -SIGUSR2 waybar
# Signal the theme module to update (assuming signal 1 is used)
pkill -RTMIN+1 waybar

echo "Theme applied successfully!"
