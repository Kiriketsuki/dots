import sys
import subprocess
import json

def run_cmd(cmd):
    try:
        subprocess.Popen(cmd, shell=True)
    except:
        pass

def get_output(cmd):
    try:
        return subprocess.check_output(cmd, shell=True).decode("utf-8").strip()
    except:
        return None

def main():
    if len(sys.argv) < 2:
        return

    direction = sys.argv[1].lower()

    # Get active workspace
    active_ws_json = get_output("hyprctl activeworkspace -j")
    if not active_ws_json: return
    current_ws_id = json.loads(active_ws_json).get("id", 1)

    # Get monitor count
    monitors = json.loads(get_output("hyprctl monitors -j"))
    mon_count = len(monitors)
    max_allowed_ws = mon_count * 10

    target_ws = current_ws_id

    if direction == "right":
        target_ws = current_ws_id + 10
    elif direction == "left":
        target_ws = current_ws_id - 10
    elif direction == "scratchpad_out":
        # Get active monitor info to find the underlying workspace
        monitors_json = get_output("hyprctl monitors -j")
        if monitors_json:
            monitors = json.loads(monitors_json)
            # Find focused monitor
            focused_mon = next((m for m in monitors if m.get("focused")), None)
            if focused_mon:
                # activeWorkspace usually points to the non-special workspace
                target_ws = focused_mon.get("activeWorkspace", {}).get("id")
    
    # Safety Checks
    if target_ws < 1:
        return # Don't go below WS 1
    if target_ws > max_allowed_ws:
        return # Don't go to a monitor that doesn't exist

    run_cmd(f"hyprctl dispatch movetoworkspace {target_ws}")

if __name__ == "__main__":
    main()
