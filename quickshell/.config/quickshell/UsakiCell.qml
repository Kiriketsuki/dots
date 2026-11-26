import QtQuick

Cell {
    id: root
    readonly property var pool: Usaki.work
    readonly property bool have: pool !== null
    readonly property real five: have && pool.five !== null ? pool.five : 0
    readonly property real week: have && pool.week !== null ? pool.week : 0

    label: "Claude · <font color='" + Theme.tealLt + "'>" + Agents.count + " live</font>"
    icon: "orbit"
    labelColor: Theme.bronze
    opacity: have && pool.stale ? 0.55 : 1

    Row {
        spacing: 7
        height: 20
        // Spinning orbit ring: a ring with a planet dot on top.
        Item {
            width: 10
            height: 10
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: 5
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(111 / 255, 211 / 255, 214 / 255, 0.55)
                Rectangle { width: 3.4; height: 3.4; radius: 1.7; x: 3.3; y: -1.2; color: Theme.tealLt }
                RotationAnimator on rotation { from: 0; to: 360; duration: 2400; loops: Animation.Infinite; running: Agents.count > 0 }
            }
        }
        RabbitMark {
            anchors.verticalCenter: parent.verticalCenter
            leftFold: root.have && root.pool.leftEar
            rightFold: root.have && root.pool.rightEar
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Gauge { width: 70; height: 4; value: root.five; endColor: root.have && root.pool.five !== null ? (root.five >= 0.75 ? Theme.err : root.five >= 0.5 ? Theme.warn : Theme.tealLt) : Theme.tealLt }
            Gauge { width: 70; height: 5; value: root.week; endColor: root.week >= 0.75 ? Theme.err : root.week >= 0.5 ? Theme.warn : Theme.tealLt }
        }
        Val {
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: Theme.pt(11.5)
            text: root.have && root.pool.next !== "" ? "→ " + root.pool.next : ""
        }
    }
}
