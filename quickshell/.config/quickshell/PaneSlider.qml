import QtQuick

// A draggable graduated gauge. It sends `committed` once, when the pointer is released.
Item {
    id: root
    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 0
    property color tone: Theme.tealLt
    // Value under the pointer while the user drags. -1 means no drag.
    property real draft: -1
    readonly property real shown: draft >= 0 ? draft : value
    readonly property real frac: to > from ? Math.max(0, Math.min(1, (shown - from) / (to - from))) : 0
    signal committed(real v)

    implicitHeight: 18
    opacity: enabled ? 1 : 0.4

    function snap(x) {
        const f = Math.max(0, Math.min(1, x / width));
        const raw = from + f * (to - from);
        return Math.max(from, Math.min(to, Math.round(raw / step) * step));
    }

    Gauge {
        id: g
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 7
        value: root.frac
        endColor: root.tone
    }
    Rectangle {
        x: Math.round(root.frac * (root.width - width))
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: 15
        color: Theme.text
        border.width: 1
        border.color: root.tone
    }
    MouseArea {
        anchors.fill: parent
        onPressed: mouse => root.draft = root.snap(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.draft = root.snap(mouse.x); }
        onReleased: {
            if (root.draft >= 0)
                root.committed(root.draft);
            root.draft = -1;
        }
        onCanceled: root.draft = -1
    }
}
