import QtQuick
import Quickshell

Cell {
    id: root
    SystemClock { id: clock; precision: SystemClock.Minutes }
    label: Qt.formatDateTime(clock.date, "ddd d MMM")
    labelColor: Theme.sky
    Text {
        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: Theme.text
        font.family: Theme.mono
        font.weight: Font.Medium
        font.pointSize: Theme.pt(14)
        font.letterSpacing: 0.56
    }
}
