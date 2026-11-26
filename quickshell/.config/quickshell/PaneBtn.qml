import QtQuick

// Small mono-caps button for panes, in the mock's .btn style: a hairline border, a tint on hover.
Rectangle {
    id: root
    property string text: ""
    property color tone: Theme.sky
    property bool active: false
    signal clicked

    implicitWidth: lbl.implicitWidth + 24
    implicitHeight: 26
    opacity: enabled ? 1 : 0.4
    color: active ? Qt.rgba(tone.r, tone.g, tone.b, 0.18) : ma.containsMouse && enabled ? Qt.rgba(tone.r, tone.g, tone.b, 0.1) : "transparent"
    border.width: 1
    border.color: active ? tone : ma.containsMouse && enabled ? Qt.rgba(tone.r, tone.g, tone.b, 0.6) : Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.22)

    Text {
        id: lbl
        anchors.centerIn: parent
        text: root.text
        color: root.active || ma.containsMouse ? Theme.text : Theme.muted
        font.family: Theme.mono
        font.weight: Font.DemiBold
        font.pointSize: Theme.pt(9)
        font.letterSpacing: 1.1
        font.capitalization: Font.AllUppercase
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
