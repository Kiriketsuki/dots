import QtQuick
import Quickshell

// One launcher result: an app icon or a glyph, a title and a muted second line.
Rectangle {
    id: row
    required property var modelData
    required property int index
    property bool selected: false
    property bool confirming: false
    property color tone: Theme.teal
    signal picked(int index)
    signal hovered(int index, point windowPos)

    readonly property string iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""

    height: 40
    color: selected ? Qt.rgba(tone.r, tone.g, tone.b, 0.16) : ma.containsMouse ? Qt.rgba(tone.r, tone.g, tone.b, 0.07) : "transparent"
    border.width: selected ? 1 : 0
    border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.55)

    Item {
        id: lead
        width: 28
        height: 28
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        Image {
            anchors.fill: parent
            visible: row.iconSource !== ""
            source: row.iconSource
            sourceSize: Qt.size(56, 56)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Text {
            anchors.centerIn: parent
            visible: row.iconSource === ""
            text: row.modelData.glyph || "·"
            color: row.selected ? Theme.text : Theme.muted
            font.family: row.modelData.glyphFont || Theme.mono
            font.pointSize: Theme.pt(row.modelData.glyphFont ? 20 : 14)
        }
    }

    Column {
        anchors { left: lead.right; leftMargin: 12; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.modelData.title
            color: row.confirming ? Theme.gold : Theme.text
            font.family: Theme.ui
            font.pointSize: Theme.pt(14)
        }
        Text {
            width: parent.width
            visible: text !== ""
            elide: Text.ElideRight
            text: row.confirming ? "Press Enter again to confirm. Esc cancels." : (row.modelData.sub || "")
            color: row.confirming ? Theme.gold : Theme.faint
            font.family: Theme.mono
            font.pointSize: Theme.pt(10)
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        // Qt also sends hover events when the list changes under a still pointer.
        // The launcher compares window positions and ignores those.
        onPositionChanged: mouse => row.hovered(row.index, ma.mapToItem(null, mouse.x, mouse.y))
        onClicked: row.picked(row.index)
    }
}
