import os

def generate_css():
    bg_path = os.path.expanduser("~/.config/backgrounds/.current_rofi")
    if os.path.islink(bg_path):
        bg_path = os.readlink(bg_path)
        if not os.path.isabs(bg_path):
            bg_path = os.path.join(os.path.dirname(os.path.expanduser("~/.config/backgrounds/.current_rofi")), bg_path)

    bg_uri = f"file://{bg_path}"

    css_content = f"""
:root {{
    --cc-bg: alpha(@chrysaki-base, 0.85);
    --noti-border-color: alpha(@chrysaki-teal, 0.5);
    --noti-bg: @chrysaki-raised;
    --noti-bg-darker: @chrysaki-base;
    --noti-bg-hover: @chrysaki-teal;
    --noti-bg-focus: alpha(@chrysaki-teal, 0.6);
    --noti-close-bg: @chrysaki-emerald;
    --noti-close-bg-hover: @chrysaki-blonde;
    --bg-selected: @chrysaki-teal;

    --text-color: @text-chrysaki-raised;
    --text-color-disabled: alpha(@text-chrysaki-raised, 0.5);

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
