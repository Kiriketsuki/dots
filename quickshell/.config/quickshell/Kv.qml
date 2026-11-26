import QtQuick

// One key and value line for a pane. The key is a small mono-caps label, the value sits right of it.
Item {
    id: root
    property string key: ""
    property string value: ""
    property color valueColor: Theme.body
    property real keyWidth: 78
    property bool valueUi: false

    width: parent ? parent.width : 200
    height: 20

    Text {
        id: k
        width: root.keyWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.key
        color: Theme.amLabel
        font.family: Theme.mono
        font.weight: Font.DemiBold
        font.pointSize: Theme.pt(8.5)
        font.letterSpacing: 1.19
        font.capitalization: Font.AllUppercase
        elide: Text.ElideRight
    }
    Text {
        anchors { left: k.right; right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.value
        color: root.valueColor
        elide: Text.ElideRight
        font.family: root.valueUi ? Theme.ui : Theme.mono
        font.pointSize: Theme.pt(root.valueUi ? 12 : 11)
    }
}
