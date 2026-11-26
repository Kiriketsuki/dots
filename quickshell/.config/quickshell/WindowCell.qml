import QtQuick
import QtQuick.Layouts

Cell {
    id: root
    required property var screenRef
    WindowInfo { id: info; screenRef: root.screenRef }

    // The title keeps its own width up to 480 px, so free space opens up after it.
    Layout.minimumWidth: 160
    Layout.maximumWidth: 480
    Layout.preferredWidth: implicitWidth
    // Reverse-DNS app ids such as com.mitchellh.ghostty show only their last part.
    label: info.cls !== "" ? "Window · " + info.cls.split(".").pop() : "Window"
    labelColor: Theme.cerulean
    Val {
        ui: true
        // Natural width, capped so a long title elides inside the 480 px cell.
        width: Math.min(implicitWidth, 458)
        text: info.title
    }
}
