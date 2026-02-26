# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a GNU Stow-based dotfiles repository for a Hyprland/Wayland desktop setup on Arch Linux. Configuration files are organized into modules (one per application), each structured so `stow .` or `stow <module>` symlinks them into `~/`.

## Stow Commands

```sh
# Symlink everything to ~/
stow .

# Symlink a specific module
stow zsh hypr waybar

# Remove symlinks for a module
stow -D <module>

# Restow (remove + re-symlink, useful after updates)
stow -R <module>
```

## Module Structure

Each module directory mirrors the target path relative to `~/`. For example:
- `hypr/.config/hypr/hyprland.conf` → `~/.config/hypr/hyprland.conf`
- `zsh/.zshrc` → `~/.zshrc`

## Theme System

Themes are CSS files in `styles/.config/styles/`:
- `deep_ocean_blue.css`
- `pastel.css`
- `sunny_beach_day.css`

The active theme is referenced by `theme/.config/theme/theme` (plain text file with theme name). Multiple Python scripts read from the active theme CSS and regenerate component-specific color configs:

- `rofi/scripts/update_colors.py` — generates Rofi color scheme (reads theme CSS, calculates contrast ratios)
- `hypr/.config/hypr/scripts/update_colors.py` — updates Hyprland border/decoration colors
- `swaync/scripts/update_colors.py` — generates SwayNC colors + background image compositing
- `waybar/.config/waybar/scripts/ensure_contrast.py` — validates text contrast compliance in Waybar
- `waybar/.config/waybar/scripts/theme_switcher.sh` — orchestrates full theme switch (calls Python scripts, reloads services)

Theme switching flow: `theme_switcher.sh` → writes theme name → calls update_colors scripts → reloads hyprland/waybar/swaync.

## Key Scripts

| Script | Purpose |
|--------|---------|
| `hypr/.config/hypr/scripts/wallpaper.sh` | Set wallpaper and trigger palette generation |
| `hypr/.config/hypr/scripts/generate_and_apply_palette.sh` | Generate color palette from wallpaper |
| `hypr/.config/hypr/scripts/smart_spawn.py` | Spawn app or focus existing instance |
| `hypr/.config/hypr/scripts/sync_workspaces.py` | Sync workspaces across monitors |
| `hypr/.config/hypr/scripts/move_window.py` | Move windows with smart boundary logic |
| `rofi/scripts/powermenu.sh` | Power menu (shutdown/reboot/suspend/lock/logout) |
| `git/git-gone.sh` | Remove local branches deleted on remote |
| `git/git-track-all.sh` | Create local tracking branches for all remotes |

## Versioning

Version format: `YY.MM.MAJOR.MINOR` stored in `VERSION` file. GitHub Actions (`.github/workflows/bump_version.yml`) auto-bumps on push to main:
- `feat:` commits → bump MAJOR
- `fix:` commits → bump MINOR
- Date change (new YY.MM) → reset MAJOR/MINOR, create a release

## Architecture Notes

- **Wayland-native stack**: Hyprland → Waybar → Rofi → SwayNC → Hyprlock/Hypridle
- **No build step**: This is pure configuration; no compilation or package management needed
- **Python scripts** use only stdlib (no pip dependencies) — they process CSS color values and call external binaries (hyprctl, notify-send, etc.)
- **Spicetify module** (`spicetify/`) is the largest module (~189 files) and contains Spotify theming assets; it's self-contained and rarely edited
- `git/.gitconfig` uses conditional includes (`includeIf`) to switch between personal and work Git identities based on directory path
