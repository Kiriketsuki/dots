# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository for a Wayland-based Linux desktop (Arch Linux) centered on the Hyprland compositor. Configurations are managed with **GNU Stow** — each top-level directory is a stow package that symlinks into `~/.config/`, `~/.local/`, etc.

## Stow Commands

```bash
# Install all configs
cd ~/dots && stow .

# Install a single package
stow <package>     # e.g. stow hypr

# Uninstall a package
stow -D <package>
```

## Architecture

### Chrysaki Single-Source Theme Pipeline

The desktop theme is derived from Chrysaki's canonical palette. Wallpaper rotation is purely cosmetic and does not affect theming. All theme outputs are committed — no runtime generation needed.

```
chrysaki/ags/.config/ags/styles/_palette.scss  (single source of truth)
  → theme/scripts/generate_theme_css.py        (dev-time bridge: SCSS → CSS, WCAG text colors)
    → theme/theme.css                           (@define-color chrysaki-<name> / text-chrysaki-<name>)
      → waybar/style.css      (direct @import)
      → swaync/style.css      (direct @import + swaync/scripts/update_colors.py)
      → rofi/scripts/update_colors.py   → rofi colors.rasi (uses text-chrysaki-* tokens directly)
      → gtk/scripts/update_colors.py    → gtk-3.0/gtk.css
      → hypr/.config/hypr/scripts/update_colors.py → hypr/colors.conf
      → ghostty/scripts/update_colors.py → ghostty/colors
      → lazygit/.config/lazygit/scripts/update_colors.py → lazygit/colors.yml
      → btop/scripts/update_colors.py   → btop/themes/chrysaki.theme
```

- `_palette.scss` — Chrysaki canonical tokens as SCSS variables (`$name: #HEX;`)
- `theme/theme.css` — central color definitions with WCAG AA contrast-safe text colors (`@define-color chrysaki-<name>` / `@define-color text-chrysaki-<name>`)
- Per-app `update_colors.py` scripts read theme.css named tokens and emit app-specific formats
- All outputs are committed; run the bridge + individual scripts only after bumping the Chrysaki submodule

### Color Variable Convention

All theme scripts use named Chrysaki tokens: `chrysaki-<name>` with matching `text-chrysaki-<name>` for accessible text on each background.

### Git Conditional Config

`git/.config/git/config` uses `includeIf` for different identities: `~/dev/` (personal) vs `~/workdev/` (work).

### Shell

Zsh with the Zinit plugin manager and an Oh My Posh prompt (`ohmyposh/`, config from `chrysaki/ohmyposh/`). Zinit loads plugins in turbo mode. Config in `zsh/`.

## Versioning

Automated via GitHub Actions. Scheme: `YY.Major.Minor.Patch[Suffix]`. Version bumps trigger on PR merge: `epic/*` → +Major, `feature/*` → +Minor, `task/*`/`bug/*` → +Patch, `hotfix/*` → +Suffix (a,b,c...).

## Theme Regeneration

After bumping the Chrysaki submodule, regenerate all theme outputs:

```bash
cd ~/dots

# 1. Generate central theme.css from Chrysaki palette
python theme/scripts/generate_theme_css.py

# 2. Update per-app color configs (each reads theme/theme.css)
python btop/scripts/update_colors.py
python ghostty/scripts/update_colors.py
python gtk/scripts/update_colors.py
python hypr/.config/hypr/scripts/update_colors.py
python lazygit/.config/lazygit/scripts/update_colors.py
python rofi/scripts/update_colors.py
python swaync/scripts/update_colors.py

# 3. Re-stow to symlink updated outputs
stow .
```

## Stow Packages

Every top-level directory is a stow package. List them with `ls -d ~/dots/*/`.

## Key Scripts

| Script | Purpose |
|--------|---------|
| `theme/scripts/generate_theme_css.py` | Bridge: reads Chrysaki _palette.scss → generates theme.css with WCAG text colors |
| `*/scripts/update_colors.py` | Per-app color generators (btop, ghostty, gtk, hypr, lazygit, rofi, swaync) |
| `hypr/.config/hypr/scripts/sync_workspaces.py` | Multi-monitor workspace synchronization |
| `hypr/.config/hypr/scripts/smart_spawn.py` | Intelligent window spawning |
| `rofi/scripts/powermenu.sh` | System power menu (lock/suspend/shutdown/logout) |
