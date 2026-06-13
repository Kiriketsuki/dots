# Feature: Notification Centre Visual Redesign

> **STATUS: NOT IMPLEMENTED** -- This is a design spec for a visual redesign. The current codebase still has the plain v1 notification widgets (flat rectangles, no chamfered edges, no Cairo drawing, no grouping, no animations). All files listed under "Affected Components" need to be created or rewritten from scratch. None of the tasks in the Task Breakdown have been started.

## Overview

**User Story**: As a desktop power user, I want the Chrysaki notification centre, toasts, and bar toggle to match the jeweled glassmorphic design language of the bar islands so that the entire AGS shell feels like a unified precision instrument of dark glass and gemstones.

**Problem**: The notification system (panel, toasts, bar toggle) is functionally complete but visually disconnected from the bar. The bar islands use ChamferedBar with Cairo-drawn backgrounds (wave gradients, slash events, ripple collisions, border sine waves), the glass mixin (diagonal hatching + compositor blur), and jewel-tone JEWEL_PALETTE colours. The notification centre, toasts, and toggle are plain flat rectangles with no chamfered edges, no Cairo drawing, no glass mixin, and no animations. This creates a jarring visual discontinuity when the notification panel opens beside the richly animated bar.

**Out of Scope**:
- Inline reply text fields (stretch goal for a future iteration)
- Media player widget embedded in the panel (separate feature)
- Quick-settings tile grid in the panel (ServicePanel already handles this)
- Custom per-app notification rules or filtering
- Notification sound/audio management
- Drag-to-dismiss gesture (mouse-only desktop; no touch)

---

## Open Questions

| # | Question | Raised By | Resolved |
|:--|:---------|:----------|:---------|
| 1 | Should ChamferedPanel be a separate GObject or a mode flag on ChamferedBar? | Claude | [x] Separate GObject — avoids regressions on bar islands |
| 2 | Should toasts get per-toast ChamferedBar or a single wrapper? | Claude | [x] Single persistent ChamferedBar wrapper for the toast list — avoids GObject lifecycle overhead on transient 5s widgets |
| 3 | Should app grouping be collapsible? | Claude | [x] Yes — collapsible with stagger animation on expand |
| 4 | Circular countdown arc vs linear progress bar for toast auto-dismiss? | Claude | [x] 2px Cairo progress bar (linear) — simpler, less visual noise than circular arc over icon |

---

## Scope

### Must-Have
- **ChamferedPanel container**: Panel wrapped in a new `ChamferedPanel` GObject (vertical fork of ChamferedBar) with calm animation profile (wave gradient + border sine wave, no slashes/ripples) — acceptance: panel has chamfered corners and subtle animated gradient visible on open
- **Glass mixin on panel**: Inner content box uses `@include glass` (diagonal hatching + white tint + border) — acceptance: hatching texture visible over the blurred background
- **App grouping**: Notifications grouped by `appName` with collapsible sections — acceptance: notifications from the same app appear under a shared group header with count badge and expand/collapse chevron
- **Group header design**: 3px jewel-tone accent stripe + app icon + app name + count "(N)" + chevron toggle — acceptance: each app group has a distinct jewel-tone accent matching its deterministic colour assignment
- **Critical breakout lane**: Critical-urgency notifications break out of app groups to a pinned top section — acceptance: `notify-send -u critical` notification appears above all groups in error-red styled section
- **Notification row accent stripes**: 3px left vertical stripe on each row, coloured by app's jewel tone — acceptance: rows from different apps have visually distinct accent colours
- **Unread glow**: Unread notifications show `box-shadow` glow on the accent stripe that fades when panel is opened — acceptance: opening the panel removes the glow on all rows
- **Scrollable list**: `Gtk.ScrolledWindow` with max-content-height ~520px and automatic vertical scrollbar — acceptance: panel scrolls when >8-10 notifications are visible
- **50-notification hard cap**: Oldest notifications are auto-dismissed when count exceeds 50 — acceptance: sending 51 notifications purges the oldest
- **Row dismiss animation**: Slide-out right (margin-left 0->400px + opacity 1->0, 200ms) — acceptance: dismissing a notification shows visible slide-out before removal
- **Row entry stagger**: Rows fade in with 40ms stagger, 150ms duration, capped at 10 rows — acceptance: opening the panel shows a visible cascade entry animation
- **Toast ChamferedBar wrapper**: Toast list wrapped in a persistent ChamferedBar with calm animation — acceptance: toast container has chamfered corners and subtle gradient
- **Toast slide-in**: Cards slide in from right edge (300ms ease-out) — acceptance: new toasts animate in rather than appearing instantly
- **Toast progress bar**: 2px Cairo-drawn bar at bottom of each toast showing time remaining — acceptance: bar visibly shrinks from 100% to 0% over 5s (normal) or 8s (critical)
- **Toast depth stacking**: Successive toasts at reduced opacity (1.0/0.95/0.90/0.85) — acceptance: 4 stacked toasts show visible depth gradient
- **Hexagonal bar badge**: Unread count badge drawn as Cairo flat-top hexagon using `drawHexFlat()` — acceptance: badge is visibly hexagonal, not rectangular
- **Badge pulse animation**: Scale 1.0->1.3->1.0 + colour flash error->blonde->error (300ms) on count change — acceptance: badge visibly pulses when a new notification arrives
- **DND indicator on toggle**: Bell icon changes to bell-off glyph + `$blonde-light` colour when DND is active — acceptance: DND state is visible on the bar toggle without opening the panel
- **App colour mapping**: Deterministic hash of appName to JEWEL_PALETTE[0-9] via `appColorIndex()` — acceptance: the same app always gets the same jewel-tone accent

