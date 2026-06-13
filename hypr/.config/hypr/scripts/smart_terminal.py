#!/usr/bin/env python3
"""
smart_terminal.py — context-aware terminal spawner.

- Active window is a Ghostty terminal running tmux:
    → split or new window based on pane count / layout
- Otherwise:
    → delegate to smart_spawn.py with the terminal command
"""
import sys
import subprocess
import json
import os

PANE_THRESHOLD = 4


def get_output(cmd):
    try:
        return subprocess.check_output(cmd, shell=True).decode("utf-8").strip()
    except Exception:
        return None


def run_cmd(cmd):
    try:
        subprocess.Popen(cmd, shell=True)
    except Exception:
        pass


def pid_tree_has_tmux(pid):
    """Return True if any child process of pid is a tmux client."""
    try:
        children = get_output(f"pgrep -P {pid}")
        if not children:
            return False
        for child_pid in children.split():
            cmdline_path = f"/proc/{child_pid}/cmdline"
            if os.path.exists(cmdline_path):
                with open(cmdline_path, 'rb') as f:
                    cmdline = f.read().decode("utf-8", errors="replace")
                if "tmux" in cmdline:
                    return True
            # recurse one level
            if pid_tree_has_tmux(child_pid):
                return True
    except Exception:
        pass
    return False


def handle_tmux():
    """Split or create a new window in the active tmux session."""
    pane_count_str = get_output("tmux display-message -p '#{window_panes}'")
    try:
        pane_count = int(pane_count_str)
    except (TypeError, ValueError):
        pane_count = 1

    if pane_count >= PANE_THRESHOLD:
        run_cmd("tmux new-window")
        return

    panes_info = get_output("tmux list-panes -F '#{pane_width} #{pane_height}'")
    if panes_info:
        first_line = panes_info.splitlines()[0].split()
        try:
            pane_width = int(first_line[0])
            pane_height = int(first_line[1])
        except (IndexError, ValueError):
            pane_width = pane_height = 0
    else:
        pane_width = pane_height = 0

    # If pane is already wider than tall (horizontal split exists), do vertical
    if pane_width > pane_height:
        run_cmd("tmux split-window -v")
    else:
        run_cmd("tmux split-window -h")


def main():
    terminal = sys.argv[1] if len(sys.argv) > 1 else "ghostty"

    active_raw = get_output("hyprctl activewindow -j")
    if not active_raw:
        # No active window — spawn fresh terminal
        script = os.path.expanduser("~/.config/hypr/scripts/smart_spawn.py")
        run_cmd(f"python3 {script} {terminal}")
        return

    try:
        active = json.loads(active_raw)
    except Exception:
        active = {}

    window_class = active.get("class", "").lower()
    pid = active.get("pid")

    is_ghostty = "ghostty" in window_class

    if is_ghostty and pid and pid_tree_has_tmux(str(pid)):
        handle_tmux()
    else:
        script = os.path.expanduser("~/.config/hypr/scripts/smart_spawn.py")
        run_cmd(f"python3 {script} {terminal}")


if __name__ == "__main__":
    main()
