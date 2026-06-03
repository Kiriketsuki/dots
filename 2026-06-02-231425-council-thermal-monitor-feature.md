---
council: thermal-monitor-feature
branch: feature/12-feat-fan-speed-and-temperature-monitor-in-powerbar-popup-panel
date: 2026-06-02
method: council-loop workflow (loop-until-dry) — recon → 5 critic dimensions × 3 rounds → questioner-verify each finding → arbiter
stats:
  agents: 73
  rounds: 3
  findings_confirmed: 55
  by_severity: { critical: 1, high: 5, medium: 9, low: 27, info: 13 }
---

# Council Recommendation: Thermal Monitor Feature Branch

**Motion:** "The thermal-monitor feature branch (`feature/12`) is correct, in-scope, and ready to commit/merge."
**Date:** 2026-06-02

---

## Verdict: AGAINST (not ready to merge as-is); CONDITIONAL on remediation

The motion makes three claims — *correct*, *in-scope*, and *ready to commit/merge*. Each fails:

- **Ready-to-merge — FAILS hard (critical).** `thermal.py` is untracked in the chrysaki submodule (`?? tmux/scripts/thermal.py`, finding 23). Committing/merging the dots branch carries **zero thermal code**: the dots-side path is an untracked symlink (finding 43) and a `git add chrysaki` would advance the submodule pin to `4079bee` — a commit that does not contain `thermal.py` and exists on no remote (findings 24, 25, 40, 41). The implementation is uncommittable in its current state.
- **In-scope — FAILS partially (medium).** The spec's Out-of-Scope at `thermal-monitor-spec.md:22` explicitly forbids "process killing" and "active thermal remediation," yet the popup ships an interactive SIGTERM kill mode (`thermal.py:450`) plus Top-CPU/Top-RAM process tables that the popup Must-Have (`thermal-monitor-spec.md:51`) never lists (findings 5, 8, 9).
- **Correct — FAILS partially (high).** The popup redraw loop (`thermal.py:321-469`) has no exception guard; a single non-numeric sensor leaf through unguarded `float()` (`thermal.py:123`) crashes the entire popup with a traceback, violating the spec's per-row graceful-degradation contract at lines 55 and 180 (findings 1, 2, 3). The `--bar` path is, by contrast, verified correct and contract-compliant (findings 7, 20).

**Recommended disposition:** Do **not** merge now. Take the **CONDITIONAL** path: (a) fix the high-severity popup crash guard, (b) make a deliberate scope decision on the kill mode / process tables — either remove them to honour the spec, or amend the spec's Out-of-Scope and Must-Have to accept them, and (c) commit `thermal.py` on a dedicated, pushed thermal branch in the submodule before bumping the dots pointer. The `--bar` half is sound and the wiring (binding, help, palette) is correct; the blockers are the popup robustness defect, the scope contradiction, and the git plumbing.

---

## Summary

A single Python script (`chrysaki/tmux/scripts/thermal.py`, 504 lines) renders a tmux status-bar thermal segment (`--bar`: CPU temp + max fan RPM, threshold-coloured) and an interactive popup (`--popup`: temps, fans, NVMe, RAM, load, battery, plus process tables and a SIGTERM kill mode). The `--bar` mode is one-shot, emits only `#[fg=...]` tmux tags, and degrades to muted `N/A` — verified correct and contract-honouring. The popup is functionally rich but lacks a frame-level exception guard and ships two capabilities outside the agreed spec scope. Most critically, **nothing is committed**: `thermal.py` is untracked in the submodule, the submodule sits on an unrelated `feat/tmux-session-restore` branch, and the would-be pinned commit is local-only — so a merge would deliver no feature at all.

---

## Findings by Severity

### Critical

| # | Finding | Location | One-line fix |
|---|---------|----------|--------------|
| 23 | `thermal.py` untracked in submodule — committing dots ships nothing | `chrysaki/tmux/scripts/thermal.py` (`??`) | `git add`+commit in submodule on a thermal branch before pinning |

