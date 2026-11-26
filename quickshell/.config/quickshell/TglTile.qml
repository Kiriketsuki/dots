import QtQuick

// Toggle tile in the mock's .tg style: a dashed border when off, a solid accent border when on,
// and an orbit ring with a centre dot when on.
Item {
    id: root
    property string label: ""
    property string value: ""
    property bool on: false
    property bool readOnly: false
    property color accent: Theme.tealLt
    signal toggled

    implicitHeight: 42
    opacity: readOnly ? 0.6 : 1

    readonly property color offLine: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.2)

    // Solid border when on.
    Rectangle {
        anchors.fill: parent
        visible: root.on
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
    }
    // Dashed border when off.
    Item {
        anchors.fill: parent
        visible: !root.on
        DashedLine { vertical: false; color: root.offLine; width: parent.width; height: 1 }
        DashedLine { vertical: false; color: root.offLine; width: parent.width; height: 1; y: parent.height - 1 }
        DashedLine { vertical: true; color: root.offLine; width: 1; height: parent.height }
        DashedLine { vertical: true; color: root.offLine; width: 1; height: parent.height; x: parent.width - 1 }
    }

    // Orbit ring.
    Item {
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        Rectangle {
            visible: root.on
            anchors.fill: parent
            anchors.margins: -2
            radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.on ? root.accent : Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.3)
            Rectangle {
                visible: root.on
                anchors.centerIn: parent
                width: 4
                height: 4
                radius: 2
                color: root.accent
            }
        }
    }

    Column {
        anchors { left: parent.left; leftMargin: 30; right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
        Lbl { text: root.label; width: parent.width }
        Val { ui: true; text: root.value; width: parent.width; color: root.on ? Theme.text : Theme.muted }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.readOnly
        onClicked: root.toggled()
    }
}
