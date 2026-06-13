# Notification Centre Visual Redesign — Handoff

## Situation
Redesigning the Chrysaki notification system (panel, toasts, bar toggle) to match the bar's jeweled glassmorphic design language. The v1 widgets were functionally complete but visually flat — this redesign adds ChamferedPanel containers, Cairo-drawn badges, app grouping, animations, and glass mixin throughout.

Spec: `/home/kiriketsuki/dots/notification-center-redesign-spec.md`
Source: `/home/kiriketsuki/dots/chrysaki/ags/.config/ags/`
Branch: `main` (chrysaki submodule)

## Current State
- Branch: `main`
- Uncommitted changes in chrysaki submodule: 4 modified files, 2 new files
- Tests: not yet run — **build test is the critical next step**
- What works: All 6 files written per the spec (2 new infrastructure + 4 rewrites)
- What's incomplete: No runtime verification, no visual testing

### Files Changed (all under `chrysaki/ags/.config/ags/`)
| File | Status |
|------|--------|
| `lib/notification-colors.ts` | NEW — app color mapping utilities |
| `widgets/ChamferedPanel.tsx` | NEW — vertical fork of ChamferedBar |
| `widgets/NotificationCenter.tsx` | REWRITTEN — grouped, ChamferedPanel |
| `widgets/NotificationToast.tsx` | REWRITTEN — progress bar, slide-in |
| `widgets/NotificationToggle.tsx` | REWRITTEN — hex badge, pulse |
| `styles/_notifications.scss` | REWRITTEN — glass, groups, animations |

`app.ts` and `style.scss` required NO changes (imports unchanged).

## Key Files
- `chrysaki/ags/.config/ags/widgets/NotificationCenter.tsx` — main panel, grouping logic, 584 lines
- `chrysaki/ags/.config/ags/widgets/NotificationToast.tsx` — toast lifecycle + progress bar
- `chrysaki/ags/.config/ags/widgets/ChamferedPanel.tsx` — calm animation container
- `chrysaki/ags/.config/ags/widgets/ChamferedIsland.tsx` — ChamferedBar reference (fork source)
- `chrysaki/ags/.config/ags/lib/cairo-island.ts` — drawIslandBackground (reused by ChamferedPanel)
- `/home/kiriketsuki/dots/notification-center-redesign-spec.md` — full design spec

## Decisions Made
- ChamferedPanel is a separate GObject class (not a mode flag on ChamferedBar) — avoids regressions
- ScrolledWindow created imperatively via `$=` callback (AGS JSX doesn't support `<Gtk.ScrolledWindow>` natively)
- `notifd.connect("notified")` has two handlers: one for unread count (line ~59), one for panel incremental update (line ~436) — both needed, independent
- Entry animation in `addNotificationToPanel` returns the row widget but does NOT schedule its own idle_add — animation cleanup is done by callers (incremental handler uses idle_add, rebuild uses stagger timeouts)
- Used `\u{...}` Unicode escapes for Nerd Font glyphs instead of literal characters (both work)
- `Gtk.Box.prepend()` used for newest-first insertion in group body (simpler than `insert_child_after(row, null)`)

## Failed Approaches
- First tried `<Gtk.ScrolledWindow>` in JSX — not supported by AGS GTK4 JSX mapper; switched to imperative creation
- Initial `addNotificationToPanel` had an `idle_add` to remove entering class — conflicted with stagger animation in `rebuildPanelRows`; removed and moved animation to call sites
- First pass used wrong Nerd Font codes: `\u{f0a9a}` for bell-off (correct: `\u{f009b}`), `\u{f0A7C}` for clear-all (correct: `\u{f01b4}`)

## Active Constraints
- AGS GTK4 JSX only supports lowercase element names (`<box>`, `<label>`, etc.) — native Gtk widgets must be created imperatively
- Royal Blue and Amethyst are fill-only colors — too dark for text on dark surfaces (JEWEL_TEXT_CSS substitutes cerulean and teal-light)
- Zero border-radius rule — no `border-radius` anywhere
- `cd` is intercepted by zoxide — use absolute paths or `git -C`

## Next Steps

1. **Build test**: `cd ~/dots/chrysaki/ags/.config/ags && ags run` — fix any TypeScript errors
2. **Toast test**: `notify-send "Test" "Hello world"` — verify slide-in, progress bar, auto-dismiss
3. **Critical test**: `notify-send -u critical "Alert" "Critical!"` — verify 8s timeout, priority lane
4. **Panel toggle**: Click NotificationToggle — verify ChamferedPanel background, glass hatching, grouped notifications
5. **Grouping**: Send notifications from different apps — verify per-app accent colors and collapse/expand
6. **Animation verification**: Dismiss rows (slide-out), clear-all (cascade), badge pulse
7. **Regression check**: Verify BarLeft/BarCenter/BarRight still render correctly
8. **If CSS margin transitions are unreliable**: Switch row entry/dismiss to imperative GLib.timeout_add (proven pattern in WorkspaceIndicator.tsx)
9. **Fix any visual issues**: Glass mixin rendering, accent stripe colors, scrollbar behavior
10. **Commit**: Once verified, commit to chrysaki submodule and bump in dots

## Open Questions
- GTK4 CSS `transition` on `margin-left`/`margin-right` — may or may not animate correctly in AGS. Fallback plan exists (imperative animation) but needs runtime testing
- ScrolledWindow max-content-height — may need adjustment depending on how it renders inside ChamferedPanel's Overlay
- The `notifd.notifications` order (newest-first vs oldest-first) — assumed newest-first for slicing in cap enforcement; verify at runtime