### High

| # | Finding | Location | One-line fix |
|---|---------|----------|--------------|
| 2 | No exception guard around per-frame redraw; any sensor/parse error crashes the popup | `thermal.py:321-469` | Wrap loop body / each collector in `try/except`, render `N/A` per row |
| 24 | Submodule pin `4079bee` recorded `-dirty` and exists on no remote — pointer would dangle | `chrysaki` gitlink | Push the thermal commit to origin before committing the dots pointer; never pin a `-dirty` SHA |
| 25 | Submodule on wrong branch (`feat/tmux-session-restore`), not a thermal branch | `chrysaki` HEAD | Create `feat/12-thermal-monitor`, commit only thermal files there |
| 40 | Committing dots advances pin to `4079bee`, which lacks `thermal.py` | `dots` gitlink → `chrysaki` | Pin to a commit that actually contains `thermal.py` |
| 41 | Pin `4079bee` on no remote branch; branch has no upstream | `chrysaki` | Push the backing commit (+set upstream) before pinning |

### Medium

| # | Finding | Location | One-line fix |
|---|---------|----------|--------------|
| 1 | Battery `int()` parsing unguarded — missing/non-int sysfs crashes popup | `thermal.py:402-404,409` | Parse via guarded helper returning `None`; degrade battery row to `N/A` |
| 3 | `_dig` `float()` unguarded — non-numeric sensor leaf crashes parse | `thermal.py:117-123` | Wrap `float()` in `try/except (TypeError, ValueError)`, return `None` |
| 5 / 8 | Kill mode + process tables are explicitly out of scope (spec line 22) | `thermal.py:308-469` (`os.kill` @450) | Remove kill mode/tables, **or** amend spec Out-of-Scope + Must-Have |
| 26 | Working-tree deletion of `feature_spec.md` would ride along in `commit -a` | `chrysaki/feature_spec.md` (` D`) | `git restore feature_spec.md`; stage thermal files by explicit path |
| 31 | Any escape-prefixed key (arrows/Home/F-keys/Alt) silently closes popup or cancels kill mode | `thermal.py:442,461-465` | After leading `\x1b`, peek for buffered bytes; only lone ESC = exit |
| 42 | Recorded pin is strict ancestor of working HEAD — naive `git add chrysaki` folds in unrelated advance | `chrysaki` gitlink | Inspect gitlink diff before staging; pin only the thermal commit |
| 43 | `thermal.py` untracked at dots level too (untracked stow symlink) | `dots tmux/.config/tmux/scripts/thermal.py` | Add+commit in submodule first; add the tracked symlink in dots |
| 45 | Popup busy-spins at 100% CPU on stdin EOF with no exit path | `thermal.py:441-469` | Add `if not ch: break` after `read(1)` |

### Low