### Should-Have
- **Choreographed Clear All**: Cascade dismiss with 50ms stagger per card (not simultaneous) — acceptance: "Clear all" shows a visible waterfall dismiss animation
- **Group expand stagger**: Expanding a collapsed group shows rows fading in with stagger animation — acceptance: expanding a group with 5 notifications shows visible cascade entry
- **Panel open/close animation**: Opacity 0->1 + marginTop 38->48 over 250ms ease-out — acceptance: panel slides down and fades in rather than appearing instantly
- **Date separators**: "Today"/"Yesterday"/"Earlier" chamfered divider strips between temporal sections within the notification list — acceptance: notifications from different days have visible date headers
- **Toast hover-pause**: Hovering a toast pauses the progress bar and auto-dismiss timer — acceptance: mouse-over a toast prevents it from disappearing
- **Read/unread visual distinction**: Read notifications show `$text-secondary` summary vs `$text-primary` for unread — acceptance: read notifications are visually dimmer

### Nice-to-Have
- **Per-app deduplication**: Configurable list of apps (e.g., Spotify, volume) that replace their previous notification rather than stacking — acceptance: two successive Spotify notifications result in one row, not two
- **Scroll overflow indicators**: "+N above"/"+N below" angular badges at panel edges when content overflows — acceptance: scrolling down shows a "+3 above" badge at the top of the list
- **Critical glitch-in animation**: 1-frame horizontal jitter (+-6px) before resolve on critical toasts (Cyberpunk 2077 inspired) — acceptance: critical toasts have a brief visual glitch effect on entry
- **Notification body markup in toasts**: Apply `sanitizeBodyMarkup()` to toast body text (currently plain text only) — acceptance: toast body renders bold/italic markup from notification apps

---

## Technical Plan

**Affected Components**:

| File | Change |
|:-----|:-------|
| `widgets/ChamferedPanel.tsx` | **New** — Vertical fork of ChamferedBar with calm animation profile |
| `lib/notification-colors.ts` | **New** — `appColorIndex()` hash, `JEWEL_TEXT_COLORS[]`, colour utilities |
| `widgets/NotificationCenter.tsx` | **Rewrite** — ChamferedPanel wrapper, ScrolledWindow, grouping, priority lane, incremental updates |
| `widgets/NotificationToast.tsx` | **Rewrite** — ChamferedBar wrapper, progress bar DrawingArea, slide-in/out, hover-pause |
| `widgets/NotificationToggle.tsx` | **Rewrite** — Hexagonal Cairo DrawingArea badge, pulse animation, DND indicator |
| `styles/_notifications.scss` | **Rewrite** — Glass mixin, accent stripes, group styles, animation transitions, neon glow |

**Data Model Changes**:
- New module-level state in NotificationCenter.tsx: `Map<string, NotificationGroupState>` keyed by appName, tracking widget refs and expanded/collapsed state per group
- New module-level state: `Set<number>` of "seen" notification IDs to track read/unread status
- 50-notification cap enforcement in the `notifd.connect("notified")` handler

**API Contracts**: N/A — desktop widget, no HTTP APIs

**Dependencies**:
- Existing: `AstalNotifd`, `ChamferedBar` (fork source), `JEWEL_PALETTE`, `drawIslandBackground()`, `BorderWaveState`, `drawHexFlat()`, `@include glass`, `sanitizeBodyMarkup()`
- New: `Gio.DesktopAppInfo` for app icon resolution from `n.desktopEntry`
- New: `Gtk.ScrolledWindow` for scrollable notification list
- New: `Gtk.DrawingArea` for toast progress bars and hexagonal badge

