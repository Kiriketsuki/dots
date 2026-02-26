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

### Wallpaper-Driven Theme Pipeline

The central architectural pattern is a color pipeline that derives the entire desktop theme from the current wallpaper:

```
Wallpaper → kilour (color extraction) → styles/palette.css
  → hypr/scripts/generate_and_apply_palette.sh
    → waybar/scripts/ensure_contrast.py → theme/theme.css (central hub, @define-color vars)
      → gtk/scripts/update_colors.py    → gtk-3.0/gtk.css
      → rofi/scripts/update_colors.py   → rofi colors.rasi
      → swaync/scripts/update_colors.py → swaync CSS
      → hypr/scripts/update_colors.py   → hypr/colors.conf
```

- `styles/palette.css` — raw extracted colors as CSS `:root` variables (`--color-N: #HEX`)
- `theme/theme.css` — central color definitions with contrast-safe text colors (`@define-color color-N` / `@define-color text-color-N`), enforcing WCAG AA 4.5:1 ratio
- Per-app `update_colors.py` scripts read theme.css and emit app-specific formats

### Color Variable Convention

All theme scripts use indexed color names: `color-0` through `color-N` with matching `text-color-N` for accessible text on each background.

### Git Conditional Config

`git/.config/git/config` uses `includeIf` for different identities: `~/dev/` (personal) vs `~/workdev/` (work).

### Shell

Zsh with Zinit plugin manager and Powerlevel10k prompt. Plugins loaded via Zinit turbo mode.

### Neovim

LazyVim-based configuration under `nvim/.config/nvim/` with modular Lua structure (`config/`, `plugins/`).

## Versioning

Automated via GitHub Actions. Scheme: `YY.MM.MAJOR.MINOR`. Commit prefixes `feat:` and `fix:` trigger version bumps.

## Key Scripts

| Script | Purpose |
|--------|---------|
| `hypr/scripts/generate_and_apply_palette.sh` | Master palette generator — orchestrates the full theme pipeline |
| `waybar/scripts/ensure_contrast.py` | Generates theme.css with WCAG-compliant text colors |
| `hypr/scripts/sync_workspaces.py` | Multi-monitor workspace synchronization |
| `hypr/scripts/smart_spawn.py` | Intelligent window spawning |
| `rofi/scripts/powermenu.sh` | System power menu (lock/suspend/shutdown/logout) |
