#!/usr/bin/env bash
# Runs one power action for the launcher: lock, suspend, logout, hibernate,
# reboot or shutdown. The launcher asks for confirmation before it calls this.
set -u
case "${1:-}" in
lock) exec "$HOME/.config/hypr/scripts/lock.sh" ;;
suspend)
	# Pause music and mute first, as the old rofi power menu did.
	mpc -q pause 2>/dev/null
	amixer -q set Master mute 2>/dev/null
	exec systemctl suspend
	;;
logout) exec hyprctl dispatch 'hl.dsp.exit()' ;;
hibernate) exec systemctl hibernate ;;
reboot) exec systemctl reboot ;;
shutdown) exec systemctl poweroff ;;
*)
	echo "power.sh: unknown action '${1:-}'" >&2
	exit 2
	;;
esac
