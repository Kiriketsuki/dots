#!/bin/bash

# Reload apps that cache theme CSS.
# All theme outputs are committed — no generation needed.

swaync-client -rs 2>/dev/null || true
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -RTMIN+1 waybar 2>/dev/null || true
