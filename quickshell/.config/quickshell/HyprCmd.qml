pragma Singleton
import QtQuick
import Quickshell

// Hyprland 0.57 takes Lua expressions in `hyprctl dispatch`.
Singleton {
    // Focuses the T3 Code window. Starts the app when no window exists.
    function focusT3() {
        Quickshell.execDetached(["sh", "-c", "hyprctl clients -j | grep -q '\"class\": \"com.t3tools.T3Code\"' && hyprctl dispatch 'hl.dsp.focus({ window = \"class:com.t3tools.T3Code\" })' || gtk-launch com.t3tools.T3Code"]);
    }

    function focusWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + Math.floor(id) + " })"]);
    }
}
