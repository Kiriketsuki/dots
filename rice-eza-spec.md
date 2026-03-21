# Feature: Rice Eza

## Overview

**User Story**: As a desktop user, I want eza themed with Chrysaki colors, icons, and styled tree lines so that `ls` output matches my desktop aesthetic.

**Problem**: Eza uses its default color scheme. The desktop uses the Chrysaki theme, and eza should match.

**Out of Scope**:
- Wallpaper-driven dynamic color pipeline integration (tracked in #6)
- Custom eza source patches or plugins
- Layout changes beyond improving the existing alias flags

---

## Open Questions

| # | Question | Raised By | Resolved |
|:--|:---------|:----------|:---------|
| 1 | — | — | [x] |

---

## Scope

### Must-Have
- Chrysaki-themed colors for files, directories, permissions, sizes, dates, and user/group
- Styled tree-view lines and connectors matching the theme
- Custom icons (Nerd Font glyphs) for common file types/extensions
- Improved `ls` alias flags (--git, --hyperlink, --classify)

### Should-Have
- Git status indicators (modified, staged, untracked) in Chrysaki palette colors

### Nice-to-Have
- Custom/extended icon mappings for niche file types (e.g., `.astro`, `.svelte`, `.ags`)

---

## Technical Plan

**Affected Components**:
- `eza/.config/eza/theme.yml` — new file (new stow package)
- `zsh/.zshrc:191` — update `ls` alias flags
- `bootstrap.sh:203` — add `eza` to stow list

**Data Model Changes**: None

**API Contracts**: N/A

**Dependencies**: eza (already installed via pacman)

**Color Mapping (Chrysaki tokens)**:

| eza category | Chrysaki token | Hex |
|:--|:--|:--|
| Directories | Teal Lt | `#20969c` |
| Symlinks | Amethyst Lt | `#583090` |
| Executables | Emerald Lt | `#1a8a6a` |
| Regular files | Secondary Text | `#a0a4b8` |
| Permissions read | Emerald | `#14664e` |
| Permissions write | Blonde | `#FBB13C` |
| Permissions execute | Error | `#8C2F39` |
| Permissions dash | Muted | `#6a6e82` |
| Size numbers | Blonde | `#FBB13C` |
| Size unit | Blonde Dim | `#C4861C` |
| Dates | Muted | `#6a6e82` |
| Users/Groups | Teal | `#197278` |
| Git modified | Blonde | `#FBB13C` |
| Git new/staged | Emerald Lt | `#1a8a6a` |
| Git deleted | Error | `#8C2F39` |
| Git untracked | Error Lt | `#b53f4a` |
| Tree lines | Border | `#363a4f` |
| Punctuation | Muted | `#6a6e82` |
| Header row | Primary Text, bold | `#e0e2ea` |

**Risks**:
| Risk | Likelihood | Mitigation |
|:-----|:-----------|:-----------|
| theme.yml schema changes across eza versions | Low | Pin to documented v0.23 schema |
| Hex colors render differently in non-Ghostty terminals | Low | Chrysaki already has terminal ports; 24-bit color assumed |

---

## Acceptance Scenarios

```gherkin
Feature: Rice Eza
  As a desktop user
  I want eza themed with Chrysaki colors and icons
  So that ls output matches my desktop aesthetic

  Background:
    Given eza is installed and the dots repo is stowed

  Rule: Chrysaki colors applied

    Scenario: Directories display in Teal Lt
      When I run ls in a directory containing subdirectories
      Then directories are rendered in Teal Lt (#20969c)

    Scenario: Git status shown in Chrysaki semantic colors
      When I run ls in a git repository with modified and staged files
      Then modified files show Blonde (#FBB13C) git indicator
      And staged files show Emerald Lt (#1a8a6a) git indicator

  Rule: Tree view styled

    Scenario: Tree connectors use Border color
      When I run ls --tree
      Then tree lines render in Border (#363a4f)
      And icons display for each file type

  Rule: Alias works correctly

    Scenario: ls alias includes all flags
      When I run ls
      Then output includes icons, git status, hyperlinks, and classifiers
```

---

## Task Breakdown

| ID   | Task | Priority | Dependencies | Status  |
|:-----|:-----|:---------|:-------------|:--------|
| T1   | Create `eza/.config/eza/theme.yml` with Chrysaki color mappings | High | None | pending |
| T1.1 | Map filekinds, perms, size, date, users, git, punctuation, tree lines | High | T1 | pending |
| T1.2 | Add custom icon mappings for common file types | High | T1 | pending |
| T2   | Update `ls` alias in `zsh/.zshrc` with improved flags | High | None | pending |
| T3   | Add `eza` to stow list in `bootstrap.sh` | Med | T1 | pending |
| T4   | Visual verification in Ghostty | Med | T1, T2, T3 | pending |

---

## Exit Criteria

- [ ] All Chrysaki color mappings render correctly in Ghostty terminal
- [ ] Tree view lines and icons display properly
- [ ] `ls` alias applies all flags without errors
- [ ] `stow eza` symlinks theme.yml to `~/.config/eza/theme.yml`

---

## References

- Issue: https://github.com/Kiriketsuki/dots/issues/5
- Chrysaki palette: `chrysaki/PALETTE.md`
- eza theme docs: `man eza_colors.5`, `man eza_colors-explanation.5`

---
*Authored by: Clault KiperS 4.6*
