#!/bin/bash

# Get a random wallpaper
WALLPAPER=$(find ~/.config/backgrounds/ -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

# Update the symlink to the current wallpaper
ln -sf "$WALLPAPER" ~/.config/backgrounds/.current_wallpaper

# Run hyprlock
hyprlock