| # | Finding | Location | One-line fix |
|---|---------|----------|--------------|
| 4 | Terminal not restored on SIGTERM/SIGHUP (low impact: throwaway pty) | `thermal.py:292-306` | Install SIGTERM/SIGHUP handlers raising `SystemExit` |
| 14 | Single-keypress SIGTERM, no confirmation | `thermal.py:443-460` | Add a confirm gate (double-press or y/n) before `os.kill` |
| 15 | Unsanitized `ps comm` rendered verbatim — terminal-escape injection | `thermal.py:484-494` | Strip `[\x00-\x1f\x7f]` from `p.name` before rendering |
| 16 | Uncaught `ValueError` on malformed battery sysfs crashes loop | `thermal.py:403-409` | Validate/guard `int()` of sysfs values |
| 18 | `bind m` omits `-x C -y C` used by sibling Command Palette popup | `chrysaki/tmux/tmux.conf:201-208` | Add `-x C -y C` for explicit-centering parity |
| 21 | Bar/popup glyphs depend on Nerd Font, undocumented in the script | `thermal.py:31-41` | Add a one-line comment noting the Nerd Font requirement |
| 29/10/11/46/35/34/48/37/47 | Spec/impl doc drift: stale `STATUS: NOT IMPLEMENTED`; dependency list lists unused `time`, omits `re`/`signal`/`dataclasses`/`pathlib`/`typing`; undocumented fan-RPM (4000) and load-avg (4.0/8.0) thresholds; `#b53f4a` not in `chrysaki.conf`; dead constants `ABYSS/BASE/SURFACE/RAISED`; "solely from CPU temp" wording vs RPM-coloured substring | `thermal-monitor-spec.md:3,50,101,106`; `thermal.py:21,26-30,99-104,189-193,390` | Update spec status, dependency list, and threshold/colour docs; drop dead constants |
| 27/53/54/44 | Stray artifacts not gitignored (`__pycache__/`, `*.pyc`, `chrysaki.conf.bak`) committable by `git add .` at both repo levels | `chrysaki/.gitignore`, `dots/.gitignore` | Add `__pycache__/`, `*.pyc`, `*.bak`; stage by explicit path |
| 28 | Unrelated submodule drift (AGENTS.md, CLAUDE.md, vscode css) | `chrysaki` working tree | Stash/separately commit docs+vscode drift |
| 32/50/52 | Robustness gaps in abnormal launch: unguarded `tcgetattr` on non-TTY; unguarded `/sys/class/nvme` read in `_nvme_model_map` reaches `--bar`; `-E` popup vanishes on early non-zero exit with no diagnostic | `thermal.py:136-142,293-298`; `tmux.conf:201-208` | `isatty()` guard; wrap nvme read in `try/except OSError`; wrap popup cmd with held-error fallback |
| 38 | PID-reuse TOCTOU: frozen-snapshot kill could SIGTERM a recycled PID | `thermal.py:447-450,467-469` | Re-resolve PID identity (comm/start-time) before signalling |
| 39/51 | Cosmetic: bar normal-path hugs `◆` separator (no leading space); segment sets no `bg=`, relies on inherited state | `thermal.py:182,191`; `chrysaki.conf:102` | Add a leading space + explicit `bg=#1c1f2b` to bar output |
| 55 | Recorded pin `71eb22c` only on `origin/fix/ags-bar-multi-monitor-polish`, not `origin/main` | `dots/.gitmodules` | Re-pin to a commit reachable from `origin/main` after pushing |

### Info (confirmations / non-defects)

Findings 6, 7, 12, 13, 17, 19, 20, 22, 30, 33, 36, 49 — see Concessions below.

---

## Scope Audit

Applying the relevance test (directly about the thermal feature) and the pre-existence test (would not exist without the motion):

**About the thermal feature (in-scope for this review):**
- Correctness defects in `thermal.py`: findings 1, 2, 3, 4, 14, 16, 31, 32, 33, 38, 45, 50, 52.
- Spec-scope divergences introduced by this feature: findings 5, 8, 9 (kill mode + process tables), 34, 35, 36, 48 (added threshold colouring), 10, 11, 29, 46, 47, 37 (spec/impl doc drift), 39, 51 (bar cosmetics).
- Git readiness of the feature: findings 23, 40, 41, 43 (untracked/uncommittable), 24, 25, 42 (pin/branch hygiene specific to landing this feature).

**Unrelated working-tree / submodule drift (NOT the thermal feature — pre-existing or incidental):**
- Finding 26 (`feature_spec.md` deletion), 28 (AGENTS.md / CLAUDE.md / vscode css edits), 27/53/54/44 (stray `__pycache__`/`.bak`/plugins/`.config` artifacts), 55 (pre-existing pin already off `origin/main`), 12 (branch-name "powerbar" vs tmux-only). These fail the pre-existence test as *defects of the feature* but are genuine **landing hazards**: they would contaminate a thermal commit under a careless `git add -A`/`commit -a`. Disposition: not feature bugs, but the commit must be staged by explicit pathspec to exclude them.

