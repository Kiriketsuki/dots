import QtQuick

// A 1 px dashed line. QML has no dashed border, so this draws short rectangles.
Item {
    id: root
    property bool vertical: true
    property color color: Theme.rule
    property int dash: 3
    property int gap: 3
    readonly property real span: vertical ? height : width

    Repeater {
        model: Math.max(0, Math.ceil(root.span / (root.dash + root.gap)))
        Rectangle {
            required property int index
            color: root.color
            x: root.vertical ? 0 : index * (root.dash + root.gap)
            y: root.vertical ? index * (root.dash + root.gap) : 0
            width: root.vertical ? 1 : Math.min(root.dash, root.width - x)
            height: root.vertical ? Math.min(root.dash, root.height - y) : 1
        }
    }
}
