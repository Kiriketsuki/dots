import QtQuick

// Bottom edge: a violet to teal hairline with a ruler on it. A minor tick (2 px tall) sits
// every 12 px and a major tick (4 px tall) every 60 px, like the T3 composer ruler.
Item {
    id: root
    readonly property int minorStep: 12
    readonly property int majorEvery: 5

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.amMid }
            GradientStop { position: 1; color: Theme.teal }
        }
    }
    Repeater {
        model: Math.ceil(root.width / root.minorStep)
        Rectangle {
            required property int index
            readonly property bool major: index % root.majorEvery === 0
            x: index * root.minorStep
            width: 1
            height: major ? 4 : 2
            y: root.height - 1 - height
            opacity: 0.55
            color: Theme.lerp(Theme.amLt, Theme.tealLt, root.width > 0 ? x / root.width : 0)
        }
    }
}
