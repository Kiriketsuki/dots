#!/bin/bash

# Re-apply the Chrysaki theme to all apps.
# With a single palette, there's nothing to "switch" — just regenerate.

"$HOME/dots/hypr/.config/hypr/scripts/generate_and_apply_palette.sh"

# Reload waybar style
pkill -SIGUSR2 waybar
pkill -RTMIN+1 waybar
