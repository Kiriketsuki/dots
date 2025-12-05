#!/usr/bin/env python3
import re
import random
import os
import sys

def generate_colors(theme_path, output_path):
    try:
        # Check if update is needed
        if os.path.exists(output_path) and os.path.exists(theme_path):
            if os.path.getmtime(output_path) > os.path.getmtime(theme_path):
                print("Colors are up to date. Skipping update.")
                return

        with open(theme_path, 'r') as f:
            content = f.read()
        
        # Extract colors defined as @define-color color-N #HEX;
        colors = re.findall(r'@define-color\s+color-\d+\s+(#[0-9a-fA-F]{6});', content)
        
        if not colors:
            print(f"No colors found in {theme_path}")
            return

        # Pick random colors
        c1 = random.choice(colors).strip('#')
        c2 = random.choice(colors).strip('#')
        inactive = random.choice(colors).strip('#')

        config_content = f"""general {{
    col.active_border = rgba({c1}ee) rgba({c2}ee) 45deg
    col.inactive_border = rgba({inactive}aa)
}}
"""
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'w') as f:
            f.write(config_content)
        
        print(f"Updated {output_path} with colors from {theme_path}")

        # Apply changes immediately using hyprctl if available
        try:
            import subprocess
            subprocess.run(["hyprctl", "keyword", "general:col.active_border", f"rgba({c1}ee) rgba({c2}ee) 45deg"], check=False)
            subprocess.run(["hyprctl", "keyword", "general:col.inactive_border", f"rgba({inactive}aa)"], check=False)
        except Exception:
            pass

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Default paths
    default_theme = os.path.expanduser("~/.config/theme/theme.css")
    default_output = os.path.expanduser("~/.config/hypr/colors.conf")

    theme = sys.argv[1] if len(sys.argv) > 1 else default_theme
    output = sys.argv[2] if len(sys.argv) > 2 else default_output

    generate_colors(theme, output)
