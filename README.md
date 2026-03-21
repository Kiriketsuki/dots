# Dotfiles

Personal configuration files for a Wayland-based Arch Linux desktop centered on Hyprland, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Install (Arch Linux)

```sh
git clone --recurse-submodules https://github.com/Kiriketsuki/dots.git ~/dots
cd ~/dots && bash bootstrap.sh
```

Then reboot. Hyprland starts automatically via TTY autologin + uwsm.

## Contents

| Package | Purpose |
|---------|---------|
| `backgrounds/` | Wallpapers and current wallpaper pointers |
| `bash/` | Bash shell configuration |
| `chrysaki/` | [Chrysaki](https://github.com/Kiriketsuki/chrysaki) design system (git submodule) — tmux, VSCode, Ghostty, lazygit, etc. |
| `Code/` | VS Code settings |
| `fontconfig/` | Font configuration |
| `ghostty/` | Ghostty terminal emulator configuration |
| `git/` | Git configuration with conditional identities (`~/dev/` vs `~/workdev/`) |
| `gtk/` | GTK 3 theme + color generation script |
| `hypr/` | Hyprland, Hyprlock, Hypridle configs + scripts |
| `lazygit/` | Lazygit configuration + color generation |
| `mime/` | MIME type associations |
| `mpd/` | Music Player Daemon configuration |
| `rofi/` | Rofi launcher (Jovian theme) + color generation |
| `spicetify/` | Spicetify (Spotify customization) |
| `styles/` | Color palettes (`palette.css` + presets) |
| `swaync/` | Sway Notification Center + color generation |
| `theme/` | Central `theme.css` hub (WCAG-compliant color definitions) |
| `waybar/` | Waybar status bar + contrast enforcement script |
| `xdg-desktop-portal/` | XDG Desktop Portal configuration |
| `yazi/` | Yazi file manager |
| `zsh/` | Zsh (Zinit, Powerlevel10k, fzf, zoxide) |

## What the Bootstrap Script Does

1. Installs `git`, `stow`, `base-devel` via pacman
2. Builds and installs `yay` (AUR helper) if not present
3. Installs all required packages (shell, Hyprland ecosystem, fonts, audio, etc.)
4. Enables services: NetworkManager, Bluetooth, TLP, Docker, Tailscale, sshd
5. Configures SSH keepalive (60s interval) to prevent idle disconnections
6. Builds and installs [kilour](https://github.com/Kiriketsuki/kilour) (Go color palette extractor)
7. Installs `uv` (Python toolchain), `nvm` + Node.js LTS, global npm tools (Claude Code, Gemini CLI)
8. Backs up conflicting config files, then stows all dotfile modules
9. Initialises the Chrysaki submodule and symlinks tmux + VSCode configs
10. Sets `zsh` as the default shell, installs Zinit + plugins
11. Configures TTY autologin on tty1 (no display manager)
12. Initialises PostgreSQL, refreshes font cache
13. Applies the Chrysaki color theme across all apps

## Wallpaper-Driven Color Pipeline

The entire desktop theme is derived from a color palette:

```
styles/palette.css (raw colors)
  → waybar/scripts/ensure_contrast.py → theme/theme.css (WCAG AA 4.5:1 text colors)
    → hypr/scripts/update_colors.py   → hypr/colors.conf
    → gtk/scripts/update_colors.py    → gtk-3.0/gtk.css
    → rofi/scripts/update_colors.py   → rofi/colors.rasi
    → swaync/scripts/update_colors.py → swaync/swaync_colors.css
    → ghostty/scripts/update_colors.py → ghostty/colors
    → lazygit/scripts/update_colors.py → lazygit/colors.yml
```

Re-apply the palette at any time (after bumping the Chrysaki submodule):

```sh
python3 ~/dots/theme/scripts/generate_theme_css.py
```

## Packages Installed

| Category | Packages |
|----------|----------|
| Shell & Terminal | `zsh`, `ghostty`, `tmux`, `fzf`, `zoxide` |
| Editors | `neovim`, `visual-studio-code-bin` |
| Hyprland ecosystem | `hyprland`, `hyprlock`, `hypridle`, `hyprpaper`, `hyprpicker`, `uwsm` |
| Status & notifications | `waybar`, `swaync` |
| Launcher & file managers | `rofi`, `yazi`, `thunar` |
| Audio & media | `mpd`, `pipewire`, `wireplumber`, `playerctl`, `pavucontrol` |
| Fonts | `ttf-iosevkatermslab-nerd`, `ttf-jetbrains-mono-nerd`, `noto-fonts-cjk`, `noto-fonts-emoji` |
| Portals | `xdg-desktop-portal-hyprland`, `xdg-utils` |
| Screenshots | `hyprshot`, `grim`, `slurp` |
| Networking | `network-manager-applet`, `tailscale`, `openssh`, `lan-mouse` |
| Dev tools | `go`, `docker`, `github-cli`, `lazygit`, `git-delta`, `nvm`, `python-pip` |
| Databases | `postgresql`, `pgbouncer`, `pgloader`, `dbeaver` |
| Desktop apps | `firefox`, `thunderbird`, `slack-desktop-wayland`, `spotify`, `obsidian-bin` |
| System | `brightnessctl`, `bluez`, `tlp`, `polkit-kde-agent`, `imagemagick` |

## Chrysaki Theme

The [Chrysaki](https://github.com/Kiriketsuki/chrysaki) design system is included as a git submodule. It provides themed configs for tmux, VSCode, Ghostty, lazygit, and more.

The tmux config is symlinked from `chrysaki/tmux/` into `~/.config/tmux/`. It requires **IosevkaTermSlab Nerd Font** for powerline glyphs.

## Git Setup

```sh
~/dots/git/gh-setup.sh
```

Configures dual GitHub identities with separate SSH keys:

| Directory | Identity | SSH key |
|-----------|----------|---------|
| `~/dev/` | kiriketsuki | `id_personal` |
| `~/workdev/Aurrigo/` | Jovian-Aurrigo | `id_work` |

## Management

- **Update**: `cd ~/dots && git pull --recurse-submodules`
- **Restow a module**: `stow -R <module>`
- **Remove a module**: `stow -D <module>`
- **Reload Hyprland**: `hyprctl reload`
- **Re-apply theme**: `python3 ~/dots/theme/scripts/generate_theme_css.py`
