#!/usr/bin/env python3
"""
Startup script that detects connected monitors by model name and applies
correct resolutions and positions via hyprctl keyword monitor.

This avoids hardcoding DP port numbers, which differ between machines:
- Kinovo:      DP-3=W270, DP-2=X300, eDP-1 scale 1.5
- Kiwork-Arch: DP-2=W270, DP-3=X300, eDP-1 scale 1.0
"""
import json
import socket
import subprocess

# Monitor profiles keyed by model substring (matched with 'in')
MONITOR_PROFILES = {
    "W270": {"res": "1920x1080@144", "scale": 1.0},
    "X300": {"res": "2560x1080@165", "scale": 1.0},
}

# Preferred left-to-right ordering for external monitors
EXTERNAL_ORDER = ["W270", "X300"]

# Per-hostname scale for the built-in laptop display (keys lowercased for matching)
LAPTOP_SCALE = {
    "kinovo": 1.5,
    "kiwork-arch": 1.0,
}


def run_cmd(cmd):
    subprocess.run(cmd, shell=True)


def get_output(cmd):
    try:
        return subprocess.check_output(cmd, shell=True).decode("utf-8").strip()
    except Exception:
        return None


def get_profile(model: str):
    """Return (key, profile) if model contains any known profile key."""
    for key, profile in MONITOR_PROFILES.items():
        if key in model:
            return key, profile
    return None, None


def external_sort_key(mon):
    model = mon.get("model", "")
    for i, key in enumerate(EXTERNAL_ORDER):
        if key in model:
            return i
    return 99


def main():
    hostname = socket.gethostname().lower()
    edp_scale = LAPTOP_SCALE.get(hostname, 1.5)

    monitors_json = get_output("hyprctl monitors -j")
    if not monitors_json:
        return

    monitors = json.loads(monitors_json)

    laptop_mon = next((m for m in monitors if m["name"] == "eDP-1"), None)
    external_mons = sorted(
        [m for m in monitors if m["name"] != "eDP-1"],
        key=external_sort_key,
    )

    x = 0

    # Configure built-in display (leftmost)
    if laptop_mon:
        run_cmd(f"hyprctl keyword monitor eDP-1,preferred,{x}x0,{edp_scale}")
        phys_width = laptop_mon.get("width", 1920)
        x += int(phys_width / edp_scale)

    # Configure external monitors left-to-right by model preference
    for mon in external_mons:
        name = mon["name"]
        model = mon.get("model", "")
        _, profile = get_profile(model)

        if profile:
            res = profile["res"]
            scale = profile["scale"]
            run_cmd(f"hyprctl keyword monitor {name},{res},{x}x0,{scale}")
            phys_width = int(res.split("x")[0])
            x += int(phys_width / scale)
        else:
            # Unknown monitor — use preferred settings and advance by its physical width
            run_cmd(f"hyprctl keyword monitor {name},preferred,{x}x0,1")
            phys_width = mon.get("width", 1920)
            x += phys_width


if __name__ == "__main__":
    main()
