#!/bin/bash

# Fixed Chrysaki palette — no wallpaper extraction needed.
# palette.css is static; this script only re-applies it to all apps.

DIR="$HOME/dots/styles"
THEME="palette.css"

echo "Applying Chrysaki palette..."

# Update the theme.css by generating GTK CSS from the palette
python3 "$HOME/.config/waybar/scripts/ensure_contrast.py" "$DIR/$THEME" > "$HOME/.config/theme/theme.css"

# Update Hyprland colors
python3 "$HOME/.config/hypr/scripts/update_colors.py" "$HOME/.config/theme/theme.css" "$HOME/.config/hypr/colors.conf"

# Update SwayNC colors
python3 "$HOME/dots/swaync/scripts/update_colors.py"
swaync-client -rs

# Update Rofi colors
python3 "$HOME/dots/rofi/scripts/update_colors.py"

# Update Ghostty colors
python3 "$HOME/dots/ghostty/scripts/update_colors.py"

# Update Lazygit colors
python3 "$HOME/.config/lazygit/scripts/update_colors.py"

# Update GTK colors
python3 "$HOME/dots/gtk/scripts/update_colors.py"

# Restart waybar to ensure GTK theme is picked up
pkill waybar
sleep 0.5
waybar > /tmp/waybar.log 2>&1 &

echo "Theme applied successfully!"