**Critical Discovery (informational only — not action items):**
- **Security (finding 15):** unsanitized `ps comm` rendered into ANSI output permits terminal-escape injection. Bounded by kernel `comm` truncation (~15 chars) and single-user context; an attacker already needs local process execution. Noted, not a merge blocker.
- **Security (finding 14, 38):** single-keypress SIGTERM and PID-reuse TOCTOU. No privilege boundary crossed (user can only signal own processes already shown by `ps`); SIGTERM is recoverable. Informational.
- No data-loss or compliance Critical Discovery found. None of the above rises to the OWASP-equivalent bar; they are recorded as notes, not dispositions the user must resolve before proceeding.

---

## Concessions / Non-Issues (honest record)

Critics looked for and did **not** find fault with the following:

- **Subprocess safety (finding 17):** both `sensors -j` and `ps axo` use list-form args, timeouts, and no `shell=True`; the only interpolated value (`sort_field`) is hardcoded by two private callers. No command-injection surface.
- **`--bar` rendering contract (findings 7, 20):** verified by execution — one-shot, exits ~0.07-0.12s, emits only `#[fg=...]` tags, zero raw ANSI bytes, valid UTF-8 degree sign, muted `N/A` fallback on missing sensors. Honours the bar contract fully.
- **Kill-key mapping correctness (finding 6):** displayed kill keys map exactly to the rows they label (CPU 1-5, RAM 6-9,0); kill mode freezes the proc list so the indexed target equals the displayed row. No wrong-process-kill defect.
- **CPU threshold values (brief fact 4):** match spec exactly — `<60` teal `#20969c`, `60-79.9` blonde `#FBB13C`, `>=80` error `#b53f4a`.
- **Graceful degradation core (finding 13):** all-`None` `SensorData` + per-row `N/A` works for partial sensor loss; the only gap is literal spec wording ("explicit error panel" vs per-row `N/A`).
- **Discoverability wiring (findings 22, 49):** `help.sh:81` and `palette.sh:70` are present, accurate, and byte-identical to the `bind m` invocation; popup is centered by tmux default.
- **Symlink health (finding 30):** the stow symlink resolves correctly to the real file; its only fragility is the untracked target (finding 23), not a broken link.
- **`status-right-length` 80→120 (finding 19):** comfortably covers the segment; long-branch truncation is a pre-existing, spec-acknowledged risk, not a regression.
- **Battery current sign (finding 33):** cosmetic display-only note; never affects control flow.

---

## Suggested Fixes (ordered, actionable)

