#!/bin/bash
if [ -f "$HOME/.config/theme/theme.css" ]; then
    # Try to find Theme Source comment
    THEME=$(grep -oP 'Theme Source: \K.*' "$HOME/.config/theme/theme.css")
    if [ -z "$THEME" ]; then
        # Fallback to old import style
        THEME=$(grep -oP 'styles/\K[^"]+' "$HOME/.config/theme/theme.css")
    fi
    echo "$(basename "${THEME%.css}")"
else
    echo "Unknown"
fi
