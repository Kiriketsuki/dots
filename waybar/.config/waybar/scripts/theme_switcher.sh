#!/bin/bash
DIR="$HOME/dots/styles"
# List files in the styles directory and use rofi to select one
THEME=$(find "$DIR" -maxdepth 1 -name "*.css" -printf "%f\n" | rofi -dmenu -p "Select Theme")

if [ -n "$THEME" ]; then
    # Update the theme.css by generating GTK CSS from the selected theme
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
fi