**Key Technical Decisions**:
- `ChamferedPanel` is a separate GObject class, not a mode on `ChamferedBar`, to avoid regressions on bar islands. It differs in two ways: `_innerBox` is VERTICAL, and the animation profile is calm (gradient + border wave only, 15fps tick, no SlashEventState/RippleState)
- Toast list uses a single persistent `ChamferedBar` wrapper (not per-toast) to avoid GObject lifecycle overhead on transient widgets
- Notification grouping uses incremental updates (insert/remove individual rows) instead of full rebuild for performance with 50 notifications
- GTK4 CSS `transition` on `opacity`, `margin-left`, `margin-right` for row/toast animations; `GLib.timeout_add` for panel open/close and badge pulse where CSS transitions are unreliable
- App colour assignment uses a deterministic string hash of appName mod 10, so the same app always gets the same JEWEL_PALETTE colour across sessions

**Risks**:

| Risk | Likelihood | Mitigation |
|:-----|:-----------|:-----------|
| ChamferedPanel performance with tall panels (380x600px Cairo at 15fps) | Low | 15fps is conservative; gradient fill is fast; no slashes/ripples to compute |
| GTK4 CSS margin transitions unreliable for animations | Medium | Fallback to GLib.timeout_add imperative animation for any property that does not transition correctly |
| ScrolledWindow inside ChamferedBar distorts chamfered background drawing | Low | ScrolledWindow is a child of the inner box, not the overlay — Cairo draws behind it unaffected |
| 50-notification cap purges notifications user wanted to keep | Low | Only purges oldest; critical-urgency notifications could be exempt from purge as an enhancement |
| Incremental update complexity vs full rebuild | Medium | Maintain the full-rebuild `rebuildPanelRows()` as a fallback if incremental state drifts |

---

## Acceptance Scenarios

```gherkin
Feature: Notification Centre Visual Redesign
  As a desktop power user
  I want the notification system to match the Chrysaki design language
  So that the shell feels like a unified jeweled glassmorphic experience

  Background:
    Given AGS is running with AstalNotifd as the D-Bus notification daemon
    And swaync is not running

  Rule: Panel has chamfered glassmorphic container

    Scenario: Panel opens with ChamferedPanel background
      When the user clicks the NotificationToggle button
      Then the notification centre panel appears with chamfered corners
      And the panel shows a subtle animated wave gradient in jewel tones
      And the panel has diagonal hatching texture over the blurred background
      And the panel slides down and fades in over ~250ms

    Scenario: Panel closes with reverse animation
      Given the notification centre panel is open
      When the user clicks the NotificationToggle button again
      Then the panel fades out and slides up over ~200ms

  Rule: Notifications are grouped by application

    Scenario: Notifications from the same app are grouped
      Given 3 notifications from "Discord" and 2 from "Firefox"
      When the user opens the notification centre
      Then "Discord" appears as a group with header showing count "(3)"
      And "Firefox" appears as a group with header showing count "(2)"
      And each group header has a distinct jewel-tone accent stripe

    Scenario: Group collapse hides notification rows
      Given the "Discord" group is expanded with 3 notifications
      When the user clicks the group collapse chevron
      Then the 3 notification rows are hidden
      And the group header still shows the count "(3)"

    Scenario: Group expand reveals rows with stagger animation
      Given the "Discord" group is collapsed
      When the user clicks the group expand chevron
      Then the notification rows appear with a cascading fade-in animation

  Rule: Critical notifications appear in priority lane

    Scenario: Critical notification breaks out to top
      Given 5 normal notifications exist in the panel
      When a critical notification arrives via notify-send -u critical
      Then the critical notification appears at the very top of the panel
      And it is visually distinct with error-red styling and 12px chamfer
      And it is not nested under any app group

  Rule: Notification rows have jewel-tone accent stripes

    Scenario: Rows show app-specific accent colours
      Given notifications from "Discord", "Firefox", and "Slack"
      When the user views the notification centre
      Then each app's notifications have a distinct 3px left accent stripe
      And the same app always gets the same jewel-tone colour

    Scenario: Unread notifications have accent glow
      Given 3 unread notifications exist
      When the user opens the notification centre
      Then unread notifications show a subtle glow on the accent stripe
      And after opening, the glow fades on all notifications

  Rule: Dismiss animations

    Scenario: Individual dismiss slides out
      Given the notification centre is open with notifications
      When the user clicks the dismiss button on a notification
      Then the notification slides out to the right and fades over ~200ms
      And the remaining notifications reflow smoothly

    Scenario: Clear All cascades dismissals
      Given 5 notifications are visible
      When the user clicks "Clear all"
      Then notifications dismiss in sequence with ~50ms delay between each
      And the cascade creates a visible waterfall effect

  Rule: Scrollable list with hard cap

    Scenario: Panel scrolls with many notifications
      Given 15 notifications exist
      When the user opens the notification centre
      Then a scrollbar appears on the notification list
      And the user can scroll to see all notifications

    Scenario: Oldest notifications are purged at 50 cap
      Given 50 notifications exist
      When a 51st notification arrives
      Then the oldest notification is automatically dismissed
      And the total count does not exceed 50

  Rule: Toast popups have chamfered glass treatment

    Scenario: Toast slides in from the right
      Given DND is off
      When a notification arrives
      Then a toast card slides in from the right edge over ~300ms
      And the toast has a jewel-tone accent stripe
      And a 2px progress bar at the bottom shows time remaining

    Scenario: Toast progress bar depletes and auto-dismisses
      Given a normal toast is visible
      Then the progress bar shrinks from 100% to 0% over 5 seconds
      And the toast fades out when the bar reaches 0%

    Scenario: Critical toast has extended timeout
      Given DND is off
      When a critical notification arrives
      Then the toast has error-red accent styling
      And the progress bar depletes over 8 seconds instead of 5

    Scenario: Hovering pauses auto-dismiss
      Given a toast is visible with 3 seconds remaining
      When the user hovers the mouse over the toast
      Then the progress bar pauses
      And the toast does not auto-dismiss until the mouse leaves

    Scenario: Toast depth stacking
      Given 4 toasts are visible
      Then each successive toast from top has slightly reduced opacity
      And the stack creates a visual depth illusion

  Rule: Bar toggle has hexagonal badge with pulse

    Scenario: Hexagonal unread badge
      Given 3 unread notifications exist
      Then the NotificationToggle shows a hexagonal badge with "3"

    Scenario: Badge pulses on new notification
      Given 2 unread notifications exist
      When a new notification arrives
      Then the badge briefly pulses (scales up and flashes blonde)
      And the count updates to "3"

    Scenario: DND indicator on toggle
      Given DND is active
      Then the bell icon changes to bell-off style
      And the icon colour changes to blonde-light
```

