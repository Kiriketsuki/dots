import QtQuick

// Classic 4-bar signal icon. Bars up to `level` are solid and the rest are faint.
// kind "wired" shows a plug glyph instead.
Item {
    id: root
    property int level: 0
    property string kind: "wifi"
    property color tone: Theme.cerulean
    implicitWidth: kind === "wired" ? 12 : 11
    implicitHeight: 9

    Row {
        visible: root.kind !== "wired"
        spacing: 1
        anchors.bottom: parent.bottom
        Repeater {
            model: 4
            Rectangle {
                required property int index
                width: 2
                height: 3 + index * 2
                anchors.bottom: parent.bottom
                color: index < root.level ? root.tone : Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.25)
            }
        }
    }
    Text {
        visible: root.kind === "wired"
        anchors.centerIn: parent
        text: ""
        color: root.tone
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: Theme.pt(10)
    }
}
