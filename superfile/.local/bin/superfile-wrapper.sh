#!/bin/sh
# Superfile wrapper for xdg-desktop-portal-termfilechooser.
# Mirrors yazi-wrapper.sh. Uses ghostty with a dedicated title so
# Hyprland floats it through the filepicker-float window rule.

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

cmd="/usr/bin/spf"
termcmd="ghostty"
term_title="File Picker"

# Start from the focused window's working directory when we can find it.
start_dir=""
if command -v hyprctl >/dev/null 2>&1; then
    pid=$(hyprctl activewindow -j 2>/dev/null | sed -n 's/.*"pid":\s*\([0-9]*\).*/\1/p')
    if [ -n "$pid" ] && [ -d "/proc/$pid/cwd" ]; then
        start_dir=$(readlink "/proc/$pid/cwd" 2>/dev/null)
    fi
fi
if [ -z "$start_dir" ] || [ "$start_dir" = "/" ]; then
    if [ "$save" != "1" ]; then
        start_dir="$HOME/Downloads"
    else
        start_dir="$HOME"
    fi
fi

if [ "$save" = "1" ] && [ -n "$path" ]; then
    if [ ! -e "$path" ]; then
        touch "$path"
    fi
    "$termcmd" --title="$term_title" -e "$cmd" --chooser-file="$out" "$path"
else
    "$termcmd" --title="$term_title" -e "$cmd" --chooser-file="$out" "$start_dir"
fi
