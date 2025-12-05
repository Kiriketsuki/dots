import random
import os

def generate_css():
    indices = list(range(10))
    random.shuffle(indices)
    
    # Mapping variables to random colors
    # We use the shuffled indices to pick colors
    
    css_content = f"""
:root {{
    --cc-bg: alpha(@color-{indices[0]}, 0.7);
    --noti-border-color: alpha(@color-{indices[1]}, 0.5);
    --noti-bg: @color-{indices[2]};
    --noti-bg-darker: @color-{indices[3]};
    --noti-bg-hover: @color-{indices[4]};
    --noti-bg-focus: alpha(@color-{indices[5]}, 0.6);
    --noti-close-bg: @color-{indices[6]};
    --noti-close-bg-hover: @color-{indices[7]};
    --bg-selected: @color-{indices[8]};
    
    /* Keep text color consistent with the main notification background if possible, 
       or just use text-color-0 as a safe default if the theme ensures it contrasts with everything.
       For now, let's try to match the notification background's text color. */
    --text-color: @text-color-{indices[2]};
    --text-color-disabled: alpha(@text-color-{indices[2]}, 0.5);
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
