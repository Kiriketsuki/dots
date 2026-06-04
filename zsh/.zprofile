# Put ~/.local/bin on PATH for the whole graphical session.
# .zshrc sets this for interactive shells, but display managers (SDDM) and the
# uwsm TTY1 launch start a *login* shell that never sources .zshrc — so apps
# launched from the session (e.g. rofi -show run) wouldn't otherwise find
# binaries here. Guarded to avoid duplicate entries on nested logins.
case ":${PATH}:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Start Hyprland on TTY1 login
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec uwsm start -- Hyprland
fi
