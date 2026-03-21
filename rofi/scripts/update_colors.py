#!/usr/bin/env python3
import re
import os

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 3:
        hex_color = ''.join([c*2 for c in hex_color])
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def main():
    theme_path = os.path.expanduser("~/.config/theme/theme.css")
    output_path = os.path.expanduser("~/.config/rofi/jovian/colors.rasi")

    if not os.path.exists(theme_path):
        print(f"Error: {theme_path} not found")
        return

    with open(theme_path, 'r') as f:
        content = f.read()

    colors = {}
    matches = re.findall(r'@define-color\s+(chrysaki-[\w-]+)\s+(#[0-9a-fA-F]{6,8});', content)
    for name, color in matches:
        colors[name] = color

    text_colors = {}
    matches_text = re.findall(r'@define-color\s+(text-chrysaki-[\w-]+)\s+(#[0-9a-fA-F]{6,8});', content)
    for name, color in matches_text:
        text_colors[name] = color

    if not colors:
        print("No colors found")
        return

    def get_color(name, fallback="#000000"):
        return colors.get(f"chrysaki-{name}", fallback)

    def get_text_color(name, fallback="#ffffff"):
        return text_colors.get(f"text-chrysaki-{name}", fallback)

    bg = get_color("base")
    bg_alt = get_color("raised")
    fg_pref = get_text_color("base")
    selected = get_color("teal")
    active = get_color("emerald")
    urgent = get_color("blonde")

    fg = fg_pref
    fg_selected = get_text_color("teal")
    fg_active = get_text_color("emerald")
    fg_urgent = get_text_color("blonde")

    bg_rgb = hex_to_rgb(bg)
    bg_alpha = f"rgba({bg_rgb[0]}, {bg_rgb[1]}, {bg_rgb[2]}, 0.85)"

    rasi_content = f"""* {{
    background:     {bg};
    background-alt: {bg_alt};
    background-alpha: {bg_alpha};
    foreground:     {fg};
    selected:       {selected};
    active:         {active};
    urgent:         {urgent};

    foreground-selected: {fg_selected};
    foreground-active:   {fg_active};
    foreground-urgent:   {fg_urgent};
}}
"""

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(rasi_content)

    print(f"Updated {output_path}")

if __name__ == "__main__":
    main()
