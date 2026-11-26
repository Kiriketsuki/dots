import QtQuick

// Graduated gauge: ticks about every 6 px over a faint track, with a fill that brightens
// from a dark shade of endColor to endColor.
Item {
    id: root
    property real value: 0
    property color endColor: Theme.tealLt
    implicitWidth: 58
    implicitHeight: 5

    Rectangle { anchors.fill: parent; color: Theme.gaugeTrack }
    Repeater {
        model: Math.floor(root.width / 6) + 1
        Rectangle {
            required property int index
            x: index * 6
            width: 1
            height: root.height
            color: Theme.gaugeTick
        }
    }
    Rectangle {
        width: Math.round(root.width * Math.max(0, Math.min(1, root.value)))
        height: root.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.darker(root.endColor, 2.2) }
            GradientStop { position: 1; color: root.endColor }
        }
    }
}
