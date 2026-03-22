# Feature: Rice and Configure Neovim

## Overview

**User Story**: As a developer transitioning from VS Code, I want a fully configured Neovim environment with Chrysaki theming and VS Code-equivalent workflows so that I can be productive in a terminal-first editor without losing the features I depend on.

**Problem**: The current nvim config is a stock LazyVim starter with zero customization — no extras enabled, no LSP servers, no colorscheme applied, and no custom keymaps. A VS Code user opening it would have no file explorer, no command palette, no go-to-definition, and no integrated terminal workflow.

**Out of Scope**:
- DAP (Debug Adapter Protocol) / debugger integration — separate task
- AI/Copilot integration — separate task
- Custom dashboard/alpha screen — low priority, defer
- Chrysaki lualine theme (separate from colorscheme) — defer to a follow-up unless trivial
- Building a Neovim-from-scratch config; we stay on the LazyVim framework

---

## Open Questions

| # | Question | Raised By | Resolved |
|:--|:---------|:----------|:---------|
| 1 | Which picker backend? | Spec | [x] **Snacks Picker** — fastest, recommended by LazyVim, already part of snacks.nvim |
| 2 | Which file explorer? | Spec | [x] **Neo-tree** — mature, feature-rich, closest to VS Code Explorer |
| 3 | Which languages need LSP? | Spec | [x] **Full polyglot**: Lua, Python, Bash, TypeScript/JS, Rust, Go, C/C++, SQL, Vue, GLSL |
| 4 | Keep nvim as nested git repo or absorb? | Issue #10 | [x] **Absorb into dots** — remove nvim/.git/, commit content directly |

---

## Scope

### Must-Have
- **Chrysaki colorscheme active**: `colorscheme chrysaki` set as default; verified all highlight groups render correctly: done when opening a Lua file shows amethyst keywords, emerald functions, blonde strings
- **Snacks picker enabled**: `<leader><space>` finds files, `<leader>/` greps, `<leader>sC` lists commands (VS Code command palette equivalent); done when all three work from a fresh nvim launch
- **File explorer sidebar**: Neo-tree or Snacks explorer toggled with `<leader>e`; follows current file, shows git status indicators; done when explorer opens on the left showing the project tree with git decorations
- **LSP servers configured**: lua_ls, pyright, bashls, ts_ls, rust-analyzer, gopls, clangd, sqlls, volar (Vue), glsl_analyzer; installed automatically via Mason; done when `gd` (go to definition) works in a Lua file
- **Go-to-definition and references**: `gd` jumps to definition, `gr` shows references, `gI` goes to implementation — all via LSP + picker; done when F12-equivalent works on any function
- **Integrated terminal**: `<C-/>` toggles a bottom-split terminal (Snacks.terminal); done when pressing Ctrl+/ opens/closes a shell at the bottom of the editor
- **Git integration**: `<leader>gg` opens LazyGit in a floating terminal; gitsigns shows add/change/delete markers in the gutter; done when lazygit launches and gutter signs appear on a modified file
- **Treesitter parsers**: Ensure installed for lua, python, bash, json, yaml, markdown, css, scss, html, javascript, typescript, rust, go, toml, c, cpp, sql, vue, glsl; done when syntax highlighting uses tree-sitter (verify with `:InspectTree`)
- **Formatters and linters wired**: conform.nvim for formatting (stylua, black/ruff, shfmt), nvim-lint for linting; done when saving a Lua file auto-formats via stylua
- **Basic Neovim options set**: Line numbers (relative), cursorline, 2-space indent, clipboard = unnamedplus, termguicolors; done when the editor feels responsive and familiar

### Should-Have
- **VS Code keybinding cheat sheet**: A `which-key` group or comment block mapping VS Code shortcuts to nvim equivalents (Ctrl+P = `<leader>ff`, Ctrl+Shift+P = `<leader>sC`, F12 = `gd`, etc.)
- **Indent guides**: indent-blankline or similar visual guide for nesting depth
- **UI polish**: noice.nvim already installed; configure for clean command-line and notifications
- **Bufferline tab theming**: bufferline.nvim tabs styled with Chrysaki surface colors

### Nice-to-Have
- **Edgy.nvim panel layout**: VS Code-style fixed panels (terminal at bottom, explorer at left, trouble at bottom-right)
- **Custom Chrysaki lualine sections**: statusline segments using Chrysaki palette tokens
- **Mini.animate or similar**: smooth scrolling and window animations
- **Session persistence**: restore last session on startup (persistence.nvim already installed, just needs config)

