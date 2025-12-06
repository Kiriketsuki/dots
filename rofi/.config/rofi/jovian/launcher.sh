#!/usr/bin/env bash

## Rofi Launcher Script

dir="$(dirname "$(readlink -f "$0")")"
theme='theme'
theme_css="$HOME/.config/theme/theme.css"
colors_rasi="${dir}/colors.rasi"

# Generate colors.rasi
if [ -f "$theme_css" ]; then
    # Helper to extract color
    get_color() {
        grep "@define-color $1 " "$theme_css" | awk '{print $3}' | tr -d ';'
    }

    bg=$(get_color "color-0")
    bg_alt=$(get_color "color-3")
    fg=$(get_color "text-color-0")
    selected=$(get_color "color-1")
    active=$(get_color "color-5")
    urgent=$(get_color "color-9")

    cat > "$colors_rasi" <<EOF
* {
    background:     $bg;
    background-alt: $bg_alt;
    foreground:     $fg;
    selected:       $selected;
    active:         $active;
    urgent:         $urgent;
}
EOF
else
    echo "Theme CSS not found at $theme_css, using default colors if available."
fi

## Run
rofi \
    -show drun \
    -theme "${dir}/${theme}.rasi"
