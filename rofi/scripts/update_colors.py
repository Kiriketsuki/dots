#!/usr/bin/env python3
import re
import os

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 3:
        hex_color = ''.join([c*2 for c in hex_color])
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def relative_luminance(rgb):
    rs, gs, bs = [x / 255.0 for x in rgb]
    rs = rs / 12.92 if rs <= 0.03928 else ((rs + 0.055) / 1.055) ** 2.4
    gs = gs / 12.92 if gs <= 0.03928 else ((gs + 0.055) / 1.055) ** 2.4
    bs = bs / 12.92 if bs <= 0.03928 else ((bs + 0.055) / 1.055) ** 2.4
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs

def contrast_ratio(c1, c2):
    l1 = relative_luminance(hex_to_rgb(c1))
    l2 = relative_luminance(hex_to_rgb(c2))
    if l1 > l2:
        return (l1 + 0.05) / (l2 + 0.05)
    else:
        return (l2 + 0.05) / (l1 + 0.05)

def get_best_text_color(bg_color, preferred_text_color="#ffffff"):
    if contrast_ratio(bg_color, preferred_text_color) >= 4.5:
        return preferred_text_color
    white_contrast = contrast_ratio(bg_color, "#ffffff")
    black_contrast = contrast_ratio(bg_color, "#000000")

    if white_contrast >= 4.5 and white_contrast > black_contrast:
        return "#ffffff"
    if black_contrast >= 4.5 and black_contrast > white_contrast:
        return "#000000"

    return "#ffffff" if white_contrast > black_contrast else "#000000"

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

    fg = get_best_text_color(bg, fg_pref)
    fg_selected = get_best_text_color(selected, fg_pref)
    fg_active = get_best_text_color(active, fg_pref)
    fg_urgent = get_best_text_color(urgent, fg_pref)

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