---

## Technical Plan

**Affected Components**:
- `nvim/.config/nvim/lazyvim.json` — enable LazyVim extras
- `nvim/.config/nvim/lua/config/options.lua` — Neovim options
- `nvim/.config/nvim/lua/config/keymaps.lua` — custom key bindings
- `nvim/.config/nvim/lua/config/autocmds.lua` — autocommands (format on save, etc.)
- `nvim/.config/nvim/lua/plugins/` — new plugin spec files (one per concern)
- `nvim/.config/nvim/colors/chrysaki.lua` — already symlinked, no changes needed

**New Plugin Spec Files** (in `lua/plugins/`):
| File | Purpose |
|:-----|:--------|
| `colorscheme.lua` | Set Chrysaki as default colorscheme |
| `editor.lua` | Neo-tree / explorer, indent guides, which-key extensions |
| `lsp.lua` | LSP server config (lua_ls, pyright, bashls, etc.) |
| `formatting.lua` | conform.nvim formatters + nvim-lint linters |
| `treesitter.lua` | Treesitter ensure_installed list |
| `git.lua` | LazyGit extra, gitsigns config |
| `ui.lua` | Bufferline theming, noice tweaks |
| `terminal.lua` | Snacks.terminal bottom-split config |

**LazyVim Extras to Enable** (in `lazyvim.json`):
- `lazyvim.plugins.extras.editor.snacks_picker` — Snacks picker (command palette, file finder, grep)
- `lazyvim.plugins.extras.editor.neo-tree` — file explorer
- `lazyvim.plugins.extras.lang.json` — JSON LSP + treesitter
- `lazyvim.plugins.extras.lang.python` — Python LSP (pyright) + formatters
- `lazyvim.plugins.extras.lang.typescript` — TypeScript/JS LSP
- `lazyvim.plugins.extras.lang.rust` — rust-analyzer
- `lazyvim.plugins.extras.lang.go` — gopls
- `lazyvim.plugins.extras.lang.clangd` — C/C++ (clangd)
- `lazyvim.plugins.extras.lang.vue` — Vue/Volar
- `lazyvim.plugins.extras.lang.sql` — SQL LSP (if available as extra, else manual)
- `lazyvim.plugins.extras.ui.indent-blankline` — indent guides

**Dependencies**:
- Mason (already installed) — auto-installs LSP servers and formatters
- Nerd Font (IosevkaTermSlab already in use per Chrysaki/tmux setup)
- lazygit CLI — must be installed on the system (`pacman -S lazygit`)

**Risks**:
| Risk | Likelihood | Mitigation |
|:-----|:-----------|:-----------|
| Chrysaki colorscheme missing highlight groups for new plugins (neo-tree, bufferline, etc.) | Medium | Add missing highlight groups to chrysaki.lua after testing |
| Mason auto-install fails for some LSP servers | Low | Pin versions in mason ensure_installed; verify on first launch |
| Nested .git in nvim/ causes stow conflicts | Medium | Remove .git from nvim/ before committing; add nvim content directly to dots |
| Plugin conflicts between enabled extras | Low | Enable extras incrementally; test after each |

---

## Acceptance Scenarios

