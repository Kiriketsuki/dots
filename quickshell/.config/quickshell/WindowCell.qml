import QtQuick
import QtQuick.Layouts

Cell {
    id: root
    required property var screenRef
    WindowInfo { id: info; screenRef: root.screenRef }

    // A fixed width, so the music cell after it stays in place when the title changes.
    Layout.minimumWidth: 380
    Layout.maximumWidth: 380
    Layout.preferredWidth: 380
    // Reverse-DNS app ids such as com.mitchellh.ghostty show only their last part.
    label: info.cls !== "" ? "Window · " + info.cls.split(".").pop() : "Window"
    labelColor: Theme.cerulean
    Val {
        ui: true
        // A long title elides inside the cell.
        width: 358
        text: info.title
    }
}
