## Adversarial Council — PR #9: Rice CLI Tools Merge Readiness

> Convened: 2026-03-21 18:00 | Advocates: 2 | Critics: 1 (2 planned, 1 spawned due to tmux pane limit) | Rounds: 3/4

### Motion
PR #9 (feat: rice CLI tools) is ready to merge as-is — the btop Chrysaki theme pipeline, atuin/procs/tealdeer configs, and shell aliases are correct, complete, and follow established dotfiles conventions.

### Advocate Positions
**ADVOCATE-1**: PR is production-ready on four pillars: (1) btop `update_colors.py` is a faithful replica of the established pipeline pattern, (2) all stow packages follow canonical `tool/.config/tool/` layout, (3) bootstrap.sh integration is complete, (4) shell alias sourcing is conditional and safe. The PR is additive with no runtime side effects.

**ADVOCATE-2**: Architecturally sound — btop script mirrors ghostty line-for-line in structure, `.stow-local-ignore` correctly excludes scripts (matching ghostty/rofi/gtk/swaync convention), stow packages are self-contained with no collision risk, and shell alias sourcing uses the established conditional `[[ -f ... ]] && source` pattern. Conceded that atuin lacks an update script but argued the named-color mapping is the highest fidelity representation possible given atuin's API constraint.

### Critic Positions
**CRITIC-1**: Three structural problems: (1) atuin `chrysaki.toml` uses static W3C named colors (`lightseagreen`, `mediumpurple`, etc.) with no `update_colors.py` — will silently diverge when the Chrysaki palette bumps; (2) tealdeer uses generic terminal colors (`green`, `cyan`, `yellow`) that are not Chrysaki-specific at all; (3) btop's `update_colors.py` is absent from CLAUDE.md's pipeline diagram, making it invisible to the documented theme update workflow. Withdrew the stow pattern inconsistency claim after ADVOCATE-2 challenged it. Conceded the spec file is not a merge blocker.

### Key Conflicts
- **atuin theme fidelity** — ADVOCATE-2 argued named colors are the best possible given atuin's API constraint (no hex support); CRITIC-1 argued the lack of any update mechanism or mapping documentation means silent drift is inevitable — **unresolved, but the API constraint is verified as real**
- **CLAUDE.md pipeline diagram** — ADVOCATE-2 called it a "documentation gap, not a code defect"; CRITIC-1 argued the motion claims "complete" and a missing diagram entry contradicts that — **resolved: CRITIC-1's point stands logically**
- **btop stow-local-ignore pattern** — CRITIC-1 claimed btop's `^scripts$` exclusion departs from convention; ADVOCATE-2 challenged for citation — **resolved: arbiter verification shows ghostty, rofi, gtk, swaync all use the same `^scripts$` pattern; btop follows the majority convention**

### Concessions
- ADVOCATE-1 conceded CLAUDE.md pipeline diagram needs updating (documentation gap)
- ADVOCATE-2 conceded atuin lacks an update script (gap acknowledged)
- CRITIC-1 conceded `rice-cli-tools-spec.md` is not a merge blocker (precedent exists: 5 other spec files in repo)
- CRITIC-1 withdrew the stow pattern inconsistency claim (could not cite evidence)

### Arbiter Recommendation
**CONDITIONAL**
The PR's core implementation (btop theme pipeline, stow packages, shell aliases, bootstrap integration) is correct and follows established conventions. However, two legitimate gaps were identified: (1) CLAUDE.md's pipeline diagram does not list btop as a consumer, breaking the documented workflow for theme updates, and (2) the atuin `chrysaki.toml` file has no mapping documentation, meaning future palette bumps have no process to follow for updating the named-color approximations. Both are small, in-PR fixes that complete the feature.

### Conditions
1. Add `btop/scripts/update_colors.py` to the CLAUDE.md pipeline diagram alongside the existing consumers (rofi, swaync, gtk, hypr, ghostty, lazygit)
2. Add inline comments to `atuin/.config/atuin/themes/chrysaki.toml` documenting which Chrysaki token each named color approximates (e.g., `# chrysaki-emerald-light (#1a8a6a) -> lightseagreen (#20B2AA)`) so future palette bumps have a reviewable mapping

### Suggested Fixes

#### Bug Fixes (always in-PR, regardless of original scope)
_(none identified)_

#### In-PR Improvements (scoped, non-bug)
1. **Update CLAUDE.md pipeline diagram** — `CLAUDE.md:19-27` — Add `btop/scripts/update_colors.py → btop/themes/chrysaki.theme` to the pipeline ASCII diagram. The diagram is the authoritative reference for which scripts to run after a Chrysaki submodule bump; omitting btop means it will be missed.
2. **Document atuin color mappings** — `atuin/.config/atuin/themes/chrysaki.toml:1-24` — Add comments mapping each named color to the Chrysaki token it approximates, with hex values for both. This turns the file from an opaque static theme into a reviewable mapping that can be manually updated when the palette changes.

#### PR Description Amendments (update scope/intent)
- Add a note to the PR body clarifying that atuin, tealdeer, and procs use the closest available named/built-in colors rather than exact Chrysaki hex values, due to API constraints in each tool. This sets accurate expectations for palette bump behavior.

#### New Issues (future features/enhancements only — confirm with human before creating)
_(none — all findings are addressable in-PR)_
