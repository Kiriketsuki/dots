import QtQuick

// Network cell: signal icon, connection name and the down and up rates stacked beside it.
Cell {
    id: root
    readonly property string shown: Net.name.length > 12 ? Net.name.slice(0, 11) + "…" : Net.name
    label: "Net · " + Net.kind
    labelColor: Theme.cerulean

    Row {
        spacing: 6
        height: 17
        SignalIcon {
            anchors.verticalCenter: parent.verticalCenter
            kind: Net.kind
            level: Net.bars
        }
        Val {
            anchors.verticalCenter: parent.verticalCenter
            text: root.shown
            color: Net.kind === "offline" ? Theme.err : Theme.body
        }
        Column {
            visible: Net.kind === "wifi" || Net.kind === "wired"
            anchors.verticalCenter: parent.verticalCenter
            Text { text: "↓" + Net.fmt(Net.rxRate); color: Theme.muted; font.family: Theme.mono; font.pointSize: Theme.pt(8); lineHeight: 0.95 }
            Text { text: "↑" + Net.fmt(Net.txRate); color: Theme.muted; font.family: Theme.mono; font.pointSize: Theme.pt(8); lineHeight: 0.95 }
        }
    }
}
