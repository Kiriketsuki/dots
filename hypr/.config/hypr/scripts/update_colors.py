#!/usr/bin/env python3
"""Deterministic Hyprland border colors from Chrysaki theme.

Active:   emerald → amethyst 45deg gradient
Inactive: blue dimmed
"""
import re
import os
import sys


def generate_colors(theme_path, output_path):
    try:
        with open(theme_path, 'r') as f:
            content = f.read()

        colors = {}
        for m in re.finditer(r'@define-color\s+(chrysaki-[\w-]+)\s+(#[0-9a-fA-F]{6,8});', content):
            colors[m.group(1)] = m.group(2)

        if not colors:
            print(f"No colors found in {theme_path}")
            return

        emerald = colors.get("chrysaki-emerald", "#14664e").lstrip('#')
        amethyst = colors.get("chrysaki-amethyst", "#3a2068").lstrip('#')
        blue = colors.get("chrysaki-blue", "#122858").lstrip('#')

        config_content = f"""general {{
    col.active_border = rgba({emerald}ee) rgba({amethyst}ee) 45deg
    col.inactive_border = rgba({blue}aa)
}}
"""
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'w') as f:
            f.write(config_content)

        print(f"Updated {output_path} with deterministic Chrysaki borders")

        try:
            import subprocess
            subprocess.run(["hyprctl", "keyword", "general:col.active_border",
                            f"rgba({emerald}ee) rgba({amethyst}ee) 45deg"], check=False)
            subprocess.run(["hyprctl", "keyword", "general:col.inactive_border",
                            f"rgba({blue}aa)"], check=False)
        except Exception:
            pass

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    default_theme = os.path.expanduser("~/.config/theme/theme.css")
    default_output = os.path.expanduser("~/.config/hypr/colors.conf")

    theme = sys.argv[1] if len(sys.argv) > 1 else default_theme
    output = sys.argv[2] if len(sys.argv) > 2 else default_output

    generate_colors(theme, output)
