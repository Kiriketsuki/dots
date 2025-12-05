import sys
import os
import re
import random

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

def get_best_text_color(bg_hex):
    try:
        bg_rgb = hex_to_rgb(bg_hex)
    except:
        return "#ffffff" # Fallback
    white_rgb = (255, 255, 255)
    black_rgb = (0, 0, 0)
    
    contrast_white = contrast(bg_rgb, white_rgb)
    contrast_black = contrast(bg_rgb, black_rgb)
    
    return "#ffffff" if contrast_white > contrast_black else "#000000"

def process_colors(colors):
    output = []
    for i, color in enumerate(colors):
        text_color = get_best_text_color(color)
        output.append(f"@define-color color-{i} {color};")
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
    
    # Shuffle for random selection
    random.shuffle(colors)
    
    output = []
    output.append(f"/* Theme Source: {file_path} */")
    
    for i, hex_color in enumerate(colors):
        # Strip alpha from the output color to ensure compatibility
        if len(hex_color) == 9: # #RRGGBBAA
            hex_color = hex_color[:7]

        text_color = get_best_text_color(hex_color)
        
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
