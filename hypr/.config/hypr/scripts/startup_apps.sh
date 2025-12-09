#!/bin/bash

# Launch communication apps directly to Workspace 10
# Using dispatch exec [workspace X] ensures they land there regardless of window rules

hyprctl dispatch exec "[workspace 20 silent] slack"
sleep 2

hyprctl dispatch exec "[workspace 30 silent] teams-for-linux"
sleep 2

hyprctl dispatch exec "[workspace 30 silent] thunderbird"
sleep 2

hyprctl dispatch exec "[workspace 10 silent] whatsapp-desktop-client"

hyprctl dispatch exec "[workspace 19 silent] spotify"