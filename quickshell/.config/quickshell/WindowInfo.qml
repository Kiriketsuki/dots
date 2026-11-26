import QtQuick
import Quickshell
import Quickshell.Hyprland

// Title and class of the window to show for one monitor. Uses the globally active window when
// it lives on this monitor, else the first window of the monitor's active workspace.
QtObject {
    id: root
    required property var screenRef
    // The main bar follows the focused window on any monitor. A side bar shows its own monitor.
    property bool followFocus: Theme.singleBar

    readonly property var mon: Hyprland.monitorFor(screenRef)
    readonly property var ws: mon ? mon.activeWorkspace : null
    readonly property var top: {
        const act = Hyprland.activeToplevel;
        if (root.followFocus)
            return act;
        if (act && act.workspace && ws && act.workspace.id === ws.id)
            return act;
        if (ws && ws.toplevels.values.length > 0)
            return ws.toplevels.values[0];
        return null;
    }
    readonly property string title: top ? top.title : ""
    readonly property string cls: top && top.lastIpcObject && top.lastIpcObject["class"] ? top.lastIpcObject["class"] : ""
}