---

## Task Breakdown

| ID | Task | Priority | Dependencies | Status |
|:---|:-----|:---------|:-------------|:-------|
| T1 | Create `ChamferedPanel.tsx` — fork ChamferedBar with VERTICAL inner box, calm animation profile (gradient + border wave only, 15fps), no slashes/ripples | High | None | pending |
| T2 | Create `lib/notification-colors.ts` — `appColorIndex()` hash function, `JEWEL_TEXT_COLORS[]` array, `getAppAccentColor()` utility | High | None | pending |
| T3 | Rewrite `NotificationCenter.tsx` — ChamferedPanel wrapper, ScrolledWindow, grouping data model (`Map<string, NotificationGroupState>`), priority lane for critical, incremental update strategy | High | T1, T2 | pending |
| T3.1 | Group header widget — 3px accent stripe + app icon (`Gio.DesktopAppInfo`) + name + count badge + chevron toggle | High | T3 | pending |
| T3.2 | Group collapse/expand — GTK `visible` toggle on group body with stagger opacity animation | High | T3.1 | pending |
| T3.3 | Notification row accent stripe — 3px left `<box>` with app jewel-tone background colour | High | T3, T2 | pending |
| T3.4 | Panel open/close animation — GLib.timeout_add opacity + marginTop transition (250ms/200ms) | Med | T3 | pending |
| T3.5 | Row entry stagger — 40ms delay per row, 150ms fade-in, cap at 10 | Med | T3.3 | pending |
| T3.6 | Row dismiss animation — CSS transition margin-left + opacity (200ms) | Med | T3.3 | pending |
| T3.7 | Choreographed Clear All — cascade dismiss with 50ms stagger per card | Med | T3.6 | pending |
| T3.8 | 50-notification hard cap — purge oldest in `notifd.connect("notified")` handler | Med | T3 | pending |
| T3.9 | Unread glow + read/unread visual distinction — box-shadow on accent stripe, summary text dimming | Med | T3.3 | pending |
| T4 | Rewrite `NotificationToast.tsx` — ChamferedBar wrapper for toast list, calm animation profile | High | T1 | pending |
| T4.1 | Toast slide-in animation — CSS transition margin-right + opacity (300ms) | High | T4 | pending |
| T4.2 | Toast progress bar — 2px Cairo `Gtk.DrawingArea` at bottom of each toast, shrinks over TOAST_MS | High | T4 | pending |
| T4.3 | Toast hover-pause — pause progress bar and auto-dismiss timer on mouse enter | Med | T4.2 | pending |
| T4.4 | Toast depth stacking — set_opacity(1.0/0.95/0.90/0.85) on visible toasts | Med | T4 | pending |
| T4.5 | Critical toast — 8s timeout, error-red accent + background tint | Med | T4, T2 | pending |
| T5 | Rewrite `NotificationToggle.tsx` — hexagonal Cairo DrawingArea badge using `drawHexFlat()` | High | T2 | pending |
| T5.1 | Badge pulse animation — GLib.timeout_add scale 9->12->9px + colour flash (300ms) | Med | T5 | pending |
| T5.2 | DND indicator — bell-off glyph + `$blonde-light` colour when DND active | Med | T5 | pending |
| T6 | Rewrite `styles/_notifications.scss` — glass mixin, accent stripes, group styles, transitions, scrollbar | High | T3, T4, T5 | pending |
| T7 | Date separators — "Today"/"Yesterday"/"Earlier" chamfered divider strips | Low | T3 | pending |
| T8 | Per-app deduplication — configurable app list that replaces previous notification | Low | T3 | pending |
| T9 | Scroll overflow indicators — "+N above/below" angular badges | Low | T3 | pending |

