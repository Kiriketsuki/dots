---
## Adversarial Council — PR #7: Chrysaki Single Source

> Convened: 2026-03-21 18:05 | Advocates: 2 | Critics: 2 | Rounds: 2/4

### Motion
Should PR #7 "refactor: Chrysaki single source — decouple wallpaper theming" be merged as-is?

### Advocate Positions
**ADVOCATE-1**: The architectural pipeline is structurally sound: `_palette.scss` is the single canonical source, named tokens replace opaque indices across all six consumers, borders are deterministic, and -643 lines of conflicting dead code are removed. None of the verified bugs touch the pipeline's structural correctness. Conceded: LEGACY_INDEX_MAP is dead code; "WCAG compliance is structural" was overstated since rofi re-derives text colors independently; Ghostty ANSI index 4 is a real defect; committed outputs do not prove semantic correctness was reviewed.

**ADVOCATE-2**: The core architectural improvement is genuine and uncontested. Replacing opaque indexed tokens with named Chrysaki tokens eliminates positional coupling. The unidirectional data flow from `_palette.scss` to `theme.css` to per-app configs is structurally correct. WCAG-compliant text colors are now a first-class pipeline output for GTK, Waybar, and SwayNC consumers. Conceded: Ghostty ANSI palette is a real bug; stale script references are a genuine oversight; CLAUDE.md overstates rofi's token consumption; the committed-outputs argument demands that committed outputs be verified before reaching main.

### Critic Positions
**CRITIC-1**: Ghostty ANSI index 4 maps Blue to amber (#FBB13C) — a protocol violation affecting `ls`, `git diff`, man pages, and any `\e[34m` usage. Both advocates conceded it. Stale references to deleted `generate_and_apply_palette.sh` in committed outputs are verified. SCSS resolver silently drops multi-hop aliases (future fragility). Conceded: swaync does not consume theme.css (BUG 4 withdrawn); hardcoded `~/dots/` path has argv override and clear error (BUG 5 withdrawn); rofi WCAG needs documentation not migration.

**CRITIC-2**: Independently verified the Ghostty ANSI index 4 bug and stale script references. WCAG logic is duplicated between `generate_theme_css.py` and `rofi/scripts/update_colors.py` with divergent fallbacks (#2E3138/#FFF8F0 vs #ffffff/#000000). LEGACY_INDEX_MAP is dead code with no consumer. Conceded: bootstrap.sh scope is appropriate for personal dotfiles; SUPPLEMENTAL dict is adequately documented; ~/dots/ hardcode is acceptable; LEGACY_INDEX_MAP is non-blocking.

### Key Conflicts
- **Ghostty ANSI palette mapping** — Critics identified, advocates initially defended as "conscious design choice," then conceded after Dracula/Nord comparison and absence of documenting comment. **Resolved: verified bug, all agree.**
- **Rofi WCAG duplication** — Critics called it a second source of truth; advocates argued rofi uses centralized tokens as "preferred" and only re-validates. **Resolved: both sides agree CLAUDE.md should accurately describe the boundary; full WCAG consolidation deferred.**
- **LEGACY_INDEX_MAP** — Critics called dead code; advocates initially called it documentation. **Resolved: dead code, non-blocking.**
- **bootstrap.sh RTK/Rust scope** — Critics objected as scope creep; advocates argued it's appropriate for a bootstrap script. **Resolved: acceptable for personal dotfiles, non-blocking.**
- **swaync GTK CSS resolution** — CRITIC-1 raised concern about `@define-color` references inside CSS custom properties. **Resolved: pre-existing architectural pattern, not a regression introduced by this PR.**

### Concessions
- ADVOCATE-1 conceded LEGACY_INDEX_MAP is dead code, WCAG claim was overstated, Ghostty ANSI 4 is a defect, committed outputs don't prove semantic review
- ADVOCATE-2 conceded Ghostty ANSI bug, stale comments, CLAUDE.md overstates rofi consumption, committed-outputs argument
- CRITIC-1 conceded BUG 4 (swaync existence check — architecturally different), BUG 5 (hardcoded path — argv override exists), rofi needs documentation not migration
- CRITIC-2 conceded bootstrap.sh scope, SUPPLEMENTAL documentation, ~/dots/ hardcode, LEGACY_INDEX_MAP non-blocking

### Arbiter Recommendation
**CONDITIONAL**
The architectural improvement is genuine, uncontested, and valuable: named tokens, single-source pipeline, deterministic borders, and -643 lines of dead code removal represent a correct and material upgrade. The PR should not be merged as-is because it ships two verified bugs in committed outputs (Ghostty ANSI palette violation and stale script references) and an inaccurate architectural description in CLAUDE.md. These are bounded fixes — a single patch commit, not a rearchitecture. Merge after the patch.

### Conditions (if CONDITIONAL)
- Fix Ghostty ANSI palette indices 4, 12, and 14 in `ghostty/scripts/update_colors.py`
- Regenerate `ghostty/.config/ghostty/colors` from corrected script
- Fix stale `generate_and_apply_palette.sh` references in committed output file headers
- Update CLAUDE.md to accurately describe rofi's text-color computation boundary

### Suggested Fixes
#### Bug Fixes (always in-PR)
- **Ghostty ANSI index 4**: `ghostty/scripts/update_colors.py:43` — change `get('blonde', '#FBB13C')` to `get('blue', '#122858')` or `get('blue-light', '#1c3d7a')`. ANSI Blue must be in the blue chromatic family.
- **Ghostty ANSI index 12 (Bright Blue)**: `ghostty/scripts/update_colors.py:51` — change from `teal-light` to `blue-light` or `cerulean`. Currently indistinguishable from index 14 (Bright Cyan).
- **Ghostty ANSI index 14 (Bright Cyan)**: `ghostty/scripts/update_colors.py:53` — keep as `teal-light` (correct for Cyan family), now distinct from index 12 after the above fix.
- **Regenerate ghostty output**: run `ghostty/scripts/update_colors.py` to update `ghostty/.config/ghostty/colors` with corrected palette.
- **Stale comment in ghostty output**: `ghostty/.config/ghostty/colors:3` — references deleted `generate_and_apply_palette.sh`. Will be fixed by regeneration above.
- **Stale comment in lazygit output**: `lazygit/.config/lazygit/colors.yml:3` — references deleted `generate_and_apply_palette.sh`. Regenerate via `lazygit/.config/lazygit/scripts/update_colors.py`.

#### In-PR Improvements (scoped, non-bug)
- **CLAUDE.md architecture description**: update the pipeline diagram and surrounding text to note that rofi reads `text-chrysaki-*` tokens as preferred but re-validates text colors with its own WCAG logic and different fallbacks. Current description implies all consumers use tokens directly.
- **LEGACY_INDEX_MAP deletion**: `generate_theme_css.py:22-48` — 26 lines of dead code with no consumer (`--legacy` flag never passed). Optional but recommended cleanup.

#### PR Description Amendments
- Note that Ghostty ANSI palette was corrected in the patch commit
- Clarify that rofi's text-color computation is a partial (not full) migration to centralized tokens

#### New Issues (future features only — confirm with human before creating)
- **Rofi WCAG consolidation** — Remove duplicate WCAG logic from `rofi/scripts/update_colors.py:5-37`, consume `text-chrysaki-*` tokens directly from theme.css. Deferred because the current hybrid approach works correctly and the divergence risk is bounded. — Task
- **SCSS multi-hop alias resolution** — Add iterative resolution or explicit error in `generate_theme_css.py:119-133` for chained SCSS aliases (`$foo: $bar` where `$bar: $baz`). Not currently triggered by the palette but unguarded. — Task
---
