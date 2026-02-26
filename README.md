# Dotfiles

My personal configuration files (dotfiles), managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

-   **alacritty/**: Alacritty terminal emulator configuration
-   **backgrounds/**: Wallpapers and background images
-   **bash/**: Bash shell configuration
-   **fontconfig/**: Font configuration files
-   **git/**: Git configuration and custom scripts (`git-gone`, `git-track-all`)
-   **gtk/**: GTK3 theme configuration
-   **hypr/**: Hyprland, Hyprlock, and Hypridle configuration + scripts
-   **mime/**: MIME type associations
-   **mpd/**: Music Player Daemon configuration
-   **rofi/**: Rofi launcher configuration and power menu script
-   **spicetify/**: Spicetify (Spotify customization) configuration
-   **styles/**: Theme CSS files (deep ocean blue, pastel, sunny beach day)
-   **swaync/**: Sway Notification Center configuration
-   **theme/**: Active theme pointer
-   **waybar/**: Waybar status bar configuration and theme switcher
-   **xdg-desktop-portal/**: XDG Desktop Portal configuration
-   **yazi/**: Yazi file manager configuration
-   **zsh/**: Zsh shell configuration (Zinit, Powerlevel10k, fzf, zoxide)

## Quick Install (Arch Linux)

```sh
git clone https://github.com/Kiriketsuki/dots.git ~/dots
cd ~/dots && bash bootstrap.sh
```

Then reboot. Hyprland will start automatically via TTY autologin.

## What the Bootstrap Script Does

1. Installs `git`, `stow`, `base-devel` via pacman
2. Builds and installs `yay` (AUR helper) if not present
3. Installs all required packages (see list below)
4. Enables NetworkManager
5. Installs `uv` (Python toolchain, required by `.zshrc`)
6. Backs up any conflicting existing config files
7. Stows all dotfile modules into `~/`
8. Sets `zsh` as the default shell
9. Disables any active display manager and sets up TTY autologin on tty1
10. Refreshes the font cache

## Packages Installed

| Category | Packages |
|----------|----------|
| Shell & Terminal | `zsh`, `alacritty` |
| Editors | `neovim`, `code` |
| Hyprland ecosystem | `hyprland`, `hyprlock`, `hypridle`, `hyprpaper` |
| Status & notifications | `waybar`, `swaync` |
| Launcher & file managers | `rofi-wayland`, `yazi`, `thunar` |
| Audio & media | `mpd`, `pipewire`, `wireplumber`, `playerctl` |
| Fonts | `ttf-iosevka-nerd` |
| Portals | `xdg-desktop-portal`, `xdg-desktop-portal-hyprland` |
| System tray | `network-manager-applet` |
| Screenshots | `hyprshot` |
| Shell tools | `fzf`, `zoxide`, `brightnessctl` |
| Spotify | `spicetify-cli` |

## Manual Installation

If you prefer to run steps manually:

1.  Clone this repository:

    ```sh
    git clone https://github.com/Kiriketsuki/dots.git ~/dots
    cd ~/dots
    ```

2.  Install packages (see table above), then enable services:

    ```sh
    sudo systemctl enable --now NetworkManager
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ```

3.  Back up any pre-existing configs that would conflict:

    ```sh
    mv ~/.bashrc ~/.bashrc.bak
    mv ~/.gitconfig ~/.gitconfig.bak
    mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak  # if hyprland was already set up
    ```

4.  Stow each package (do **not** use `stow .`):

    ```sh
    stow alacritty backgrounds bash fontconfig git gtk hypr mime mpd \
         rofi spicetify styles swaync theme waybar xdg-desktop-portal yazi zsh
    ```

    > **Note:** `rofi/`, `swaync/`, and `gtk/` each have a `scripts/` directory intentionally excluded from stow — those scripts are called directly from `~/dots/` by the theme system. `.stow-local-ignore` files in each module handle this.

5.  Set zsh as your default shell:

    ```sh
    chsh -s $(which zsh)
    ```

6.  Disable your display manager and enable TTY autologin:

    ```sh
    sudo systemctl disable lightdm  # or sddm/gdm
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
    [Service]
    ExecStart=
    ExecStart=-/sbin/agetty --autologin YOUR_USERNAME --noclear %I $TERM
    EOF
    ```

    Hyprland is launched automatically from `~/.zprofile` when you log into tty1.

7.  Refresh font cache:

    ```sh
    fc-cache -fv
    ```

## After First Boot

Set your wallpaper (this also generates the colour palette):

```sh
~/.config/hypr/scripts/wallpaper.sh
```

## GitHub / Git Setup

Run the interactive setup script to authenticate both GitHub accounts and configure SSH:

```sh
~/dots/git/gh-setup.sh
```

This will:
1. Log in to both GitHub accounts via `gh auth login` (browser-based, interactive)
2. Generate separate SSH keys (`~/.ssh/id_personal`, `~/.ssh/id_work`) and upload them to GitHub
3. Write `~/.ssh/config` with host aliases (`github.com-personal`, `github.com-work`)

Git identity and SSH key are then applied automatically per directory:

| Directory | Identity | SSH key |
|-----------|----------|---------|
| `~/dev/` | kiriketsuki | `id_personal` |
| `~/workdev/` | kiriketsuki (default) | `id_personal` |
| `~/workdev/Aurrigo/` | Jovian-Aurrigo | `id_work` |

When cloning work repos into the Aurrigo context, use the work SSH host alias so the right key is used:

```sh
git clone git@github.com-work:Aurrigo/repo.git ~/workdev/Aurrigo/repo
```

Personal repos clone normally:

```sh
git clone git@github.com:kiriketsuki/repo.git ~/dev/repo
```

## Features

-   **Theme System**: Multiple CSS themes in `styles/` — switch with `waybar/.config/waybar/scripts/theme_switcher.sh`
-   **Wallpaper-driven palette**: Wallpaper script generates a colour palette and applies it across Hyprland, Rofi, SwayNC, and GTK
-   **Hyprland Setup**: Full Wayland compositor with lock screen, idle management, and multi-monitor support
-   **IosevkaTermSlab Nerd Font**: Used in Alacritty

## Management

-   **Update**: `git pull` inside `~/dots`
-   **Restow a module**: `stow -R <module>` (e.g. after editing configs)
-   **Remove a module**: `stow -D <module>`
-   **Reload Hyprland**: `hyprctl reload`
