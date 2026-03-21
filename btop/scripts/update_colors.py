#!/usr/bin/env python3
"""Generate btop Chrysaki theme from theme.css.

Reads @define-color tokens from ~/.config/theme/theme.css and emits
a btop .theme file at ~/.config/btop/themes/chrysaki.theme.
"""
import re
import os


def main():
    theme_path = os.path.expanduser("~/.config/theme/theme.css")
    output_path = os.path.expanduser("~/.config/btop/themes/chrysaki.theme")

    if not os.path.exists(theme_path):
        print(f"Error: {theme_path} not found")
        return

    with open(theme_path, 'r') as f:
        content = f.read()

    colors = {}
    matches = re.findall(r'@define-color\s+(chrysaki-[\w-]+)\s+(#[0-9a-fA-F]{6,8});', content)
    for name, color in matches:
        colors[name] = color

    if not colors:
        print("No colors found in theme.css")
        return

    def get(name, fallback="#000000"):
        return colors.get(f"chrysaki-{name}", fallback)

    output = f"""# btop Chrysaki theme — auto-generated
# Source: ~/.config/theme/theme.css (Chrysaki palette)
# Do not edit manually; run btop/scripts/update_colors.py to regenerate

# Main background, empty for terminal default
theme[main_bg]="{get('base', '#161821')}"

# Main text color
theme[main_fg]="{get('text-primary', '#e0e2ea')}"

# Title color for boxes
theme[title]="{get('text-primary', '#e0e2ea')}"

# Highlight color for keyboard shortcuts
theme[hi_fg]="{get('emerald-light', '#1a8a6a')}"

# Background color of selected item in processes box
theme[selected_bg]="{get('elevated', '#2e3142')}"

# Foreground color of selected item in processes box
theme[selected_fg]="{get('text-primary', '#e0e2ea')}"

# Color of inactive/disabled text
theme[inactive_fg]="{get('text-muted', '#6a6e82')}"

# Misc colors for processes box
theme[proc_misc]="{get('cerulean', '#3d95e0')}"

# Cpu box outline color
theme[cpu_box]="{get('emerald', '#14664e')}"

# Memory/disks box outline color
theme[mem_box]="{get('amethyst', '#3a2068')}"

# Net up/down box outline color
theme[net_box]="{get('teal', '#197278')}"

# Processes box outline color
theme[proc_box]="{get('blue', '#122858')}"

# Box divider line and small boxes line color
theme[div_line]="{get('border', '#363a4f')}"

# Temperature graph colors
theme[temp_start]="{get('teal', '#197278')}"
theme[temp_mid]="{get('blonde-dim', '#C4861C')}"
theme[temp_end]="{get('error', '#8C2F39')}"

# CPU graph colors
theme[cpu_start]="{get('emerald', '#14664e')}"
theme[cpu_mid]="{get('emerald-light', '#1a8a6a')}"
theme[cpu_end]="{get('blonde', '#FBB13C')}"

# Mem/Disk free meter
theme[free_start]="{get('emerald-dim', '#0e4a38')}"
theme[free_mid]="{get('emerald', '#14664e')}"
theme[free_end]="{get('emerald-light', '#1a8a6a')}"

# Mem/Disk cached meter
theme[cached_start]="{get('amethyst-dim', '#1e1040')}"
theme[cached_mid]="{get('amethyst', '#3a2068')}"
theme[cached_end]="{get('amethyst-light', '#583090')}"

# Mem/Disk available meter
theme[available_start]="{get('blue-dim', '#0c1a40')}"
theme[available_mid]="{get('blue', '#122858')}"
theme[available_end]="{get('cerulean', '#3d95e0')}"

# Mem/Disk used meter
theme[used_start]="{get('error-dim', '#5e1f25')}"
theme[used_mid]="{get('error', '#8C2F39')}"
theme[used_end]="{get('error-light', '#b53f4a')}"

# Download graph colors
theme[download_start]="{get('teal-dim', '#0f4f54')}"
theme[download_mid]="{get('teal', '#197278')}"
theme[download_end]="{get('teal-light', '#20969c')}"

# Upload graph colors
theme[upload_start]="{get('amethyst-dim', '#1e1040')}"
theme[upload_mid]="{get('amethyst', '#3a2068')}"
theme[upload_end]="{get('amethyst-light', '#583090')}"
"""

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(output)

    print(f"Updated {output_path}")


if __name__ == "__main__":
    main()