---

## Exit Criteria

- [ ] All Must-Have scenarios pass manually (`notify-send` test)
- [ ] No regressions on existing bar widgets (BarLeft, BarCenter, BarRight still render correctly)
- [ ] ChamferedPanel fork does not affect ChamferedBar behaviour (bar islands unchanged)
- [ ] Panel visually matches Chrysaki design system: chamfered container, jewel-tone accents, glassmorphism, diagonal hatching
- [ ] Toasts have chamfered container, slide-in animation, and visible progress bar
- [ ] Bar toggle badge is hexagonal with pulse animation
- [ ] App grouping works with collapse/expand and correct jewel-tone colour assignment
- [ ] Critical notifications appear in priority lane above all groups
- [ ] 50-notification cap is enforced
- [ ] All animations run smoothly without visible jank (target: 60fps for CSS transitions, 15fps for Cairo panel background)
- [ ] swaync fully replaced — no `swaync-client` calls remain in codebase

---

## References

- Previous spec: `ags-notification-center-spec.md` (v1 — functional implementation, this spec is the visual redesign)
- Issue: [#5 feat: AGS Notification Center](https://github.com/Kiriketsuki/chrysaki/issues/5)
- ChamferedBar source (fork base): `widgets/ChamferedIsland.tsx`
- Cairo drawing library: `lib/cairo-island.ts`, `lib/cairo-hex.ts`
- Glass mixin: `styles/_glass.scss`
- Palette reference: `PALETTE.md`
- Design rules: `CLAUDE.md` (Design Rules section — zero border-radius, gradient direction, text colour safety)
- ServicePanel pattern (popup toggle reference): `widgets/ServiceStatus.tsx`

### Design Inspiration Sources (from creative research)
- **Neon glass edge glow**: Dark glassmorphism trend (Prototypr/Medium 2024-2025) — jewel-tone Cairo stroke around card boundaries
- **Choreographed stagger**: end-4/dots-hyprland AGS v1 `notification.js` — cascade dismiss with per-card delay
- **Circular countdown / progress bar**: end-4/dots-hyprland — Cairo-drawn timeout indicator
- **App grouping with collapsible headers**: KDE Plasma 6, GNOME 46, end-4 Quickshell rewrite
- **Priority lane**: Apple Focus system — pinned critical section at panel top
- **Tonal depth without shadows**: Android Material You — surface colour shift by elevation tier
- **Hover-pause timeout**: Ax-Shell (Fabric/Python) — hovering pauses auto-dismiss
- **Date separators**: Ax-Shell — "Today"/"Yesterday" dividers in notification history
- **Per-app deduplication**: Ax-Shell — Spotify/volume replace previous notification
- **Chamfer depth = lifetime**: UX research synthesis — 4px ephemeral, 8px transient, 12px persistent
- **Scroll overflow indicators**: caelestia-dots/shell — "+N above/below" count badges
- **Zero chamfered card geometry**: Novel opportunity — no surveyed implementation uses angular cut corners for notification cards

---
*Authored by: Clault KiperS 4.6*
