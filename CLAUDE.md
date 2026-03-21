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
      → hypr/scripts/update_colors.py   → hypr/colors.conf
      → ghostty/scripts/update_colors.py → ghostty/colors
      → lazygit/scripts/update_colors.py → lazygit/colors.yml
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

Zsh with Zinit plugin manager and Powerlevel10k prompt. Plugins loaded via Zinit turbo mode.

### Neovim

LazyVim-based configuration under `nvim/.config/nvim/` with modular Lua structure (`config/`, `plugins/`).

## Versioning

Automated via GitHub Actions. Scheme: `YY.MM.MAJOR.MINOR`. Commit prefixes `feat:` and `fix:` trigger version bumps.

## Key Scripts

| Script | Purpose |
|--------|---------|
| `theme/scripts/generate_theme_css.py` | Bridge: reads Chrysaki _palette.scss → generates theme.css with WCAG text colors |
| `hypr/scripts/sync_workspaces.py` | Multi-monitor workspace synchronization |
| `hypr/scripts/smart_spawn.py` | Intelligent window spawning |
| `rofi/scripts/powermenu.sh` | System power menu (lock/suspend/shutdown/logout) |

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **dots** (154 symbols, 207 relationships, 8 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/dots/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/dots/context` | Codebase overview, check index freshness |
| `gitnexus://repo/dots/clusters` | All functional areas |
| `gitnexus://repo/dots/processes` | All execution flows |
| `gitnexus://repo/dots/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

## CLI

- Re-index: `npx gitnexus analyze`
- Check freshness: `npx gitnexus status`
- Generate docs: `npx gitnexus wiki`

<!-- gitnexus:end -->
