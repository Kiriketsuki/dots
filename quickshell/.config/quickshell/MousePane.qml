import QtQuick
import QtQuick.Layouts
import Quickshell

// Mouse pane: battery, DPI, SmartShift, ratchet mode, haptics and a button for the Solaar GUI.
// Controls stay locked while the mouse sleeps. The saved values show in that case.
PaneWindow {
    id: root
    readonly property color tone: Theme.amLt
    readonly property bool on: Mouse.online
    readonly property var dpiPresets: [800, 1200, 1600, 2400]

    onOpenChanged: if (open) Mouse.refreshIfStale()

    component Sec: Text {
        color: Theme.amLabel
        font.family: Theme.mono
        font.weight: Font.DemiBold
        font.pointSize: Theme.pt(8.5)
        font.letterSpacing: 1.36
        font.capitalization: Font.AllUppercase
    }
    component Err: Text {
        required property string key
        visible: !!Mouse.errors[key]
        text: "! " + (Mouse.errors[key] || "")
        color: Theme.err
        width: parent.width
        wrapMode: Text.Wrap
        font.family: Theme.mono
        font.pointSize: Theme.pt(9)
    }
    component NumRow: Item {
        id: nr
        property string name: ""
        property int val: -1
        property real from: 0
        property real to: 100
        property real step: 1
        property string key: ""
        property string unit: ""
        width: parent.width
        height: 20
        Text {
            id: nm
            width: 96
            anchors.verticalCenter: parent.verticalCenter
            text: nr.name
            color: Theme.amLabel
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pointSize: Theme.pt(8.5)
            font.letterSpacing: 1.19
            font.capitalization: Font.AllUppercase
        }
        PaneSlider {
            x: 104
            width: parent.width - 104 - 54
            anchors.verticalCenter: parent.verticalCenter
            from: nr.from
            to: nr.to
            step: nr.step
            value: nr.val < 0 ? nr.from : nr.val
            tone: root.tone
            enabled: root.on && nr.val >= 0
            onCommitted: v => {
                const p = {};
                p[nr.key === "dpi" ? "dpi" : nr.key === "smart-shift" ? "smartShift" : "haptic"] = Math.round(v);
                Mouse.apply(nr.key, Math.round(v), p);
            }
        }
        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: nr.val < 0 ? "–" : nr.val + nr.unit
            color: Theme.body
            font.family: Theme.mono
            font.pointSize: Theme.pt(11)
        }
    }

    Pane {
        paneWidth: 380
        tone: root.tone
        heading: "◈ Mouse"
        rightText: Mouse.device

        // Battery.
        Item {
            width: parent.width
            height: 20
            Text {
                width: 96
                anchors.verticalCenter: parent.verticalCenter
                text: "Battery"
                color: Theme.amLabel
                font.family: Theme.mono
                font.weight: Font.DemiBold
                font.pointSize: Theme.pt(8.5)
                font.letterSpacing: 1.19
                font.capitalization: Font.AllUppercase
            }
            Gauge {
                x: 104
                width: parent.width - 104 - 110
                height: 7
                anchors.verticalCenter: parent.verticalCenter
                value: Mouse.battery < 0 ? 0 : Mouse.battery / 100
                endColor: Mouse.battery >= 0 && Mouse.battery <= Mouse.lowPercent ? Theme.err : Theme.amLt
            }
            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: (Mouse.battery < 0 ? "–" : Mouse.battery + "%") + (Mouse.charging ? " charging" : "")
                color: Mouse.battery >= 0 && Mouse.battery <= Mouse.lowPercent ? Theme.err : Theme.body
                font.family: Theme.mono
                font.pointSize: Theme.pt(11)
            }
        }

        Text {
            visible: Mouse.presence !== "online"
            width: parent.width
            wrapMode: Text.Wrap
            color: Mouse.presence === "error" ? Theme.err : Theme.warn
            font.family: Theme.ui
            font.pointSize: Theme.pt(12)
            text: Mouse.presence === "offline" ? "The mouse is asleep. The pane shows saved values. Move the mouse to wake it." : Mouse.presence === "error" ? "Solaar failed. " + Mouse.detail : Mouse.presence === "absent" ? "No Logitech receiver or mouse was found." : "Reading the mouse."
        }

        Sec { text: "Pointer" }
        Row {
            spacing: 6
            Repeater {
                model: root.dpiPresets
                PaneBtn {
                    required property int modelData
                    text: modelData
                    tone: root.tone
                    active: Mouse.dpi === modelData
                    enabled: root.on
                    onClicked: Mouse.apply("dpi", modelData, { dpi: modelData })
                }
            }
        }
        NumRow { name: "DPI"; key: "dpi"; val: Mouse.dpi; from: 200; to: 8000; step: 50 }
        Err { key: "dpi" }

        Sec { text: "Wheel" }
        Row {
            spacing: 6
            Repeater {
                model: [{ v: "Ratcheted", t: "Ratchet" }, { v: "Freespinning", t: "Free spin" }]
                PaneBtn {
                    required property var modelData
                    text: modelData.t
                    tone: root.tone
                    active: Mouse.ratchet === modelData.v
                    enabled: root.on
                    onClicked: Mouse.apply("scroll-ratchet", modelData.v, { ratchet: modelData.v })
                }
            }
        }
        Err { key: "scroll-ratchet" }
        NumRow { name: "SmartShift"; key: "smart-shift"; val: Mouse.smartShift; from: 1; to: 50; step: 1 }
        Err { key: "smart-shift" }

        Sec { text: "Haptics" }
        NumRow { name: "Haptic level"; key: "haptic-level"; val: Mouse.haptic; from: 0; to: 100; step: 5 }
        Err { key: "haptic-level" }

        PaneBtn {
            text: "Open Solaar"
            tone: root.tone
            onClicked: Quickshell.execDetached(["env", "-u", "LD_PRELOAD", "solaar"])
        }
    }
}
