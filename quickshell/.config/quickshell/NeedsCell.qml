import QtQuick

// Notifications: the count of notifications in the list. A click opens the list.
Cell {
    id: root
    property var notify: null
    readonly property int count: notify ? notify.history.length : 0

    label: "Notifications"
    labelColor: count > 0 ? Theme.gold : Theme.sky
    Val {
        text: root.count
        color: root.count > 0 ? Theme.gold : Theme.faint
    }
}
