import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Slim bar for a side monitor: its own workspaces, its own window, and the clock.
// It has no popovers. The main bar keeps the popovers, notifications and IPC.
PanelWindow {
    id: bar
    required property var modelData

    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.mainHeight
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property var mon: Hyprland.monitorFor(bar.screen)
    readonly property int shownId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : -1

    Rectangle { anchors.fill: parent; color: Theme.glass }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Cell {
            first: true
            label: "Workspace · " + bar.shownId
            icon: "workspaces"
            labelColor: Theme.tealLt
            OrbitWorkspaces {
                onlyScreen: bar.screen
                height: 19
                topPadding: 2
            }
        }
        WindowCell { screenRef: bar.screen; followFocus: false }
        Item { Layout.fillWidth: true }
        ClockCell {}
    }

    BarEdge { anchors.fill: parent }
}
