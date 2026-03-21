## PR Naming Convention
| Type | PR Title Format |
|------|----------------|
| Feature | `feat: Name of Feature` |
| Task | `chore: Name of Task` |
| Bug | `fix: Name of Bug` |

> All PRs are **squash merged**. Keep individual commits on your branch descriptive — they'll be squashed into one on main.

---

## Summary

<!-- Describe what this PR does and why. One paragraph is fine. -->

Closes #<!-- issue number -->

---

## Changes

<!-- Brief bullet list of what changed. -->

-

---

## Affected Apps

<!-- Which stow packages / apps does this touch? -->

- [ ] Hyprland
- [ ] Waybar
- [ ] Rofi
- [ ] SwayNC
- [ ] GTK
- [ ] Ghostty
- [ ] Tmux
- [ ] Zsh
- [ ] Neovim
- [ ] Theme (Chrysaki)
- [ ] Other: ___

---

## Testing

<!-- Describe how you tested this change. -->

- [ ] Stow applied cleanly (`cd ~/dots && stow .`)
- [ ] App reloaded/restarted with no errors
- [ ] No regressions introduced

---

## Notes for reviewers

<!-- Anything a reviewer should pay special attention to, or known limitations. -->