```gherkin
Feature: Rice and Configure Neovim
  As a VS Code user transitioning to Neovim
  I want familiar workflows in a terminal editor
  So that I can stay productive without VS Code

  Background:
    Given Neovim is launched with the configured dotfiles
    And the LazyVim framework is loaded with all extras

  Rule: Chrysaki theme is applied consistently

    Scenario: Colorscheme loads on startup
      Given Neovim opens any file
      When the editor renders
      Then the background is Chrysaki Base (#161821)
      And keywords are Amethyst Lt (#583090)
      And functions are Emerald Lt (#1a8a6a)
      And strings are Blonde (#FBB13C)

  Rule: Command palette equivalent works

    Scenario: Find files like Ctrl+P
      Given the user presses <leader><space>
      When the Snacks picker opens
      Then files in the project root are listed
      And typing filters results in real time

    Scenario: Command search like Ctrl+Shift+P
      Given the user presses <leader>sC
      When the Snacks commands picker opens
      Then all available Neovim commands are listed
      And typing filters to matching commands

  Rule: Go-to-definition works via LSP

    Scenario: Jump to function definition
      Given a Lua file is open with cursor on a function call
      When the user presses gd
      Then the editor jumps to the function definition
      And the definition file opens in the current window

    Scenario: Find all references
      Given a Lua file is open with cursor on a symbol
      When the user presses gr
      Then a picker shows all references to that symbol

  Rule: File explorer provides VS Code-like sidebar

    Scenario: Toggle file explorer
      Given the user presses <leader>e
      When the explorer opens on the left side
      Then the current project tree is visible
      And the current file is highlighted
      And git-modified files show status indicators

  Rule: Integrated terminal works at the bottom

    Scenario: Toggle bottom terminal
      Given the user presses Ctrl+/
      When the terminal panel toggles
      Then a shell opens at the bottom of the editor
      And pressing Ctrl+/ again hides it

  Rule: Git integration via LazyGit

    Scenario: Open LazyGit
      Given the user presses <leader>gg
      When LazyGit opens in a floating window
      Then the user can stage, commit, and push from within Neovim

    Scenario: Gutter signs show file changes
      Given a file has uncommitted modifications
      When the file is open in the editor
      Then green/yellow/red signs appear in the gutter for added/changed/deleted lines
```

---

## Task Breakdown

| ID   | Task | Priority | Dependencies | Status  |
|:-----|:-----|:---------|:-------------|:--------|
| T1   | Resolve nested .git in nvim/ (absorb into dots or keep) | High | None | pending |
| T2   | Create `lua/plugins/colorscheme.lua` — set Chrysaki as default | High | None | pending |
| T3   | Create `lua/config/options.lua` — relative line numbers, indent, clipboard, etc. | High | None | pending |
| T4   | Update `lazyvim.json` — enable extras (snacks_picker, neo-tree, lang packs, indent-blankline) | High | None | pending |
| T5   | Create `lua/plugins/lsp.lua` — LSP servers via Mason (lua_ls, pyright, bashls, ts_ls, rust-analyzer, gopls, clangd, sqlls, volar, glsl_analyzer) | High | T4 | pending |
| T6   | Create `lua/plugins/treesitter.lua` — ensure_installed for all languages | High | T4 | pending |
| T7   | Create `lua/plugins/formatting.lua` — conform.nvim + nvim-lint config | High | T5 | pending |
| T8   | Create `lua/plugins/editor.lua` — neo-tree tweaks, indent guides | Med | T4 | pending |
| T9   | Create `lua/plugins/git.lua` — lazygit extra, gitsigns config | Med | T4 | pending |
| T10  | Create `lua/plugins/terminal.lua` — Snacks.terminal bottom-split | Med | T4 | pending |
| T11  | Create `lua/config/keymaps.lua` — VS Code transition bindings | Med | T4, T5 | pending |
| T12  | Create `lua/plugins/ui.lua` — bufferline Chrysaki theming, noice tweaks | Low | T2 | pending |
| T13  | Test all acceptance scenarios manually | High | T2-T11 | pending |
| T14  | Update Chrysaki colorscheme if missing highlight groups for new plugins | Med | T13 | pending |

---

## Exit Criteria

- [ ] All Must-Have scenarios pass (manual verification)
- [ ] Chrysaki colorscheme renders correctly across all UI elements
- [ ] LSP go-to-definition works for Lua, Python, and Bash
- [ ] File explorer, terminal, and lazygit all toggle correctly
- [ ] `stow nvim` symlinks cleanly to `~/.config/nvim/` without conflicts
- [ ] No regressions on existing dotfiles (stow other packages still work)
- [ ] Nested .git decision resolved and documented

---

## References

- Issue: #10 "Feature: Rice and configure Neovim"
- PR: #11 "feat: Rice and configure Neovim"
- LazyVim docs: https://lazyvim.github.io/
- LazyVim Snacks Picker: https://www.lazyvim.org/extras/editor/snacks_picker
- LazyVim Neo-tree: https://www.lazyvim.org/extras/editor/neo-tree
- Chrysaki Neovim port: `chrysaki/nvim/chrysaki.lua` (symlinked to `nvim/.config/nvim/colors/`)
- Chrysaki palette reference: `chrysaki/CLAUDE.md`

---
*Authored by: Clault KiperS 4.6*
