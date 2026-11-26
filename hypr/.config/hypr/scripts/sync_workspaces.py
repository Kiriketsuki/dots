import sys
import subprocess
import json
import time

import hyprlua

def get_output(cmd):
    try:
        return subprocess.check_output(cmd, shell=True).decode("utf-8").strip()
    except:
        return None

def main():
    if len(sys.argv) < 2:
        return

    try:
        base = int(sys.argv[1])
    except ValueError:
        return

    # 1. Get Connected Monitors (Sorted by position Left->Right)
    monitors_json = get_output("hyprctl monitors -j")
    if not monitors_json: return

    monitors = json.loads(monitors_json)
    # Sort by X position so "Monitor 1" is always the leftmost one
    monitors.sort(key=lambda x: x['x'])

    # Single-monitor: just switch workspace, no cross-monitor sync needed
    if len(monitors) == 1:
        hyprlua.focus_workspace(base)
        return

    # 2. Assign Workspaces to Connected Monitors
    for i, mon in enumerate(monitors):
        target_ws = base + (i * 10)
        name = mon['name']

        # Attempt to move the workspace to the monitor first (if it exists)
        # This ensures that if the workspace is open elsewhere, it gets pulled here
        hyprlua.move_workspace_to_monitor(target_ws, name)

        # Focus monitor and switch workspace in one Lua call. Hyprland 0.54.x hit
        # a CReservedArea assertion when these two came as separate dispatches.
        hyprlua.evaluate(
            f"hl.dispatch(hl.dsp.focus({{ monitor = {hyprlua.lua_str(name)} }})) "
            f"hl.dispatch(hl.dsp.focus({{ workspace = {int(target_ws)} }}))"
        )
        time.sleep(0.05)

    # 3. Prioritize Middle Monitor (Index 1) if available, else Left (Index 0)
    focus_idx = 1 if len(monitors) >= 3 else 0
    if monitors and len(monitors) > focus_idx:
        target_mon = monitors[focus_idx]
        # Just focus the monitor, the workspace is already set in the loop above
        hyprlua.focus_monitor(target_mon['name'])

if __name__ == "__main__":
    main()
