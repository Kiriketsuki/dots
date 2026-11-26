import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Workspace pane: the ten workspaces of one monitor. Each row has the ring, the number and the
// windows inside it as `class · title`. A click on a row focuses that workspace.
PaneWindow {
    id: root
    required property var screenRef
    readonly property color tone: Theme.tealLt

    readonly property var mon: Hyprland.monitorFor(screenRef)
    readonly property int activeId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : -1
    // The monitor at index i, sorted left to right by x, owns the ids 10*i+1 to 10*i+10.
    readonly property int base: {
        const list = Quickshell.screens.slice().sort((a, b) => a.x - b.x);
        const i = list.findIndex(s => s.name === screenRef.name);
        return (i < 0 ? 0 : i) * 10;
    }

    function shortClass(t) {
        const c = t.lastIpcObject && t.lastIpcObject["class"] ? t.lastIpcObject["class"] : "";
        return c.split(".").pop();
    }
    function kindFor(id) {
        if (id === activeId)
            return "on";
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (!ws)
            return "empty";
        if (ws.urgent)
            return "need";
        return ws.toplevels.values.length > 0 ? "occ" : "empty";
    }
    function windowsOf(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        return ws ? ws.toplevels.values : [];
    }

    Pane {
        paneWidth: 460
        tone: root.tone
        heading: "◉ Workspaces"
        rightText: root.screenRef ? root.screenRef.name : ""

        Column {
            width: parent.width
            Repeater {
                model: 10
                Item {
                    id: row
                    required property int index
                    readonly property int wsId: root.base + index + 1
                    readonly property var wins: root.windowsOf(wsId)
                    width: parent.width
                    height: Math.max(32, 12 + wins.length * 17)

                    DashedLine { vertical: false; width: parent.width; height: 1 }
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        color: row.wsId === root.activeId ? Theme.tealFill : ma.containsMouse ? Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.05) : "transparent"
                    }
                    OrbitRing {
                        x: 8
                        y: 8
                        wsId: row.wsId
                        kind: root.kindFor(row.wsId)
                    }
                    Text {
                        x: 36
                        y: 8
                        width: 22
                        text: row.wsId
                        color: row.wsId === root.activeId ? Theme.tealLt : Theme.amLabel
                        font.family: Theme.mono
                        font.weight: Font.DemiBold
                        font.pointSize: Theme.pt(11)
                    }
                    Text {
                        visible: row.wins.length === 0
                        x: 66
                        y: 9
                        text: "empty"
                        color: Theme.faint
                        font.family: Theme.ui
                        font.pointSize: Theme.pt(12)
                    }
                    Column {
                        x: 66
                        y: 7
                        width: parent.width - 66 - 8
                        spacing: 1
                        Repeater {
                            model: row.wins
                            Text {
                                required property var modelData
                                width: parent.width
                                height: 16
                                elide: Text.ElideRight
                                textFormat: Text.StyledText
                                color: Theme.body
                                font.family: Theme.ui
                                font.pointSize: Theme.pt(12)
                                text: "<font color='" + Theme.cerulean + "'>" + root.shortClass(modelData) + "</font> · " + (modelData.title || "").replace(/&/g, "&amp;").replace(/</g, "&lt;")
                            }
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: HyprCmd.focusWorkspace(row.wsId)
                    }
                }
            }
        }
    }
}
