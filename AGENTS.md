# AGENTS.md

## Overview

`dots` is a personal Arch Linux dotfiles repo for a Wayland desktop centered on Hyprland. Config is managed with GNU Stow, with top-level directories acting as stow packages that symlink into `~/.config/`, `~/.local/`, and related locations.

Chrysaki is a git submodule and the canonical theme source for the desktop.

## Stack

- GNU Stow
- Hyprland
- AGS
- Chrysaki theme pipeline

## Commands

```bash
cd ~/dots && stow .
stow <package>
stow -D <package>
python theme/scripts/generate_theme_css.py
python btop/scripts/update_colors.py
python ghostty/scripts/update_colors.py
python gtk/scripts/update_colors.py
python hypr/.config/hypr/scripts/update_colors.py
python lazygit/.config/lazygit/scripts/update_colors.py
python rofi/scripts/update_colors.py
python swaync/scripts/update_colors.py
```

## Architecture

The main architectural constraint is the Chrysaki single-source theme pipeline.

Flow:

- `chrysaki/ags/.config/ags/styles/_palette.scss` is the source of truth
- `theme/scripts/generate_theme_css.py` generates `theme/theme.css`
- Per-app `update_colors.py` scripts read `theme/theme.css`
- Generated outputs are committed
- Stow then links the resulting config into the live system

Other important areas:

- `git/.config/git/config`: conditional identities
- `zsh/`: shell environment
- `hypr/.config/hypr/scripts/`: compositor automation scripts

## Active Work

Normal work here is maintenance-oriented:

- Keep Stow-managed configs in sync
- Regenerate theme outputs after Chrysaki submodule updates
- Preserve the Chrysaki token naming convention and committed generated files
