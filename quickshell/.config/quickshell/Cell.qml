import QtQuick
import QtQuick.Layouts

// One bar cell: a tiny label over a value, split from its neighbour by a dashed line.
Item {
    id: root
    property string label: ""
    property color labelColor: Theme.amLabel
    // An iconsmith icon from icons/build. It sits left of the label and value, in labelColor.
    property string icon: ""
    property color iconColor: labelColor
    readonly property real iconSpace: icon !== "" ? 16 + 7 : 0
    property bool first: false
    property real padding: 11
    default property alias content: col.data
    signal clicked
    signal wheeled(real dy)

    Layout.fillHeight: true
    implicitWidth: col.implicitWidth + padding * 2 + iconSpace

    DashedLine {
        visible: !root.first
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 1
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked()
        onWheel: wheel => root.wheeled(wheel.angleDelta.y)
    }

    BarIcon {
        visible: root.icon !== ""
        name: root.icon !== "" ? root.icon : "bell"
        size: 16
        color: root.iconColor
        anchors { left: parent.left; leftMargin: root.padding; verticalCenter: parent.verticalCenter }
    }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; leftMargin: root.padding + root.iconSpace; rightMargin: root.padding; verticalCenter: parent.verticalCenter }
        Lbl {
            visible: root.label !== ""
            text: root.label
            color: root.labelColor
        }
    }
}
