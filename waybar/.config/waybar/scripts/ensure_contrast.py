import sys
import os
import re
import random

FALLBACK_BLACK = "#2E3138"
FALLBACK_WHITE = "#FFF8F0"
CONTRAST_THRESHOLD = 4.5

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 8: # Handle alpha
        hex_color = hex_color[:6]
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def luminance(r, g, b):
    a = [x / 255.0 for x in [r, g, b]]
    a = [((x + 0.055) / 1.055) ** 2.4 if x > 0.03928 else x / 12.92 for x in a]
    return 0.2126 * a[0] + 0.7152 * a[1] + 0.0722 * a[2]

def contrast(rgb1, rgb2):
    lum1 = luminance(*rgb1)
    lum2 = luminance(*rgb2)
    brightest = max(lum1, lum2)
    darkest = min(lum1, lum2)
    return (brightest + 0.05) / (darkest + 0.05)

def get_best_text_color(bg_hex, palette_darkest, palette_lightest):
    try:
        bg_rgb = hex_to_rgb(bg_hex)
        p_dark_rgb = hex_to_rgb(palette_darkest)
        p_light_rgb = hex_to_rgb(palette_lightest)
        f_dark_rgb = hex_to_rgb(FALLBACK_BLACK)
        f_light_rgb = hex_to_rgb(FALLBACK_WHITE)
    except:
        return FALLBACK_WHITE

    # Calculate contrasts
    c_p_dark = contrast(bg_rgb, p_dark_rgb)
    c_p_light = contrast(bg_rgb, p_light_rgb)
    c_f_dark = contrast(bg_rgb, f_dark_rgb)
    c_f_light = contrast(bg_rgb, f_light_rgb)

    # Determine best potential contrast for dark vs light side
    max_dark_contrast = max(c_p_dark, c_f_dark)
    max_light_contrast = max(c_p_light, c_f_light)

    if max_light_contrast > max_dark_contrast:
        # Prefer light text
        if c_p_light >= CONTRAST_THRESHOLD:
            return palette_lightest
        else:
            return FALLBACK_WHITE
    else:
        # Prefer dark text
        if c_p_dark >= CONTRAST_THRESHOLD:
            return palette_darkest
        else:
            return FALLBACK_BLACK

def get_palette_extremes(colors):
    valid_colors = []
    for c in colors:
        c_hex = c
        if len(c) == 9:
            c_hex = c[:7]
        try:
            rgb = hex_to_rgb(c_hex)
            lum = luminance(*rgb)
            valid_colors.append((c_hex, lum))
        except:
            continue
    
    if not valid_colors:
        return FALLBACK_BLACK, FALLBACK_WHITE

    valid_colors.sort(key=lambda x: x[1])
    return valid_colors[0][0], valid_colors[-1][0]

def process_colors(colors):
    darkest, lightest = get_palette_extremes(colors)
    output = []
    for i, color in enumerate(colors):
        hex_color = color
        if len(hex_color) == 9:
            hex_color = hex_color[:7]
            
        text_color = get_best_text_color(hex_color, darkest, lightest)
        output.append(f"@define-color color-{i} {hex_color};")
        output.append(f"@define-color text-color-{i} {text_color};")
    return "\n".join(output)

def get_current_theme_path():
    theme_link = os.path.expanduser("~/.config/theme/theme.css")
    if not os.path.exists(theme_link):
        return None
    
    with open(theme_link, 'r') as f:
        content = f.read()
        # Match @import url("path"); OR /* Theme Source: path */
        match = re.search(r'@import url\("([^"]+)"\);', content)
        if match:
            return match.group(1)
        
        match_comment = re.search(r'/\* Theme Source: (.+) \*/', content)
        if match_comment:
            return match_comment.group(1).strip()
            
    return None

def parse_css_variables(file_path):
    colors = []
    if not os.path.exists(file_path):
        return colors
        
    with open(file_path, 'r') as f:
        content = f.read()
        # Simple regex for --name: value;
        matches = re.findall(r'--[\w-]+:\s*(#[0-9a-fA-F]{6,8});', content)
        for value in matches:
            colors.append(value)
    return colors

def generate_gtk_css(file_path):
    colors = parse_css_variables(file_path)
    
    # Ensure we have at least 5 colors if possible
    num_colors = len(colors)
    if num_colors == 0:
        return "/* No colors found in theme */"
    
    darkest, lightest = get_palette_extremes(colors)
    
    # Shuffle for random selection
    random.shuffle(colors)
    
    output = []
    output.append(f"/* Theme Source: {file_path} */")
    
    for i, hex_color in enumerate(colors):
        # Strip alpha from the output color to ensure compatibility
        if len(hex_color) == 9: # #RRGGBBAA
            hex_color = hex_color[:7]

        text_color = get_best_text_color(hex_color, darkest, lightest)
        
        output.append(f"@define-color color-{i} {hex_color};")
        output.append(f"@define-color text-color-{i} {text_color};")
    
    return "\n".join(output)

def process_theme_colors():
    theme_path = get_current_theme_path()
    if not theme_path:
        return "/* No theme found */"
    return generate_gtk_css(theme_path)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if os.path.isfile(arg):
            print(generate_gtk_css(arg))
        else:
            print(process_colors(sys.argv[1:]))
    else:
        print(process_theme_colors())
