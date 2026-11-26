import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces of every monitor, grouped left to right in screen order. sync_workspaces.py
// gives the monitor at index i (sorted by x) the ids 10*i+1 to 10*i+10. Each group shows
// only workspaces with windows, plus the workspace that its monitor shows.
Row {
    id: root
    spacing: 10

    // When set, the row shows only this screen's group. A side bar uses it.
    property var onlyScreen: null

    // Quickshell.screens always has positions. Hyprland.monitors can be empty for a moment
    // after a reload.
    readonly property var screensByX: Quickshell.screens.slice().sort((a, b) => a.x - b.x)
    readonly property var focusedMon: Hyprland.focusedMonitor
    readonly property int activeId: focusedMon && focusedMon.activeWorkspace ? focusedMon.activeWorkspace.id : -1

    // on: the workspace you are on. vis: shown on another monitor. need: urgent. occ: has windows.
    function kindFor(id, shownHere) {
        if (id === activeId)
            return "on";
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (ws && ws.urgent)
            return "need";
        if (id === shownHere)
            return "vis";
        if (!ws)
            return "empty";
        return ws.toplevels.values.length > 0 ? "occ" : "empty";
    }

    function groupFor(index, screen) {
        const mon = Hyprland.monitorFor(screen);
        const shownHere = mon && mon.activeWorkspace ? mon.activeWorkspace.id : -1;
        const ids = [];
        for (let i = 1; i <= 10; i++) {
            const id = index * 10 + i;
            if (kindFor(id, shownHere) !== "empty")
                ids.push({ id: id, kind: kindFor(id, shownHere) });
        }
        return ids;
    }

    Repeater {
        model: root.screensByX
        Row {
            id: group
            required property var modelData
            required property int index
            spacing: 4
            readonly property var items: root.groupFor(index, modelData)
            readonly property bool picked: !root.onlyScreen || modelData.name === root.onlyScreen.name
            visible: picked && items.length > 0
            // A short dashed rule splits one monitor's group from the next.
            DashedLine {
                visible: group.index > 0 && !root.onlyScreen
                width: 1
                height: 17
            }
            Repeater {
                model: group.items
                OrbitRing {
                    required property var modelData
                    wsId: modelData.id
                    kind: modelData.kind
                }
            }
        }
    }
}
