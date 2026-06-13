# Chrysaki AGS Bar — Multi-Monitor Workspace + Opacity + Notification Fixes

## Situation
Fixing the Chrysaki AGS bar (GTK4/TypeScript) across three areas:
workspace indicator range (was 1–10, needs 1–30 for 3 monitors), island background
opacity (too transparent against wallpaper), and notification action buttons
(wrong API call, broken window focus). All work is in the `chrysaki` submodule
at `~/dots/chrysaki/`. The dots repo is on `main`.

## Current State
- Branch: `main` (both dots and chrysaki)
- chrysaki submodule: **4 files modified, not committed**
  - `ags/.config/ags/widgets/WorkspaceIndicator.tsx`
  - `ags/.config/ags/widgets/BarCenter.tsx`
  - `ags/.config/ags/widgets/NotificationCenter.tsx`
  - `ags/.config/ags/lib/cairo-island.ts`
- dots repo: unrelated uncommitted changes (backgrounds, hypr colors, zsh, nvim) — do NOT commit those as part of this work
- No tests (AGS has no test suite — verification is live in the bar via `rags`)

**What works:**
- Island backgrounds: animated (left/right) at 0.85 alpha, static center at 0.90 Abyss base — readable over any wallpaper
- WorkspaceIndicator: accepts `gdkmonitor`, sorts monitors by x-position, assigns left→1–10, middle→11–20, right→21–30
- Pip labels: localized (`id % 10 === 0 ? String(id - 10) : String(id)`) so WS 10→"0", WS 20→"10", WS 30→"20"
- PipSeparator: uses `rangeMax` prop instead of hardcoded `10`
- Notification actions: `n.invoke(action.id)` (was wrongly `n.invokeAction`)
- Window focus on action click: searches `hyprland.clients` by `initialClass` match, dispatches `address:0x...` only if found (no fallback class dispatch to avoid "No such window" errors)
- `rebuildPanelRows` deferred via `GLib.idle_add` when triggered by `notify::notifications` signal

**What needs verification:**
- Workspace pip active styling on monitors 2 and 3 (workspaces 11–20 and 21–30) — haven't confirmed pips light up Royal Blue + rotate on those monitors
- Whether notification action "View" actually switches workspace when the matching app IS open

## Key Files
- `chrysaki/ags/.config/ags/widgets/WorkspaceIndicator.tsx` — monitor range + pip label fix
- `chrysaki/ags/.config/ags/widgets/BarCenter.tsx` — passes `gdkmonitor` to WorkspaceIndicator
- `chrysaki/ags/.config/ags/widgets/NotificationCenter.tsx` — invoke fix + focuswindow dispatch
- `chrysaki/ags/.config/ags/lib/cairo-island.ts` — island opacity (lines ~704–714)

## Decisions Made
- **Monitor→workspace mapping**: sort `app.get_monitors()` by `get_geometry().x`, index 0=left(1–10), 1=middle(11–20), 2=right(21–30). Chosen over AstalHyprland monitor matching to avoid connector-name fragility.
- **Pip label "0"**: `id % 10 === 0 → String(id - 10)`. WS10→"0", WS20→"10", WS30→"20". User specified this convention.
- **Animated island alpha**: 0.85 black base (was 0.30). User asked for 0.65→0.75→0.85 in increments.
- **Static island (center)**: Abyss `#0f1117` at 0.90 alpha via `else` branch in `drawIslandBackground`. Was missing entirely (only 0.05 white glass).
- **focuswindow dispatch**: `address:` only when client found, no `class:` fallback. Reason: class fallback caused "No such window found" Hyprland errors when app wasn't open.
- **rebuildPanelRows deferral**: `GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, ...)` to avoid `onCleanup` "out of tracking context" warning when triggered from within a signal callback.

## Failed Approaches
- `class:${needle}` fallback in focuswindow dispatch — caused Hyprland "No such window found" errors when app not open; removed.
- `n.invokeAction(action.id)` — method doesn't exist on AstalNotifd.Notification; correct API is `n.invoke(action_id)`.

## Active Constraints
- chrysaki is a **submodule** of dots — all AGS edits are in `~/dots/chrysaki/`, NOT `~/dots/ags/`
- AGS restart: `rags` alias in zsh (`pkill -f "gjs -m /run/user/1000/ags.js" && sleep 1 && ags run ~/.config/ags/app.ts &`)
- "out of tracking context" CRITICAL warnings at startup are **harmless** — appear whenever `rebuildPanelRows` creates JSX outside a reactive root. NotificationToast has the same pattern. Do not chase these.
- The dots repo has unrelated uncommitted changes — don't bundle them into chrysaki commit
- `app.get_monitors()` returns array-like; spread with `[...app.get_monitors()]` before `.sort()`

## Next Steps
1. User verifies workspace pips on monitors 2 and 3 — switch to WS 11 and WS 21, confirm Royal Blue hex + rotation
2. User verifies notification action "View" when the source app is open — confirm workspace switches
3. Commit chrysaki: `cd ~/dots/chrysaki && git add ags/.config/ags/widgets/NotificationCenter.tsx ags/.config/ags/widgets/WorkspaceIndicator.tsx ags/.config/ags/widgets/BarCenter.tsx ags/.config/ags/lib/cairo-island.ts && git commit -m "fix(ags): multi-monitor workspace range, island opacity, notification invoke + focus"`
4. Bump chrysaki submodule in dots: `cd ~/dots && git add chrysaki && git commit -m "chore: bump chrysaki — multi-monitor pips, opacity, notification fixes"`

## Open Questions
- Do pips on monitors 2/3 correctly show active styling (`_focusedWsId` + rotation)? The fix was from the previous session but only tested on monitor 1.
- For notification window focus: does `n.invoke(action.id)` alone cause Wayland-native apps to raise their window (making the Hyprland dispatch redundant), or is the `address:` dispatch the only path?
