import QtQuick
import Quickshell

// Popup window that hangs below a bar cell and grows to the size of its Pane.
PopupWindow {
    id: root
    required property Item anchorItem
    property bool open: false
    default property alias content: holder.data
    property real paneWidth: 0

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 5
    anchor.adjustment: PopupAdjustment.Slide
    visible: open
    color: "transparent"
    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height

    Item { id: holder; anchors.fill: parent }
}
