# Chrysaki AGS Bar — Bug Fix Session

## Situation
Active bug-fix pass on the Chrysaki AGS bar (`feat/5-ags-notification-center` branch in the chrysaki submodule). All changes are committed and pushed. The bar renders correctly at this checkpoint but some visual polish issues remain open.

## Current State
- Branch: `feat/5-ags-notification-center` (chrysaki submodule)
- Dots repo: `main` (tracks chrysaki submodule pointer, up to date)
- Uncommitted in chrysaki: `ghostty/config` (unrelated, ignore)
- Uncommitted in dots: `hypr/` scripts, `nvim/`, `.claude/`, `AGENTS.md` (all pre-existing, unrelated to this work)
- Tests: none (no test suite for AGS bar)
- AGS instance: running as `chrysaki-bar`, started via `ags run ~/.config/ags/app.ts`

### What works
- Service status icons: white when healthy, red+blinking when unhealthy
- GitNexus health check: now uses `pgrep -f 'gitnexus'` (was `gitnexus status` which always exited 0)
- System tray expand/collapse: now uses `Gtk.Revealer` (SLIDE_RIGHT, 180ms) — no more snap-resize
- Right/left bar height parity: `power-button` CSS added, strips GTK Adwaita `min-height: 32px`

### What's incomplete / known issues
- Tray spacing after collapse: Revealer fix was just pushed; user hasn't confirmed it's resolved yet
- `svc-error` CSS in `_bar.scss` uses `opacity: 0.35` — this conflicts with the reactive `svc-error` class on `<image>` in ServiceStatus (which tries to set color via the class). The blink GLib timer handles opacity separately; the CSS `svc-error { opacity: 0.35 }` would permanently dim the icon even without blinking. Needs review.

## Key Files
- `chrysaki/ags/.config/ags/widgets/ServiceStatus.tsx` — bar service health icons + popup panel
- `chrysaki/ags/.config/ags/widgets/SystemTray.tsx` — tray expand/collapse with Revealer
- `chrysaki/ags/.config/ags/widgets/BarRight.tsx` — right bar segment definitions
- `chrysaki/ags/.config/ags/styles/_bar.scss` — bar/segment sizing, svc-error opacity rule
- `chrysaki/ags/.config/ags/styles/_services.scss` — service icon color rules
- `chrysaki/ags/.config/ags/styles/_utility-buttons.scss` — utility-button + power-button reset

## Decisions Made
- Service icon color in bar: **white when healthy, red (`svc-error`) when unhealthy** — user explicitly rejected per-service accent colors (was the first approach)
- GitNexus check: `pgrep -f 'gitnexus'` — `gitnexus status` CLI exits 0 regardless of daemon state
- `createPoll` initial value: kept as `"ok"` (was `"fail"`) — avoids startup flash of red on all icons
- Tray collapse: `Gtk.Revealer` over `visible={false}` on a plain `GtkBox` — Revealer properly animates space allocation, plain box caused separator DrawingAreas to appear mis-positioned
- `power-button` grouped with `utility-button` CSS — same visual treatment, single rule

## Failed Approaches
- Per-service accent colors on bar icons (svc-teal, svc-emerald etc): user rejected, wants all white
- `gitnexus status` as health check: exits 0 even when daemon not running
- `visible={false}` on `GtkBox` for tray collapse: bar snapped narrower causing content to appear mis-spaced

## Active Constraints
- chrysaki is a **git submodule** of dots. Always commit+push inside `chrysaki/` first, then update the submodule pointer in `dots/` and push dots.
- AGS restart: `ags quit --instance chrysaki-bar && nohup ags run /home/kiriketsuki/.config/ags/app.ts &>/tmp/ags.log &`
- AGS instance must be started from `~/.config/ags/app.ts` (symlinked from `chrysaki/ags/.config/ags/`)
- NVM: use absolute path `/home/kiriketsuki/.nvm/versions/node/v24.14.0/bin/node` in scripts

## Next Steps
1. **Verify Revealer fix** — ask user if the tray spacing looks correct after collapse. If still off, try `transitionType={3}` (SLIDE_LEFT) or `transitionType={0}` (NONE).
2. **Audit `svc-error` conflict** — `_bar.scss:51` has `.svc-error { opacity: 0.35 }` but `ServiceStatus.tsx` also applies `svc-error` class to the icon image to get CSS color. The opacity rule will permanently dim unhealthy icons to 0.35, the GLib blink timer then oscillates that. Decide: remove the CSS opacity rule (blink only) or remove the blink and use CSS only.
3. **`notif-badge` height check** — `NotificationToggle` has a `<label class="notif-badge" valign={1}>` that starts invisible. Confirm it doesn't add height when the badge count is 0. No CSS rule for `notif-badge` was found; may need `min-height: 0px`.

## Open Questions
- Is the tray Revealer spacing fix satisfactory or does it still look wrong?
- Should unhealthy service icons blink (current: blink + opacity) or just turn red (color only)?
