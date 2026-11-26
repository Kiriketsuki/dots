import QtQuick
import QtQuick.Layouts

// The usaKi card: pool totals, next seat, one row per seat, and a dimmed line per stale pool.
PaneWindow {
    id: root

    readonly property var work: Usaki.work
    function pct(v) { return v === null || v === undefined ? "–" : Math.round(v * 100) + "%"; }
    function span(sec) {
        const h = sec / 3600;
        return h >= 24 ? Math.floor(h / 24) + "d " + Math.round(h % 24) + "h" : Math.max(0, Math.round(h)) + "h";
    }
    function ago(sec) { return sec < 120 ? Math.round(sec) + " s ago" : sec < 7200 ? Math.round(sec / 60) + " min ago" : Math.round(sec / 3600) + " h ago"; }
    function seatState(s, pool) {
        if (s.name === pool.next)
            return "next";
        return s.state.replace(/_/g, " ");
    }

    Pane {
        paneWidth: 640
        tone: Theme.bronze
        heading: "◎ Claude"
        rightText: root.work ? "work · " + root.ago(root.work.age) : "work · no data"

        // Live agent sessions come first, then the usaKi hub.
        AgentsList {}

        Text {
            text: "✶ usaKi · hub"
            color: Theme.bronze
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pointSize: Theme.pt(9.5)
            font.letterSpacing: 1.52
            font.capitalization: Font.AllUppercase
            topPadding: 4
        }

        Row {
            visible: root.work !== null
            spacing: 16
            opacity: root.work && root.work.stale ? 0.55 : 1
            Text { textFormat: Text.StyledText; color: Theme.muted; font.family: Theme.mono; font.weight: Font.Medium; font.pointSize: Theme.pt(11.5)
                text: root.work ? "5h <font color='" + Theme.text + "'>" + root.pct(root.work.five) + "</font>" : "" }
            Text { textFormat: Text.StyledText; color: Theme.muted; font.family: Theme.mono; font.weight: Font.Medium; font.pointSize: Theme.pt(11.5)
                text: root.work ? "7d <font color='" + Theme.tierColor(root.work.week) + "'>" + root.pct(root.work.week) + "</font>" : "" }
            Text { textFormat: Text.StyledText; color: Theme.muted; font.family: Theme.mono; font.weight: Font.Medium; font.pointSize: Theme.pt(11.5)
                text: root.work ? "open <font color='" + Theme.text + "'>" + root.work.open + " of " + root.work.seats.length + "</font>" : "" }
            Text { textFormat: Text.StyledText; color: Theme.muted; font.family: Theme.mono; font.weight: Font.Medium; font.pointSize: Theme.pt(11.5)
                text: root.work ? "next <font color='" + Theme.tealLt + "'>" + root.work.next + "</font>" : "" }
        }

        Column {
            width: parent.width
            opacity: root.work && root.work.stale ? 0.55 : 1
            Repeater {
                model: root.work ? root.work.seats : []
                Item {
                    id: row
                    required property var modelData
                    readonly property real wk: modelData.week === null ? 0 : modelData.week
                    width: parent.width
                    height: 30
                    DashedLine { vertical: false; width: parent.width; height: 1 }
                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        spacing: 10
                        HexIcon { tone: Theme.tierColor(modelData.week); fillAlpha: 0.15 + row.wk * 0.5; Layout.preferredWidth: 22 }
                        Val { text: modelData.name; Layout.preferredWidth: 92; font.pointSize: Theme.pt(11.5) }
                        Text {
                            Layout.preferredWidth: 74
                            text: root.seatState(modelData, root.work)
                            font.family: Theme.mono
                            font.weight: Font.DemiBold
                            font.pointSize: Theme.pt(8.5)
                            font.letterSpacing: 1.19
                            font.capitalization: Font.AllUppercase
                            color: text === "next" ? Theme.tealLt : text === "week full" ? Theme.err : Theme.muted
                        }
                        Gauge {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            value: row.wk
                            endColor: row.wk >= 0.75 ? Theme.err : row.wk >= 0.5 ? Theme.warn : Theme.tealLt
                        }
                        Val {
                            Layout.preferredWidth: 96
                            horizontalAlignment: Text.AlignRight
                            color: Theme.muted
                            font.pointSize: Theme.pt(11)
                            text: root.pct(modelData.week) + (modelData.weekReset !== null ? " · " + root.span(modelData.weekReset - Usaki.now) : "")
                        }
                    }
                }
            }
        }

        // Pools other than work, dimmed when stale.
        Repeater {
            model: Usaki.poolNames.filter(n => n !== "work" && Usaki.pools[n])
            Row {
                required property string modelData
                readonly property var p: Usaki.pools[modelData]
                spacing: 16
                opacity: p.stale ? 0.55 : 1
                Text {
                    color: Theme.muted
                    font.family: Theme.mono
                    font.weight: Font.Medium
                    font.pointSize: Theme.pt(11.5)
                    text: modelData + (p.stale ? " · stale " + root.span(p.age) : " · " + root.ago(p.age))
                }
                Repeater {
                    model: p.seats
                    Text {
                        required property var modelData
                        textFormat: Text.StyledText
                        color: Theme.muted
                        font.family: Theme.mono
                        font.weight: Font.Medium
                        font.pointSize: Theme.pt(11.5)
                        text: modelData.name + " 7d <font color='" + Theme.text + "'>" + root.pct(modelData.week) + "</font>"
                    }
                }
            }
        }
    }
}
