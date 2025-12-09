# Dotfiles

My personal configuration files (dotfiles), managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

-   **alacritty/**: Alacritty terminal emulator configuration
-   **backgrounds/**: Wallpapers and background images
-   **bash/**: Bash shell configuration
-   **Code/**: VS Code editor configuration
-   **fontconfig/**: Font configuration files
-   **git/**: Git configuration and settings
-   **hypr/**: Hyprland, Hyprlock, and Hypridle configuration
-   **mpd/**: Music Player Daemon configuration
-   **nvim/**: Neovim text editor configuration
-   **rofi/**: Rofi application launcher configuration (includes powermenu scripts)
-   **spicetify/**: Spicetify (Spotify customization) configuration
-   **styles/**: Theme CSS files (deep ocean blue, pastel, sunny beach day)
-   **swaync/**: Sway Notification Center configuration
-   **theme/**: System theme configuration
-   **waybar/**: Waybar status bar configuration
-   **xdg-desktop-portal/**: XDG Desktop Portal configuration
-   **yazi/**: Yazi file manager configuration
-   **zsh/**: Zsh shell configuration

## Requirements

-   [GNU Stow](https://www.gnu.org/software/stow/)
-   git

## Installing Applications

### Arch Linux

```sh
# Core dependencies
sudo pacman -S git stow

# Shell
sudo pacman -S bash zsh

# Terminal
sudo pacman -S alacritty

# Editors
sudo pacman -S neovim code

# Hyprland ecosystem (Wayland compositor)
sudo pacman -S hyprland hyprlock hypridle

# Status bar and notifications
sudo pacman -S waybar swaync

# Application launcher and widgets
sudo pacman -S rofi

# File manager
sudo pacman -S yazi

# Music
sudo pacman -S mpd

# Font configuration
sudo pacman -S fontconfig

# XDG Desktop Portal
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland

# Spotify customization (Spicetify - install from AUR)
yay -S spicetify-cli
```

### Ubuntu

```sh
# Core dependencies
sudo apt update
sudo apt install git stow

# Shell
sudo apt install bash zsh

# Terminal
sudo apt install alacritty

# Editors
sudo apt install neovim
# VS Code - install via Microsoft's official repository
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install code

# Hyprland ecosystem (requires additional repositories on Ubuntu)
# Note: Hyprland is not officially supported on Ubuntu. Consider using a PPA or building from source.
# See: https://wiki.hyprland.org/Getting-Started/Installation/

# Waybar
sudo apt install waybar

# Sway Notification Center
sudo apt install swaync

# Rofi
sudo apt install rofi

# Yazi (file manager - may need to build from source or use cargo)
cargo install --locked yazi-fm

# MPD
sudo apt install mpd

# Font configuration
sudo apt install fontconfig

# XDG Desktop Portal
sudo apt install xdg-desktop-portal xdg-desktop-portal-gtk

# Spicetify (install manually)
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
```

> **Note:** Hyprland and its related tools (hyprlock, hypridle) have limited support on Ubuntu. For the best experience with Hyprland, consider using Arch Linux or another rolling-release distribution.

## Installation

1. Clone this repository:

    ```sh
    git clone https://github.com/Kiriketsuki/dots.git ~/dots
    cd ~/dots
    ```

2. Install configurations using stow:

    ```sh
    # Install everything
    stow .

    # Or install specific packages
    stow zsh nvim hypr waybar alacritty rofi swaync yazi
    ```

    By default, stow will create symlinks in the parent directory (`../`), which should be your home directory if you cloned into `~/dots`.

## Features

-   **Theme System**: Multiple CSS themes available in `styles/` (deep ocean blue, pastel, sunny beach day)
-   **Custom Scripts**: Power menu and color update scripts in `rofi/` and `swaync/`
-   **Hyprland Setup**: Complete Wayland compositor configuration with lock screen and idle management
-   **Modern Terminal**: Configured Alacritty with custom themes
-   **Development Ready**: Neovim and VS Code configurations included

## Management

-   **Update**: `git pull` inside the directory.
-   **Uninstall a package**: `stow -D <package>` (e.g., `stow -D nvim`).
-   **Reinstall a package**: `stow -R <package>` (restow - useful after updates).
