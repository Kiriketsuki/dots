#!/usr/bin/env bash
# ags-monitor-handler.sh
# Listens to the Hyprland event socket for monitor hotplug events and restarts
# AGS so the bar recovers on every monitor. Runs as a long-lived daemon.
#
# Add to hyprland.conf:
#   exec-once = ~/.config/hypr/scripts/ags-monitor-handler.sh

LOG=/tmp/ags-monitor-handler.log
DEBOUNCE=2  # seconds — only one restart per burst of events

log() {
    printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

restart_ags() {
    log "Monitor event detected — restarting AGS"

    # Kill any running AGS instance gracefully first, fall back to SIGKILL
    if ags quit 2>/dev/null; then
        log "ags quit succeeded"
    else
        # Look for the gjs process hosting ags.js and kill it
        pkill -f 'gjs.*ags' 2>/dev/null && log "pkill gjs.*ags succeeded" \
            || log "No gjs/ags process found to kill"
    fi

    sleep 1

    log "Launching AGS"
    ags run ~/.config/ags/app.ts &>> "$LOG" &
    log "AGS launched (PID $!)"
}

# -------------------------------------------------------------------------
# Locate the Hyprland event socket (.socket2.sock)
# The socket lives under /run/user/<UID>/hypr/<instance>/
# -------------------------------------------------------------------------
find_socket() {
    local uid
    uid=$(id -u)
    local hypr_dir="/run/user/${uid}/hypr"

    # Pick the most-recently-modified instance directory (handles multiple instances)
    local instance
    instance=$(ls -t "$hypr_dir" 2>/dev/null | head -1)
    if [[ -z "$instance" ]]; then
        log "ERROR: No Hyprland instance found under ${hypr_dir}"
        return 1
    fi

    local sock="${hypr_dir}/${instance}/.socket2.sock"
    if [[ ! -S "$sock" ]]; then
        log "ERROR: socket not found at ${sock}"
        return 1
    fi

    printf '%s' "$sock"
}

# -------------------------------------------------------------------------
# Main loop — read events from .socket2.sock, debounce, restart AGS
# -------------------------------------------------------------------------
main() {
    log "=== ags-monitor-handler started (PID $$) ==="

    local sock
    while true; do
        sock=$(find_socket)
        if [[ -z "$sock" ]]; then
            log "Waiting 5 s for Hyprland socket..."
            sleep 5
            continue
        fi

        log "Listening on ${sock}"

        # Debounce state
        local pending=0
        local last_event=0

        # ncat -U reads from a UNIX domain socket; events are newline-separated.
        # We use a while-read loop so we can apply debouncing.
        while IFS= read -r event; do
            case "$event" in
                monitoradded*|monitorremoved*|monitoraddedv2*)
                    local now
                    now=$(date +%s)
                    log "Raw event: ${event}"

                    if (( now - last_event > DEBOUNCE )); then
                        # No recent restart — trigger immediately
                        last_event=$now
                        pending=0
                        restart_ags
                    else
                        # Within debounce window — mark pending, do not restart again
                        log "Event within debounce window (${DEBOUNCE}s) — skipping duplicate restart"
                        pending=1
                        last_event=$now
                    fi
                    ;;
            esac
        done < <(ncat -U "$sock" 2>>"$LOG")

        log "Socket read loop exited (Hyprland may have restarted) — reconnecting in 3 s"
        sleep 3
    done
}

main
