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

def is_ws_empty(ws_id):
    # Get workspace info
    workspaces = json.loads(get_output("hyprctl workspaces -j"))
    for ws in workspaces:
        if ws['id'] == ws_id:
            return ws['windows'] == 0
    return True # Workspace doesn't exist yet, so it's empty

def main():
    if len(sys.argv) < 2:
        return

    # The command to run (e.g., "kitty" or "firefox")
    app_command = " ".join(sys.argv[1:])

    # 1. Get Monitor Count & Current Status
    monitors = json.loads(get_output("hyprctl monitors -j"))
    mon_count = len(monitors)
    
    active_ws = json.loads(get_output("hyprctl activeworkspace -j"))
    current_id = active_ws['id']
    
    # Calculate Base (1-10)
    # Example: If on WS 12, Base is 2. If on WS 1, Base is 1.
    if current_id > 0:
        base = (current_id - 1) % 10 + 1
    else:
        base = 1

    target_ws = current_id
    found_empty = False

    # 2. Check Logic: Current -> Next Monitor -> Next Monitor
    # We only check "slots" that actually correspond to connected monitors
    for i in range(mon_count):
        candidate = base + (i * 10)
        
        # If this candidate is the one we are already on, check if it's empty
        # If it's a different one (spillover), check if it's empty
        if is_ws_empty(candidate):
            target_ws = candidate
            found_empty = True
            break
    
    # 3. Execution
    if found_empty and target_ws != current_id:
        # If we found a better empty spot elsewhere, go there first
        run_cmd(f"hyprctl dispatch workspace {target_ws}")
    
    # Launch the app
    run_cmd(f"hyprctl dispatch exec {app_command}")

if __name__ == "__main__":
    main()
