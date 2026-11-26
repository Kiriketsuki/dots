import QtQuick
import QtQuick.Layouts
import Quickshell

// System pane: a mini gauge for each core, memory, load, temperature, uptime and the top five
// processes. It refreshes every 2 s while it is open.
PaneWindow {
    id: root
    readonly property color tone: Theme.topaz

    SysStats { id: sys; polling: root.open }

    function gib(b) { return (b / 1073741824).toFixed(1); }
    function up(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return (d > 0 ? d + "d " : "") + h + "h " + m + "m";
    }
    function heat(f) { return f >= 0.85 ? Theme.err : f >= 0.6 ? Theme.warn : Theme.topaz; }

    Pane {
        paneWidth: 440
        tone: root.tone
        heading: "⚙ System"
        rightText: "CPU " + Math.round(Cpu.usage * 100) + "%"

        // Core grid: 8 columns.
        Grid {
            columns: 8
            columnSpacing: 8
            rowSpacing: 6
            width: parent.width
            Repeater {
                model: sys.cores
                Column {
                    required property int index
                    required property real modelData
                    width: (440 - 36 - 7 * 8) / 8
                    spacing: 2
                    Text {
                        text: index
                        color: Theme.faint
                        font.family: Theme.mono
                        font.pointSize: Theme.pt(8)
                    }
                    Gauge { width: parent.width; height: 5; value: modelData; endColor: root.heat(modelData) }
                }
            }
        }

        Kv { key: "Memory"; keyWidth: 64; value: sys.memTotal > 0 ? root.gib(sys.memUsed) + " / " + root.gib(sys.memTotal) + " GiB" : "–" }
        Gauge { width: parent.width; height: 6; value: sys.memTotal > 0 ? sys.memUsed / sys.memTotal : 0; endColor: root.heat(sys.memTotal > 0 ? sys.memUsed / sys.memTotal : 0) }
        Kv { key: "Swap"; keyWidth: 64; visible: sys.swapTotal > 0; value: root.gib(sys.swapUsed) + " / " + root.gib(sys.swapTotal) + " GiB" }
        Kv { key: "Load"; keyWidth: 64; value: sys.load }
        Kv { key: "Temp"; keyWidth: 64; visible: sys.tempC >= 0; value: sys.tempC.toFixed(0) + " °C"; valueColor: sys.tempC >= 85 ? Theme.err : sys.tempC >= 70 ? Theme.warn : Theme.body }
        Kv { key: "Uptime"; keyWidth: 64; value: root.up(sys.uptimeSec) }

        Text {
            text: "Top processes"
            color: Theme.amLabel
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pointSize: Theme.pt(8.5)
            font.letterSpacing: 1.36
            font.capitalization: Font.AllUppercase
        }
        Column {
            width: parent.width
            Repeater {
                model: sys.procs
                Item {
                    required property var modelData
                    width: parent.width
                    height: 22
                    DashedLine { vertical: false; width: parent.width; height: 1 }
                    Text {
                        x: 2
                        width: 52
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.pid
                        color: Theme.faint
                        font.family: Theme.mono
                        font.pointSize: Theme.pt(9.5)
                    }
                    Text {
                        x: 58
                        width: parent.width - 58 - 130
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.comm
                        elide: Text.ElideRight
                        color: Theme.body
                        font.family: Theme.mono
                        font.pointSize: Theme.pt(10.5)
                    }
                    Text {
                        width: 60
                        x: parent.width - 126
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.cpu.toFixed(1) + "%"
                        color: root.tone
                        font.family: Theme.mono
                        font.pointSize: Theme.pt(10.5)
                    }
                    Text {
                        width: 60
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        horizontalAlignment: Text.AlignRight
                        text: modelData.mem.toFixed(1) + "% mem"
                        color: Theme.muted
                        font.family: Theme.mono
                        font.pointSize: Theme.pt(9.5)
                    }
                }
            }
        }
    }
}
