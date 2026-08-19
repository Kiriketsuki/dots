#!/usr/bin/env bash
# Toggle on-screen annotation (gromit-mpx) together with the Hyprland
# "annotate" submap.
#
# The submap is what makes Ctrl+Z / Ctrl+Y / Delete mean undo / redo / clear
# *only while drawing*. Outside annotation mode those keys keep their normal
# meaning in every application, so nothing is hijacked globally.
#
# Hyprland's own submap state is the single source of truth for on/off, so
# killing gromit-mpx can never strand us in a half-on state.
#
# gromit-mpx's control flags (-t/-z/-y/-c/-v) only work against an already
# running instance; with no instance it prints "Unknown Option ... startup"
# and exits WITHOUT starting one. We use that as the liveness probe: try to
# toggle, and if there is no daemon, start one with -a (start + activate),
# which turns drawing on in a single step. This avoids polling for readiness
# — the daemon does not map its overlay window until it is activated, so
# there is nothing to wait on.
set -euo pipefail

readonly SUBMAP="annotate"
readonly GROMIT="gromit-mpx"

die() {
    notify-send -u critical "Annotation" "$1" 2>/dev/null || true
    echo "error: $1" >&2
    exit 1
}

command -v "$GROMIT" >/dev/null 2>&1 \
    || die "$GROMIT is not installed. Install it with: yay -S gromit-mpx"

current_submap() {
    hyprctl submap 2>/dev/null | head -1 | tr -d '[:space:]'
}

# Send a control flag to a running gromit-mpx.
# Returns 1 if no instance is running (so the caller can start one).
gromit_control() {
    local output
    output="$("$GROMIT" "$@" 2>&1)" || true
    if grep -q "Unknown Option" <<<"$output"; then
        return 1
    fi
    return 0
}

# Replaces its own previous notification instead of stacking a new one each
# toggle, so the indicator reads as state rather than history.
readonly NOTIFY_TAG="gromit-annotate"

indicate() {
    notify-send -a "$NOTIFY_TAG" -h "string:x-canonical-private-synchronous:$NOTIFY_TAG" \
        -t "$2" "$1" "$3" 2>/dev/null || true
}

leave_submap() {
    hyprctl dispatch submap reset >/dev/null
}

# Hyprland does not honour the empty X input shape that gromit-mpx sets on its
# overlay while inactive, so the deactivated overlay would swallow every click
# and you could not reach the windows underneath. Hyprland's own `no_focus`
# does make the window click-through, so drive it per-state:
#     drawing  -> no_focus 0  (overlay takes the pointer, strokes land)
#     stopped  -> no_focus 1  (strokes stay visible, clicks fall through)
overlay_address() {
    hyprctl clients -j 2>/dev/null | python3 -c '
import json, sys
try:
    for c in json.load(sys.stdin):
        if c.get("title") == "gromit-mpx":
            print(c["address"])
            break
except Exception:
    pass
'
}

# $1: 1 = interactive (drawable), 0 = click-through
set_overlay_interactive() {
    local want_focus="$1" addr=""

    # When switching on, the overlay may not be mapped yet — poll briefly.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        addr="$(overlay_address)"
        [[ -n "$addr" ]] && break
        sleep 0.1
    done
    [[ -n "$addr" ]] || return 0

    if [[ "$want_focus" == "1" ]]; then
        hyprctl dispatch setprop "address:$addr" no_focus 0 >/dev/null 2>&1 || true
    else
        hyprctl dispatch setprop "address:$addr" no_focus 1 >/dev/null 2>&1 || true
    fi
}

# "quit" -> force close: wipe strokes and kill the daemon outright, so no
# overlay survives. Bound to Escape.
if [[ "${1:-}" == "quit" ]]; then
    gromit_control --clear || true
    gromit_control --quit || true
    # Belt and braces: --quit is a no-op if the daemon never registered.
    pkill -x "$GROMIT" 2>/dev/null || true
    leave_submap
    indicate "✏  Annotation closed" 1500 "Overlay cleared"
    exit 0
fi

if [[ "$(current_submap)" == "$SUBMAP" ]]; then
    # Currently drawing -> release the pointer grab but KEEP the strokes
    # on screen. Gromit sets an empty X input shape while inactive, so the
    # overlay stays visible while clicks fall through to the windows behind.
    # Escape (force close) is what actually wipes it.
    gromit_control --toggle || true
    set_overlay_interactive 0
    # Focus can still be sitting on the overlay; hand it back to the window
    # that had it before, otherwise keystrokes go nowhere.
    if [[ "$(hyprctl activewindow -j 2>/dev/null | grep -c '"title": "gromit-mpx"')" != "0" ]]; then
        hyprctl dispatch focuscurrentorlast >/dev/null 2>&1 || true
    fi
    leave_submap
    indicate "✏  Annotation OFF" 1500 "Drawing kept · clicks pass through"
else
    if ! gromit_control --toggle; then
        # No daemon yet: start one already activated.
        setsid "$GROMIT" -a >/dev/null 2>&1 </dev/null &
        disown
    fi
    set_overlay_interactive 1
    hyprctl dispatch submap "$SUBMAP" >/dev/null
    indicate "✏  Annotation ON" 3000 "Ctrl+Z undo · Ctrl+Y redo · Delete clear · Esc close"
fi
