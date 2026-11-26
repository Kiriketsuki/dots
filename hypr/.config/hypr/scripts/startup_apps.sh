#!/bin/bash

# Wait for setup_monitors.py to finish applying monitor configuration
sleep 2

MON_COUNT=$(hyprctl monitors -j | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

if [ "$MON_COUNT" -ge 3 ]; then
    # 3 monitors: eDP-1 (1-10), W270/center (11-20), X300/ultrawide (21-30)
    hyprctl dispatch 'hl.dsp.exec_cmd("slack", { workspace = "20 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("teams-for-linux", { workspace = "30 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("thunderbird", { workspace = "30 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("zapzap", { workspace = "10 silent" })'
    hyprctl dispatch 'hl.dsp.exec_cmd("spotify", { workspace = "19 silent" })'
    hyprctl dispatch 'hl.dsp.exec_cmd("obsidian", { workspace = "23 silent" })'
elif [ "$MON_COUNT" -eq 2 ]; then
    # 2 monitors: eDP-1 (1-10), external (11-20)
    hyprctl dispatch 'hl.dsp.exec_cmd("slack", { workspace = "20 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("teams-for-linux", { workspace = "20 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("thunderbird", { workspace = "10 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("zapzap", { workspace = "10 silent" })'
    hyprctl dispatch 'hl.dsp.exec_cmd("spotify", { workspace = "19 silent" })'
    hyprctl dispatch 'hl.dsp.exec_cmd("obsidian", { workspace = "13 silent" })'
else
    # 1 monitor: comm apps on 10, spotify on 9, obsidian on 3
    hyprctl dispatch 'hl.dsp.exec_cmd("slack", { workspace = "10 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("teams-for-linux", { workspace = "10 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("thunderbird", { workspace = "10 silent" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.exec_cmd("zapzap", { workspace = "10 silent" })'
    hyprctl dispatch 'hl.dsp.exec_cmd("spotify", { workspace = "9 silent" })'
    hyprctl dispatch 'hl.dsp.exec_cmd("obsidian", { workspace = "3 silent" })'
fi

# usaKi usage widget, only when the binary is installed
[ -x "$HOME/.local/bin/usaki" ] && hyprctl dispatch "hl.dsp.exec_cmd(\"$HOME/.local/bin/usaki\")"
