#!/bin/bash

# Chrysaki single-source theme pipeline.
# Reads _palette.scss → generates theme.css → updates all app colors.

SCSS_SOURCE="$HOME/dots/chrysaki/ags/.config/ags/styles/_palette.scss"
BRIDGE="$HOME/dots/theme/scripts/generate_theme_css.py"

echo "Applying Chrysaki palette..."

# Generate theme.css from Chrysaki SCSS source
python3 "$BRIDGE" "$SCSS_SOURCE" "$HOME/.config/theme/theme.css"

# Update Hyprland colors
python3 "$HOME/.config/hypr/scripts/update_colors.py" "$HOME/.config/theme/theme.css" "$HOME/.config/hypr/colors.conf"

# Update Rofi colors
python3 "$HOME/dots/rofi/scripts/update_colors.py"

# Update Ghostty colors
python3 "$HOME/dots/ghostty/scripts/update_colors.py"

# Update Lazygit colors
python3 "$HOME/.config/lazygit/scripts/update_colors.py"

# Update GTK colors
python3 "$HOME/dots/gtk/scripts/update_colors.py"

# Update SwayNC colors
python3 "$HOME/dots/swaync/scripts/update_colors.py"
swaync-client -rs 2>/dev/null || true

# Restart AGS bar to pick up new theme
ags quit chrysaki-bar 2>/dev/null || true
sleep 0.5
ags run ~/.config/ags/app.ts > /tmp/ags.log 2>&1 &

echo "Theme applied successfully!"
