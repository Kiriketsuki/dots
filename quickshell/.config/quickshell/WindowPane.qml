import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Window pane: details of the active window and buttons that act on it. The window is fixed when
// the pane opens, so a later focus change does not move the buttons to another window.
PaneWindow {
    id: root
    required property var screenRef
    readonly property color tone: Theme.cerulean

    WindowInfo { id: info; screenRef: root.screenRef }

    property var target: null
    property var ipc: null
    readonly property string addr: target && target.lastIpcObject && target.lastIpcObject.address ? target.lastIpcObject.address : ""
    readonly property string cls: ipc && ipc["class"] ? ipc["class"] : ""
    readonly property var size: ipc && ipc.size ? ipc.size : [0, 0]
    readonly property int wsId: ipc && ipc.workspace ? ipc.workspace.id : -1
    readonly property int base: {
        const list = Quickshell.screens.slice().sort((a, b) => a.x - b.x);
        const i = list.findIndex(s => s.name === screenRef.name);
        return (i < 0 ? 0 : i) * 10;
    }

    onOpenChanged: {
        if (open) {
            target = info.top;
            ipc = target ? target.lastIpcObject : null;
            Hyprland.refreshToplevels();
        }
    }

    function dispatch(expr) {
        if (addr === "")
            return;
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp." + expr.replace("%A", "address:" + addr)]);
        // Hyprland needs a moment before the new state shows.
        settle.restart();
    }

    Timer {
        id: settle
        interval: 350
        onTriggered: {
            Hyprland.refreshToplevels();
            fetch.restart();
        }
    }
    Timer {
        id: fetch
        interval: 250
        onTriggered: root.ipc = root.target ? root.target.lastIpcObject : null
    }

    Pane {
        paneWidth: 400
        tone: root.tone
        heading: "▣ Window"
        rightText: root.target ? "ws " + root.wsId : ""

        Text {
            visible: !root.target
            text: "No window on this monitor."
            color: Theme.faint
            font.family: Theme.ui
            font.pointSize: Theme.pt(12.5)
        }

        Column {
            visible: !!root.target
            width: parent.width
            spacing: 2
            Kv { key: "Class"; value: root.cls }
            Kv { key: "Title"; value: root.target ? root.target.title : ""; valueUi: true }
            Kv { key: "Workspace"; value: root.wsId >= 0 ? String(root.wsId) : "" }
            Kv { key: "Size"; value: root.size[0] + " × " + root.size[1] }
            Kv {
                key: "State"
                value: [root.ipc && root.ipc.floating ? "floating" : "tiled", root.ipc && root.ipc.pinned ? "pinned" : "", root.ipc && root.ipc.fullscreen > 0 ? "maximized" : ""].filter(s => s !== "").join(" · ")
            }
        }

        Flow {
            visible: !!root.target
            width: parent.width
            spacing: 6
            PaneBtn { text: "Float"; tone: root.tone; active: root.ipc && root.ipc.floating; onClicked: root.dispatch("window.float({action=\"toggle\", window=\"%A\"})") }
            PaneBtn { text: "Maximize"; tone: root.tone; active: root.ipc && root.ipc.fullscreen > 0; onClicked: root.dispatch("window.fullscreen({mode=\"maximized\", window=\"%A\"})") }
            PaneBtn { text: "Pin"; tone: root.tone; active: root.ipc && root.ipc.pinned; onClicked: root.dispatch("window.pin({action=\"toggle\", window=\"%A\"})") }
            PaneBtn { text: "Close"; tone: Theme.err; onClicked: root.dispatch("window.close({window=\"%A\"})") }
        }

        Text {
            visible: !!root.target
            text: "Move to workspace"
            color: Theme.amLabel
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pointSize: Theme.pt(8.5)
            font.letterSpacing: 1.36
            font.capitalization: Font.AllUppercase
        }
        Row {
            visible: !!root.target
            spacing: 5
            Repeater {
                model: 10
                Item {
                    id: ring
                    required property int index
                    readonly property int wsId: root.base + index + 1
                    readonly property bool here: wsId === root.wsId
                    width: 28
                    height: 28
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: 11
                        color: ring.here ? Theme.cerulean : rma.containsMouse ? Qt.rgba(90 / 255, 169 / 255, 236 / 255, 0.2) : "transparent"
                        border.width: 1
                        border.color: ring.here || rma.containsMouse ? Theme.cerulean : Theme.ringEmpty
                        Text {
                            anchors.centerIn: parent
                            text: ring.index + 1
                            color: ring.here ? "#0b1220" : Theme.body
                            font.family: Theme.mono
                            font.pointSize: Theme.pt(9)
                            font.weight: ring.here ? Font.Bold : Font.Medium
                        }
                    }
                    MouseArea {
                        id: rma
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !ring.here
                        onClicked: root.dispatch("window.move({workspace=" + ring.wsId + ", follow=false, window=\"%A\"})")
                    }
                }
            }
        }
    }
}
