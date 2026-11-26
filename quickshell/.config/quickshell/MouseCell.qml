import QtQuick

// Logitech MX Master 4: a mouse glyph and the battery percent. Hidden when no receiver or device exists.
// It uses the violet label colour, because the six gem colours already belong to other cells.
Cell {
    id: root
    readonly property bool low: Mouse.battery >= 0 && Mouse.battery <= Mouse.lowPercent && !Mouse.charging
    readonly property color tone: Mouse.presence === "error" ? Theme.err : root.low ? Theme.err : Theme.amLabel

    visible: Mouse.presence !== "absent"
    // No label: the mouse icon says what the cell is, so it stays narrow.
    label: ""
    padding: 8
    opacity: Mouse.presence === "offline" ? 0.55 : 1

    Row {
        spacing: 4
        height: 17
        BarIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "mouse"
            size: 16
            color: root.low ? Theme.err : Mouse.online ? Theme.amLt : Theme.faint
        }
        Val {
            anchors.verticalCenter: parent.verticalCenter
            text: Mouse.presence === "offline" ? "offline" : Mouse.presence === "error" ? "err" : Mouse.presence === "unknown" ? "…" : Mouse.battery >= 0 ? Mouse.battery + "%" + (Mouse.charging ? " ↑" : "") : "--%"
            color: root.low || Mouse.presence === "error" ? Theme.err : Mouse.online ? Theme.body : Theme.faint
        }
    }
}
