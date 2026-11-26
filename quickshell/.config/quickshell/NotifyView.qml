import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Toast stack and list pane. They draw from `notify`, which is the Notify service.
Scope {
    id: root
    required property var notify
    property var screenRef: null

    component Card: Pane {
        id: card
        required property var rec
        signal dismissed
        signal opened
        paneWidth: 360
        need: rec.urgent
        heading: "✶ " + rec.app
        rightText: rec.time
        // The freedesktop "default" action belongs to a click on the card text, not to a
        // button. Senders often give it the same label as a real button, which drew the
        // label twice.
        readonly property var defaultAction: card.rec.actions.find(a => a.identifier === "default") || null
        readonly property var buttons: card.rec.actions.filter(a => a.identifier !== "default")
        function invokeDefault() {
            if (card.defaultAction) {
                card.defaultAction.invoke();
                card.dismissed();
            }
        }
        Text {
            width: parent.width
            text: card.rec.summary
            color: Theme.text
            wrapMode: Text.Wrap
            font.family: Theme.ui
            font.pointSize: Theme.pt(14)
            font.weight: Font.DemiBold
            MouseArea { anchors.fill: parent; enabled: card.defaultAction !== null; cursorShape: Qt.PointingHandCursor; onClicked: card.invokeDefault() }
        }
        Text {
            visible: card.rec.body !== ""
            width: parent.width
            text: card.rec.body
            color: Theme.body
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            font.family: Theme.ui
            font.pointSize: Theme.pt(13)
            MouseArea { anchors.fill: parent; enabled: card.defaultAction !== null; cursorShape: Qt.PointingHandCursor; onClicked: card.invokeDefault() }
        }
        Row {
            spacing: 8
            Repeater {
                model: card.buttons
                Rectangle {
                    required property var modelData
                    width: lbl.implicitWidth + 24
                    height: 26
                    color: "#181e40"
                    border.width: 1
                    border.color: Theme.amMid
                    Text { id: lbl; anchors.centerIn: parent; text: modelData.text; color: Theme.text; font.family: Theme.mono; font.weight: Font.DemiBold; font.pointSize: Theme.pt(10.5); font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
                    MouseArea { anchors.fill: parent; onClicked: { modelData.invoke(); card.dismissed(); } }
                }
            }
            Rectangle {
                width: dl.implicitWidth + 24
                height: 26
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.2)
                Text { id: dl; anchors.centerIn: parent; text: "Dismiss"; color: Theme.muted; font.family: Theme.mono; font.weight: Font.DemiBold; font.pointSize: Theme.pt(10.5); font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
                MouseArea { anchors.fill: parent; onClicked: card.dismissed() }
            }
        }
    }

    // Toasts, top right under the bar.
    PanelWindow {
        screen: root.screenRef
        // Toasts hide while the list is open, because both sit in the same corner.
        visible: root.notify.toasts.length > 0 && !root.notify.listOpen
        anchors { top: true; right: true }
        margins { top: Theme.mainHeight + 8; right: 8 }
        implicitWidth: 360
        implicitHeight: toastCol.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-toast"
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: toastCol
            spacing: 8
            width: parent.width
            Repeater {
                model: root.notify.toasts
                Card {
                    required property var modelData
                    rec: modelData
                    onDismissed: root.notify.dropToast(rec.id)
                    Timer {
                        interval: rec.urgent ? 12000 : 6000
                        running: true
                        onTriggered: root.notify.dropToast(rec.id)
                    }
                }
            }
        }
    }

    // List pane.
    PanelWindow {
        id: listWin
        screen: root.screenRef
        visible: root.notify.listOpen
        anchors { top: true; right: true }
        margins { top: Theme.mainHeight + 8; right: 8 }
        implicitWidth: 360
        implicitHeight: listCol.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-notify-list"
        WlrLayershell.layer: WlrLayer.Overlay

        HyprlandFocusGrab {
            windows: [listWin]
            active: root.notify.listOpen
            onCleared: root.notify.listOpen = false
        }

        Column {
            id: listCol
            spacing: 8
            width: parent.width
            Pane {
                paneWidth: 360
                heading: "✶ Notifications"
                rightText: root.notify.history.length
                Text {
                    visible: root.notify.history.length === 0
                    text: "Nothing new."
                    color: Theme.faint
                    font.family: Theme.ui
                    font.pointSize: Theme.pt(13)
                }
                Row {
                    visible: root.notify.history.length > 0
                    spacing: 8
                    Rectangle {
                        width: clr.implicitWidth + 24
                        height: 26
                        color: "#181e40"
                        border.width: 1
                        border.color: Theme.tealLt
                        Text { id: clr; anchors.centerIn: parent; text: "Clear all"; color: Theme.text; font.family: Theme.mono; font.weight: Font.DemiBold; font.pointSize: Theme.pt(10.5); font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.notify.clearAll(); root.notify.listOpen = false; } }
                    }
                    Text {
                        visible: root.notify.history.length > 5
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.notify.history.length - 5) + " older not shown"
                        color: Theme.faint
                        font.family: Theme.ui
                        font.pointSize: Theme.pt(12)
                    }
                }
            }
            // The five newest only, so the list never runs off the screen.
            Repeater {
                model: root.notify.history.slice(0, 5)
                Card {
                    required property var modelData
                    rec: modelData
                    onDismissed: root.notify.dropHistory(rec.id)
                }
            }
        }
    }
}
