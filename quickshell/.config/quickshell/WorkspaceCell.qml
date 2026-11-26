import QtQuick

Cell {
    id: root
    required property var screenRef

    label: "Workspace · " + ws.activeId
    labelColor: Theme.tealLt
    OrbitWorkspaces {
        id: ws
        height: 19
        topPadding: 2
    }
}
