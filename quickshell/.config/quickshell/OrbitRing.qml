import QtQuick

// One workspace as an orbit ring. kind is one of: empty, occ, vis, on, need.
// vis is the workspace that another monitor shows.
Item {
    id: root
    property int wsId: 1
    property string kind: "empty"
    width: 17
    height: 17

    readonly property color accent: kind === "on" || kind === "vis" ? Theme.tealLt : kind === "need" ? Theme.gold : Theme.cerulean

    // Soft halo for the active and urgent rings.
    Rectangle {
        visible: root.kind === "on" || root.kind === "need"
        anchors.fill: parent
        anchors.margins: -2
        radius: width / 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.kind === "on" ? Theme.tealLt : "transparent"
        border.width: 1
        border.color: root.kind === "empty" ? Theme.ringEmpty : root.kind === "occ" ? Theme.ringOcc : root.accent
    }
    Rectangle {
        visible: root.kind !== "empty"
        width: 4.4
        height: 4.4
        radius: 2.2
        x: (parent.width - width) / 2
        y: -1.2
        color: root.accent
    }
    Text {
        anchors.centerIn: parent
        text: root.wsId
        font.family: Theme.mono
        font.weight: root.kind === "on" ? Font.Bold : Font.Medium
        font.pointSize: Theme.pt(8.5)
        font.letterSpacing: -0.17
        color: root.kind === "on" ? "#0b1220" : root.kind === "need" ? Theme.gold : root.kind === "vis" ? Theme.tealLt : root.kind === "occ" ? Theme.cerulean : Theme.faint
    }
    MouseArea {
        anchors.fill: parent
        onClicked: HyprCmd.focusWorkspace(root.wsId)
    }
}
