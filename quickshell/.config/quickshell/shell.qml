//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell

// Observatory bar. Run with: qs -p ~/dots/quickshell/.config/quickshell
ShellRoot {
    id: shell

    // The main monitor is Theme.mainMonitor when present, else the widest screen.
    readonly property var mainScreen: {
        const all = Quickshell.screens;
        const named = all.find(s => s.name === Theme.mainMonitor);
        if (named)
            return named;
        return all.slice().sort((a, b) => b.width - a.width)[0] || null;
    }

    Notify {
        id: notifySvc
        screenRef: shell.mainScreen
    }

    // Quickshell has its own reload popup in its own style. This hides it, and a failed
    // reload shows as one of our toasts instead. The old config keeps running on failure.
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }
        function onReloadFailed(errorString) {
            Quickshell.inhibitReloadPopup();
            notifySvc.push(notifySvc.record({ appName: "Quickshell", summary: "Bar reload failed", body: errorString, urgent: true }, true));
        }
    }

    // The launcher opens on the focused monitor. It replaces rofi.
    Launcher {}

    // One bar, on the main monitor. Notifications show there too.
    MainBar {
        modelData: shell.mainScreen
        notify: notifySvc
    }
}
