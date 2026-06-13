# Thermal Monitor Feature — Post-Council Remediation & Landing

## Situation
Ran an adversarial **council-loop workflow** (73 agents, 3 rounds, 55 confirmed findings) over the `feature/12` thermal-monitor branch in the `dots` repo. Verdict: **AGAINST as-is / CONDITIONAL on remediation**. The feature is a tmux status-bar segment + interactive popup implemented in one Python script. No code has been fixed yet — this session was review-only. Next session either does the git plumbing to make it landable, runs a fix pass, or both.

## Current State
- **Branch (dots):** `feature/12-feat-fan-speed-and-temperature-monitor-in-powerbar-popup-panel` — only commit is `4bcaa6c Initial commit from main`. ALL feature + drift is uncommitted working tree.
- **Submodule (chrysaki):** on branch `feat/tmux-session-restore` (NOT a thermal branch). `tmux/scripts/thermal.py` is **untracked** there. Wiring files modified: `tmux/{chrysaki.conf,tmux.conf,help.sh,scripts/palette.sh}`. Also has unrelated drift (AGENTS.md, CLAUDE.md, vscode css, deleted `feature_spec.md`, `.bak`, `__pycache__`).
- **Tests:** none exist for this feature; not run. `--bar` verified working by the council (one-shot, ~0.07s); `--popup` has crash bugs.
- **What works:** `--bar` mode (correct, contract-compliant), tmux wiring (`prefix+m`, help.sh, palette.sh, status-right-length 80→120), the stow symlink resolves.
- **What's incomplete/broken:** popup crashes on bad sensor/battery values (no exception guard); kill-mode + process tables violate spec scope; nothing committed so a merge ships zero feature code.
- **Artifact produced:** `2026-06-02-231425-council-thermal-monitor-feature.md` at dots root (full verdict + 55 findings).

## Key Files
- `2026-06-02-231425-council-thermal-monitor-feature.md` — council verdict, findings, ordered fixes, exit-criteria table
- `chrysaki/tmux/scripts/thermal.py` — the 504-line implementation (untracked in submodule)
- `thermal-monitor-spec.md` — spec; source of the scope contradiction (line 22 forbids process-killing)
- `chrysaki/tmux/tmux.conf` — `prefix+m` binding (~:201-208)
- `chrysaki/tmux/chrysaki.conf` — status-right segment + length
- `tmux/.config/tmux/scripts/thermal.py` — stow symlink → chrysaki source

## Decisions Made
- Ran the review as a **Workflow** (multi-agent fan-out), not the `council-fix` skill, because the user said "workflow" explicitly.
- Scoped the council to the thermal feature; treated the config drift (zshrc, hypr, backgrounds, etc.) as a **landing hazard**, not feature bugs.
- Verdict stands at AGAINST as-is / CONDITIONAL — gating items are (1) untracked/uncommittable, (2) popup crash on bad input, (3) kill-mode scope contradiction.
- Did **not** touch any code — review only. User was told a merge is "blocked, not impossible."

## Failed Approaches
None — single clean review pass. No dead ends to avoid.

## Active Constraints
- **Commit order matters:** the feature lives in the chrysaki submodule. Must commit + **push** the submodule first, THEN bump the dots pointer. Pinning a local-only/`-dirty` SHA dangles the pointer.
- **Stage by explicit pathspec — never `git add -A` / `commit -a`.** That would sweep in unrelated drift AND the `feature_spec.md` deletion. Restore `feature_spec.md` first.
- User convention: dated council results as `YYYY-MM-DD-HHMMSS-council-<topic>.md` at repo root.
- Don't pin chrysaki to `4079bee` (lacks thermal.py) or `71eb22c` (not on `origin/main`).

## Next Steps
1. **Resolve the scope question with the user first** (see Open Questions) — keep or remove kill-mode/process-tables. This changes what gets committed.
2. **Make it committable (critical):** in `chrysaki/` create `feat/12-thermal-monitor`, `git restore feature_spec.md`, `git add tmux/scripts/thermal.py tmux/chrysaki.conf tmux/tmux.conf tmux/help.sh tmux/scripts/palette.sh` (explicit paths), commit, `git push -u`.
3. **Bump dots pointer:** stage the chrysaki gitlink + the tracked symlink only, commit on `feature/12`.
4. **Fix high-severity bugs before merge:** wrap popup redraw loop in try/except (`thermal.py:321-469`, guard `_dig` float `:123` + battery int `:402-409`); add `if not ch: break` after `read(1)` at `:442` (EOF busy-spin).
5. Optionally run `/parallel-fix` or a fix workflow on high+medium findings.
6. Repo hygiene: add `__pycache__/`, `*.pyc`, `*.bak` to both `.gitignore`s; delete `chrysaki.conf.bak`.

## Open Questions
- **Kill mode + Top-CPU/RAM tables:** spec forbids process-killing (line 22). Remove them to honor the spec, OR amend the spec to accept them? User must decide — blocks what gets committed.
- **Fix path:** `/parallel-fix` remediation vs. manual edits this session?
- **Branch name** says "powerbar popup panel" but the feature is tmux-only (spec out-of-scopes Waybar/AGS). Rename branch/issue, or accept the misnomer?
