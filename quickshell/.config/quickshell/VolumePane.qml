import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

// Control pane: wifi, bluetooth and quiet tiles, then output volume and microphone level.
// Click a gauge to set the level.
PaneWindow {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    property var notify: null
    // Only the pane on the main monitor answers IPC, because a target name can have one handler.
    property bool ipc: true

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevice: adapter ? adapter.devices.values.find(d => d.connected) : null
    readonly property string btValue: !adapter ? "No adapter" : !adapter.enabled ? "Off" : btDevice ? (btDevice.name || btDevice.deviceName) : "On"

    // Read wifi state again each time the pane opens.
    onOpenChanged: if (open) Net.refresh()

    function toggleBluetooth() { if (adapter) adapter.enabled = !adapter.enabled; }
    function toggleQuiet() { if (notify) notify.quiet = !notify.quiet; }

    // `qs ipc call control bluetooth|quiet|wifi` flips a tile without a click.
    IpcHandler {
        target: "control"
        enabled: root.ipc
        function bluetooth(): void { root.toggleBluetooth(); }
        function quiet(): void { root.toggleQuiet(); }
        function wifi(): void { Net.toggle(); }
    }

    PwObjectTracker { objects: [root.sink, root.source].filter(o => o) }

    component LevelRow: Item {
        id: lr
        required property string name
        required property var node
        property color tone: Theme.emerald
        width: parent.width
        height: 18
        readonly property real level: node && node.audio ? node.audio.volume : 0
        readonly property bool muted: node && node.audio ? node.audio.muted : false

        Text {
            id: nm
            text: lr.name
            width: 64
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.amLabel
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pointSize: Theme.pt(9.5)
            font.letterSpacing: 1.33
            font.capitalization: Font.AllUppercase
        }
        Gauge {
            id: g
            x: 74
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 74 - 46
            height: 7
            value: lr.muted ? 0 : lr.level
            endColor: lr.tone
            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                onClicked: mouse => {
                    if (lr.node && lr.node.audio)
                        lr.node.audio.volume = Math.max(0, Math.min(1, (mouse.x + 5) / g.width));
                }
            }
        }
        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: lr.muted ? "mute" : Math.round(lr.level * 100)
            color: lr.muted ? Theme.faint : Theme.body
            font.family: Theme.mono
            font.pointSize: Theme.pt(11)
            MouseArea {
                anchors.fill: parent
                onClicked: if (lr.node && lr.node.audio) lr.node.audio.muted = !lr.node.audio.muted
            }
        }
    }

    Pane {
        paneWidth: 480
        heading: "☉ Control"
        rightText: root.sink ? (root.sink.nickname || root.sink.description || "") : "no output"
        Row {
            spacing: 8
            width: parent.width
            TglTile {
                width: (parent.width - 16) / 3
                label: "Wifi"
                value: Net.value
                on: Net.on
                readOnly: Net.readOnly
                accent: Theme.cerulean
                onToggled: Net.toggle()
            }
            TglTile {
                width: (parent.width - 16) / 3
                label: "Bluetooth"
                value: root.btValue
                on: root.adapter !== null && root.adapter.enabled
                readOnly: root.adapter === null
                accent: Theme.rhodolite
                onToggled: root.toggleBluetooth()
            }
            TglTile {
                width: (parent.width - 16) / 3
                label: "Quiet"
                value: root.notify && root.notify.quiet ? "On" : "Off"
                on: root.notify !== null && root.notify.quiet
                readOnly: root.notify === null
                accent: Theme.bronze
                onToggled: root.toggleQuiet()
            }
        }
        LevelRow { name: "Volume"; node: root.sink; tone: Theme.emerald }
        LevelRow { name: "Mic"; node: root.source; tone: Theme.cerulean }
    }
}
