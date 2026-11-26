import QtQuick
import QtQuick.Layouts

// The live agent sessions as a pane section. It is a Column, so a pane can drop it in as is.
// The heading has the live count and an "Open T3" button.
Column {
    id: root
    property color tone: Theme.peridot
    width: parent ? parent.width : 400
    spacing: 4

    function run(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
        return h >= 24 ? Math.floor(h / 24) + "d " + (h % 24) + "h" : h > 0 ? h + "h " + m + "m" : Math.max(1, m) + "m";
    }

    Item {
        width: parent.width
        height: 26
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "◎ Agents · " + Agents.count + " live"
            color: root.tone
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pointSize: Theme.pt(9.5)
            font.letterSpacing: 1.52
            font.capitalization: Font.AllUppercase
        }
        PaneBtn {
            anchors.right: parent.right
            implicitHeight: 24
            text: "Open T3"
            tone: root.tone
            onClicked: HyprCmd.focusT3()
        }
    }

    Text {
        visible: Agents.count === 0
        text: "No live agent sessions."
        color: Theme.faint
        font.family: Theme.ui
        font.pointSize: Theme.pt(12)
    }

    Repeater {
        model: Agents.sessions
        Item {
            required property var modelData
            width: root.width
            height: 26
            DashedLine { vertical: false; width: parent.width; height: 1 }
            Rectangle { x: 2; width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: root.tone }
            Text {
                x: 18
                width: parent.width - 18 - 190
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.project
                elide: Text.ElideRight
                color: Theme.body
                font.family: Theme.mono
                font.weight: Font.Medium
                font.pointSize: Theme.pt(11)
            }
            Text {
                x: parent.width - 180
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.model
                elide: Text.ElideRight
                color: Theme.muted
                font.family: Theme.mono
                font.pointSize: Theme.pt(10)
            }
            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: root.run(modelData.secs)
                color: Theme.tealLt
                font.family: Theme.mono
                font.pointSize: Theme.pt(10.5)
            }
        }
    }
}
