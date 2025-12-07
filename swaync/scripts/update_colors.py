import os

def generate_css():
    # Deterministic mapping to match rofi theme
    # rofi background -> color-0
    # rofi background-alt -> color-1
    # rofi selected -> color-2
    # rofi active -> color-3
    # rofi urgent -> color-4
    
    # Resolve background image
    bg_path = os.path.expanduser("~/.config/backgrounds/.current_rofi")
    if os.path.islink(bg_path):
        bg_path = os.readlink(bg_path)
        if not os.path.isabs(bg_path):
            bg_path = os.path.join(os.path.dirname(os.path.expanduser("~/.config/backgrounds/.current_rofi")), bg_path)
    
    # Ensure it's a valid URI
    bg_uri = f"file://{bg_path}"
    
    css_content = f"""
:root {{
    --cc-bg: alpha(@color-0, 0.85);
    --noti-border-color: alpha(@color-2, 0.5);
    --noti-bg: @color-1;
    --noti-bg-darker: @color-0;
    --noti-bg-hover: @color-2;
    --noti-bg-focus: alpha(@color-2, 0.6);
    --noti-close-bg: @color-3;
    --noti-close-bg-hover: @color-4;
    --bg-selected: @color-2;
    
    --text-color: @text-color-1;
    --text-color-disabled: alpha(@text-color-1, 0.5);
    
    --cc-bg-image: url("{bg_uri}");
}}
"""
    return css_content

def main():
    config_dir = os.path.expanduser("~/.config/swaync")
    os.makedirs(config_dir, exist_ok=True)
    
    output_file = os.path.join(config_dir, "swaync_colors.css")
    
    with open(output_file, "w") as f:
        f.write(generate_css())

if __name__ == "__main__":
    main()
