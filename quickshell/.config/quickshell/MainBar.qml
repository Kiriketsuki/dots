import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// Full bar for the main monitor.
PanelWindow {
    id: bar
    required property var modelData
    property string pane: ""
    property var notify: null

    function toggle(name) { pane = pane === name ? "" : name; }

    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.mainHeight
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.keyboardFocus: bar.pane !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Item {
        focus: true
        Keys.onEscapePressed: bar.pane = ""
    }

    Rectangle { anchors.fill: parent; color: Theme.glass }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        WorkspaceCell { id: wsCell; first: true; screenRef: bar.screen; onClicked: bar.toggle("workspace") }
        // Left: workspaces, the window, music and volume. Free space, then the machine and
        // account cells on the right.
        WindowCell { id: winCell; screenRef: bar.screen; onClicked: bar.toggle("window") }
        MediaCell { id: mediaCell; onClicked: bar.toggle("media") }
        VolumeCell { id: volCell; onClicked: bar.toggle("volume") }
        Item { Layout.fillWidth: true }
        NetCell { onClicked: bar.toggle("volume") }
        CpuCell { id: cpuCell; onClicked: bar.toggle("cpu") }
        MouseCell { id: mouseCell; onClicked: bar.toggle("mouse") }
        UsakiCell { id: usakiCell; onClicked: bar.toggle("usaki") }
        NeedsCell {
            id: needsCell
            notify: bar.notify
            onClicked: if (bar.notify && bar.notify.active) bar.notify.listOpen = !bar.notify.listOpen
        }
        ClockCell { id: clockCell; onClicked: bar.toggle("clock") }
    }

    BarEdge { anchors.fill: parent }

    // `qs ipc call bar toggle usaki` opens a pane without a click.
    IpcHandler {
        target: "bar"
        // One handler per target name. Only the bar on the main monitor answers.
        enabled: bar.screen && bar.screen.name === Theme.mainMonitor
        function toggle(name: string): void { bar.toggle(name); }
    }

    UsakiPane { id: usakiPane; anchorItem: usakiCell; open: bar.pane === "usaki" }
    WorkspacePane { id: workspacePane; anchorItem: wsCell; screenRef: bar.screen; open: bar.pane === "workspace"; onPicked: bar.pane = "" }
    WindowPane { id: windowPane; anchorItem: winCell; screenRef: bar.screen; open: bar.pane === "window" }
    MediaPane { id: mediaPane; anchorItem: mediaCell; open: bar.pane === "media" }
    CpuPane { id: cpuPane; anchorItem: cpuCell; open: bar.pane === "cpu" }
    MousePane { id: mousePane; anchorItem: mouseCell; open: bar.pane === "mouse" }
    ClockPane { id: clockPane; anchorItem: clockCell; open: bar.pane === "clock" }
    VolumePane { id: volumePane; anchorItem: volCell; open: bar.pane === "volume"; notify: bar.notify; ipc: bar.screen && bar.screen.name === Theme.mainMonitor }

    // The panes are their own windows. They must be in the grab, or a click inside a pane counts
    // as a click outside and closes it before the click lands.
    HyprlandFocusGrab {
        windows: [bar, usakiPane, workspacePane, windowPane, mediaPane, cpuPane, mousePane, clockPane, volumePane]
        active: bar.pane !== ""
        onCleared: bar.pane = ""
    }
}
