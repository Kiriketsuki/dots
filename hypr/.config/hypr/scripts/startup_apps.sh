#!/bin/bash

# Wait for setup_monitors.py to finish applying monitor configuration
sleep 2

MON_COUNT=$(hyprctl monitors -j | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

if [ "$MON_COUNT" -ge 3 ]; then
    # 3 monitors: eDP-1 (1-10), W270/center (11-20), X300/ultrawide (21-30)
    hyprctl dispatch exec "[workspace 20 silent] slack"
    sleep 1
    hyprctl dispatch exec "[workspace 30 silent] teams-for-linux"
    sleep 1
    hyprctl dispatch exec "[workspace 30 silent] thunderbird"
    sleep 1
    hyprctl dispatch exec "[workspace 10 silent] zapzap"
    hyprctl dispatch exec "[workspace 19 silent] spotify"
    hyprctl dispatch exec "[workspace 23 silent] obsidian"
elif [ "$MON_COUNT" -eq 2 ]; then
    # 2 monitors: eDP-1 (1-10), external (11-20)
    hyprctl dispatch exec "[workspace 20 silent] slack"
    sleep 1
    hyprctl dispatch exec "[workspace 20 silent] teams-for-linux"
    sleep 1
    hyprctl dispatch exec "[workspace 10 silent] thunderbird"
    sleep 1
    hyprctl dispatch exec "[workspace 10 silent] zapzap"
    hyprctl dispatch exec "[workspace 19 silent] spotify"
    hyprctl dispatch exec "[workspace 13 silent] obsidian"
else
    # 1 monitor: comm apps on 10, spotify on 9, obsidian on 3
    hyprctl dispatch exec "[workspace 10 silent] slack"
    sleep 1
    hyprctl dispatch exec "[workspace 10 silent] teams-for-linux"
    sleep 1
    hyprctl dispatch exec "[workspace 10 silent] thunderbird"
    sleep 1
    hyprctl dispatch exec "[workspace 10 silent] zapzap"
    hyprctl dispatch exec "[workspace 9 silent] spotify"
    hyprctl dispatch exec "[workspace 3 silent] obsidian"
fi
