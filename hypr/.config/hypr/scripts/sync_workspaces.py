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

    # 2. Assign Workspaces to Connected Monitors
    # Mon 0 -> Base, Mon 1 -> Base+10, Mon 2 -> Base+20
    cmds = []
    
    for i, mon in enumerate(monitors):
        target_ws = base + (i * 10)
        # Focus monitor first, then switch workspace
        # Use name instead of ID for reliability
        cmds.append(f"hyprctl dispatch focusmonitor {mon['name']}")
        cmds.append(f"hyprctl dispatch workspace {target_ws}")

    # Ensure we end up focused on the requested base workspace (Monitor 1)
    # We find the name of the first monitor (leftmost)
    if monitors:
        cmds.append(f"hyprctl dispatch focusmonitor {monitors[0]['name']}")
        cmds.append(f"hyprctl dispatch workspace {base}")

    # 3. Execute (Batch for performance)
    full_cmd = "; ".join(cmds)
    run_cmd(full_cmd)

if __name__ == "__main__":
    main()