1. **(Critical) Make the feature committable.** In the chrysaki submodule: create `feat/12-thermal-monitor`, `git add tmux/scripts/thermal.py tmux/chrysaki.conf tmux/tmux.conf tmux/help.sh tmux/scripts/palette.sh` (explicit paths — not `commit -a`), commit, and **push** so the SHA is reachable on origin. Only then bump the dots submodule pointer to that pushed commit. (findings 23, 24, 25, 40, 41, 42, 43)
2. **(High) Guard the popup redraw loop.** Wrap the frame body in `thermal.py:321-469` (or each metric collector) in `try/except` so any malformed reading renders `N/A` for that row only; in particular guard `_dig`'s `float()` (`:123`) and the battery `int()` parses (`:402-404,409`). (findings 1, 2, 3, 16)
3. **(High) Add EOF exit path.** Insert `if not ch: break` after `ch = sys.stdin.read(1)` at `thermal.py:442` to stop the 100% busy-spin and close cleanly on severed input. (finding 45)
4. **(Medium) Resolve the scope contradiction explicitly.** Either remove the kill mode and Top-CPU/Top-RAM tables (`thermal.py:308-469`, drop `_render_proc_table`/`_get_top_procs`/`ProcInfo`), **or** amend `thermal-monitor-spec.md` Out-of-Scope (line 22) and the popup Must-Have (line 51) to document and accept them, updating Decisions/Acceptance Scenarios. Do not merge while code and spec contradict each other. (findings 5, 8, 9)
5. **(Medium) Fix escape-key handling.** After a leading `\x1b`, peek with a non-blocking `select` and discard recognized CSI/SS3 sequences so arrow/Home/F-keys do not close the popup. (finding 31)
6. **(Medium) Quarantine unrelated drift.** `git restore chrysaki/feature_spec.md`; stash/separately commit the AGENTS.md/CLAUDE.md/vscode-css edits; stage thermal files by explicit pathspec. (findings 26, 28)
7. **(Low) Repo hygiene.** Add `__pycache__/`, `*.pyc`, `*.bak` to both `chrysaki/.gitignore` and `dots/.gitignore`; delete `chrysaki.conf.bak`. (findings 27, 44, 53, 54)
8. **(Low) Sync the spec to reality.** Flip `STATUS: NOT IMPLEMENTED` (line 3); correct the dependency list (drop `time`, add `re`/`signal`/`dataclasses`/`pathlib`/`typing`); document the fan-RPM (4000) and load-avg (4.0/8.0) thresholds and NVMe/RAM colour reuse, or relax the "solely from CPU temperature" wording; fix the `#b53f4a`-vs-`chrysaki.conf` cross-reference (point line 101 at the canonical palette). (findings 10, 11, 29, 34, 35, 36, 37, 46, 48)
9. **(Low) Hardening polish.** Sanitize `ps comm` (`thermal.py:484-494`); add a kill-mode confirm gate (`:443-460`); guard `tcgetattr` with `isatty()` (`:293`); wrap `_nvme_model_map` sysfs reads in `try/except OSError` (`:136-142`); add `-x C -y C` to `bind m` and a leading space + explicit `bg=` to the bar output; remove dead constants `ABYSS/BASE/SURFACE/RAISED`. (findings 14, 15, 32, 34, 39, 47, 50, 51, 18)

---

## Exit-Criteria Check (vs `thermal-monitor-spec.md:222-230`)

| Exit criterion | Status | Evidence |
|---|---|---|
| `--bar` returns quickly, prints valid tmux segment | **PASS** | One-shot, ~0.07s, only `#[fg=...]` tags, zero ANSI (findings 7, 20) |
| `--popup` refreshes every 2s and exits on `q`/`Esc` | **PARTIAL** | 2s cadence + `q`/`Esc` work, but escape-prefixed keys mis-exit (31) and EOF busy-spins (45); crashes on bad sensor/battery values (1, 2, 3) |
| `prefix + m` opens the popup | **PASS** | `tmux.conf:201-208` binding verified (findings 22, 49) |
| Right status keeps branch/host/time/date | **PASS** | `status-right-length` 80→120; segment fits (finding 19) |
| `tmux/.config/.../thermal.py` exists and resolves to source | **PARTIAL** | Symlink resolves (finding 30) **but target is untracked** — not in the repo as committable content (findings 23, 43) |
| Missing sensors / rows never crash bar or popup | **FAIL** | Bar degrades correctly; popup crashes on non-numeric leaf, missing/empty battery sysfs, `os.getloadavg`/nvme `OSError` (findings 1, 2, 3, 16, 50) |
| `prefix + ?` help documents the binding | **PASS** | `help.sh:81` documents `Prefix + m` (finding 22) |

**Net:** 4 PASS, 2 PARTIAL, 1 FAIL. The hard FAIL on graceful degradation and the untracked-target PARTIAL are the gating items, alongside the unmet scope boundary. The feature is close, but not yet correct, in-scope, or committable — verdict stands at **AGAINST as-is / CONDITIONAL on the fixes above.**
