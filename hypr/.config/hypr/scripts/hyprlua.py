"""Helpers for the Lua IPC of Hyprland 0.57+.

Hyprland 0.57 dropped the old `hyprctl dispatch <name> <args>` form and
`hyprctl keyword`. `hyprctl dispatch` now takes one Lua dispatcher expression,
and `hyprctl eval` runs any Lua chunk.
"""
import subprocess


def lua_str(value):
    """Return value as a Lua string literal, with backslash and quote escaped."""
    text = str(value).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{text}"'


def dispatch(expr, wait=True):
    """Run one dispatcher expression, for example 'hl.dsp.focus({ workspace = 3 })'."""
    cmd = ["hyprctl", "dispatch", expr]
    if wait:
        subprocess.run(cmd, check=False, stdout=subprocess.DEVNULL)
    else:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL)


def evaluate(code):
    """Run a Lua chunk inside Hyprland."""
    subprocess.run(["hyprctl", "eval", code], check=False, stdout=subprocess.DEVNULL)


def exec_cmd(command, wait=True):
    dispatch(f"hl.dsp.exec_cmd({lua_str(command)})", wait)


def focus_workspace(ws_id, wait=True):
    dispatch(f"hl.dsp.focus({{ workspace = {int(ws_id)} }})", wait)


def focus_monitor(name, wait=True):
    dispatch(f"hl.dsp.focus({{ monitor = {lua_str(name)} }})", wait)


def move_window_to_workspace(ws_id, wait=True):
    dispatch(f"hl.dsp.window.move({{ workspace = {int(ws_id)}, follow = true }})", wait)


def move_workspace_to_monitor(ws_id, monitor, wait=True):
    dispatch(f"hl.dsp.workspace.move({{ workspace = {int(ws_id)}, monitor = {lua_str(monitor)} }})", wait)
