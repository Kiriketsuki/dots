# Alacritty → Ghostty Migration + Smart tmux Keybind

## Situation
Migrating the terminal from Alacritty to Ghostty and integrating it into the
wallpaper-driven color pipeline. Also adding a context-aware Super+Enter keybind
that opens a new tmux pane when inside tmux, otherwise spawns a fresh terminal.
Work is on `main`, all changes uncommitted.

## Current State
- Branch: `main`
- Ghostty stow package: **created and stowed** (`~/.config/ghostty` → symlink into dots)
- Uncommitted: `ghostty/` (entire new package), `smart_terminal.py`, `hyprland.conf`,
  `generate_and_apply_palette.sh`, `bootstrap.sh`, `zsh/.zshrc`, `yazi` desktop files,
  `chrysaki` submodule (tmux terminal-overrides)
- Tests: N/A (dotfiles)
- What works: stow, hex shader loads, color pipeline hook added
- What's incomplete: ctrl+backspace word-delete (partially fixed — needs testing after restart), tmux bar bottom-flush (ongoing cosmetic issue), ghostty not yet installed (needs `yay -S ghostty` interactively)

## Key Files
- `ghostty/.config/ghostty/config` — main Ghostty config (padding, font, shader, keybinds)
- `ghostty/.config/ghostty/colors` — Chrysaki ANSI 16 seed palette (auto-regenerated)
- `ghostty/.config/ghostty/shaders/grain.glsl` — hex wave shader
- `ghostty/scripts/update_colors.py` — theme pipeline integration (reads theme.css, writes colors)
- `hypr/.config/hypr/scripts/smart_terminal.py` — Super+Enter tmux-aware spawner
- `hypr/.config/hypr/scripts/generate_and_apply_palette.sh` — orchestrator (ghostty hook added)
- `hypr/.config/hypr/hyprland.conf` — `$terminal = ghostty`, keybind, window rules, gaps
- `zsh/.zshrc` — has `bindkey $'\e[127;5u' backward-kill-word` added

## Decisions Made
- **Ghostty over Alacritty** because `config-file` import directive enables clean theme pipeline
  (no full-rewrite needed on palette change; Ghostty hot-reloads)
- **`window-padding-balance = true`** added to distribute leftover cell-rounding pixels
  evenly rather than dumping them at the bottom (reduces but doesn't eliminate bottom gap)
- **`window-padding-x/y = 0`** — padding removed; shader vignette provides depth instead
- **`gaps_out = 5`** kept (desired tile spacing); `gaps_out = 0` was tried and reverted
- **ctrl+backspace via CSI** — `keybind = ctrl+backspace=csi:127;5u` in Ghostty +
  `bindkey $'\e[127;5u' backward-kill-word` in zsh. Required because Ghostty default
  sends `\x7f` (single char delete), not `^W`
- **No grain** — user explicitly rejected film grain; hex wave shader used instead
- **Shader subtlety** — base brightness `0.006`, peak `0.042`, fill `0.003`; earlier
  versions were too visible
- **`blur_passes` window rule** removed — not a valid Hyprland rule; blur is global
  via `decoration:blur:enabled = true`, already set in hyprland.conf
- **`.stow-local-ignore`** added to ghostty package excluding top-level `scripts/`
  (conflicts with rofi's stowed `~/scripts/`); scripts are called from `~/dots/` path directly

## Failed Approaches
- `esc:0x17` for ctrl+backspace: sends ESC + literal string "0x17" (5 chars) — wrong
- `text:\x17` for ctrl+backspace: Ghostty strips `\` → sends literal "x17" — wrong
- `text:"\x17"` for ctrl+backspace: quotes sent literally → user sees `""` + invisible ^W — wrong
- `blur_passes = 3` in windowrule: not a valid Hyprland window rule property — error
- `window-padding-x/y = 10` with tmux: creates visible 10px gap around tmux session
- Grain shader: user rejected immediately — too distracting
- `gaps_out = 0`: user rejected — wants 5px gaps between tiles
- Aspect-ratio correction in hex UV (`fragCoord / (cellSize * ar)`): caused squished
  wide hexagons. Fix: uniform `fragCoord / cellSize`

## Active Constraints
- Ghostty config changes to `window-padding-*` **only apply to new windows**, not on
  config reload — user must fully close/reopen Ghostty to see padding changes
- `custom-shader-animation = always` forces continuous GPU updates; acceptable for this use case
- The tmux bottom gap is a fundamental cell-rounding issue (window height not divisible
  by cell height). `window-padding-balance = true` mitigates but doesn't eliminate it.
  Only fully fixable if Hyprland snaps window to grid dimensions (not currently configured)
- `chrysaki` is a git submodule pointing to the Obsidian vault tmux config; tmux live config
  is symlinked from `~/dev/obKidian/...` not from the dots stow path
- Ghostty not yet installed — `yay -S ghostty` needs to be run in an interactive terminal

## Next Steps
1. Run `yay -S ghostty` in an interactive terminal to install
2. Test ctrl+backspace after opening a **new** Ghostty window (reload isn't enough for keybind changes to CSI sequence)
3. Confirm hex wave shader is visible but subtle — if still too visible, reduce `bright` base in `grain.glsl:54` further
4. Commit all changes: `ghostty/`, modified `hypr/`, `zsh/.zshrc`, `bootstrap.sh`, `yazi` files
5. Optionally: investigate Hyprland `windowrule` to snap Ghostty window to cell-height multiples
   (would fix tmux bottom gap permanently)
6. Optionally: add Ghostty port to Chrysaki theme repo (`chrysaki/ghostty/` directory with colors file)

## Open Questions
- Does the hex shader wave speed (4.5 hex-units/sec) feel right? User hasn't confirmed final approval
- Should `window-padding-balance = true` stay, or does the user prefer no balance (grid top-left aligned)?
- Is the ctrl+backspace fix (`csi:127;5u`) working after full Ghostty restart? Not yet confirmed
