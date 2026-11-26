import QtQuick
import QtQuick.Layouts
import Quickshell

// Clock pane: a month calendar with today in teal and the ISO week numbers, and the times in
// Singapore and the UK. Both zones come from UTC, so the pane does not depend on the machine zone.
PaneWindow {
    id: root
    readonly property color tone: Theme.sky

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // The month on show. It resets to this month each time the pane opens.
    property int viewYear: clock.date.getFullYear()
    property int viewMonth: clock.date.getMonth()
    onOpenChanged: if (open) {
        viewYear = clock.date.getFullYear();
        viewMonth = clock.date.getMonth();
    }

    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var days: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    function shift(n) {
        const d = new Date(viewYear, viewMonth + n, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    // ISO 8601 week number of a calendar date.
    function isoWeek(y, m, d) {
        const t = new Date(Date.UTC(y, m, d));
        const dow = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - dow);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    // The last Sunday of a month, as a UTC day number.
    function lastSunday(y, m) {
        const last = new Date(Date.UTC(y, m + 1, 0));
        return last.getUTCDate() - last.getUTCDay();
    }

    // UK offset in hours: BST from 01:00 UTC on the last Sunday of March to the same in October.
    function ukOffset(ms) {
        const y = new Date(ms).getUTCFullYear();
        const start = Date.UTC(y, 2, lastSunday(y, 2), 1);
        const end = Date.UTC(y, 9, lastSunday(y, 9), 1);
        return ms >= start && ms < end ? 1 : 0;
    }

    function zoneText(ms, off) {
        const d = new Date(ms + off * 3600000);
        const p = n => (n < 10 ? "0" : "") + n;
        return p(d.getUTCHours()) + ":" + p(d.getUTCMinutes());
    }
    function zoneDay(ms, off) {
        const d = new Date(ms + off * 3600000);
        return root.days[(d.getUTCDay() + 6) % 7] + " " + d.getUTCDate() + " " + root.months[d.getUTCMonth()].slice(0, 3);
    }

    readonly property real nowMs: clock.date.getTime()
    readonly property int ukOff: ukOffset(nowMs)
    // Monday-first index of the first day of the month, and the number of days.
    readonly property int lead: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property int dim: new Date(viewYear, viewMonth + 1, 0).getDate()
    readonly property int weeks: Math.ceil((lead + dim) / 7)

    component Zone: Column {
        property string name: ""
        property string time: ""
        property string day: ""
        property color accent: Theme.tealLt
        width: (parent.width - 12) / 2
        spacing: 1
        Text { text: parent.name; color: Theme.amLabel; font.family: Theme.mono; font.weight: Font.DemiBold; font.pointSize: Theme.pt(8.5); font.letterSpacing: 1.19; font.capitalization: Font.AllUppercase }
        Text { text: parent.time; color: parent.accent; font.family: Theme.mono; font.weight: Font.Medium; font.pointSize: Theme.pt(20) }
        Text { text: parent.day; color: Theme.muted; font.family: Theme.ui; font.pointSize: Theme.pt(11.5) }
    }

    Pane {
        paneWidth: 340
        tone: root.tone
        heading: "◷ Calendar"
        rightText: root.months[root.viewMonth] + " " + root.viewYear

        Row {
            width: parent.width
            spacing: 12
            Zone { name: "Singapore"; time: root.zoneText(root.nowMs, 8); day: root.zoneDay(root.nowMs, 8) + " · UTC+8" }
            Zone { name: "United Kingdom"; time: root.zoneText(root.nowMs, root.ukOff); day: root.zoneDay(root.nowMs, root.ukOff) + (root.ukOff ? " · BST" : " · GMT"); accent: Theme.sky }
        }

        Item {
            width: parent.width
            height: 26
            PaneBtn { text: "‹"; tone: root.tone; implicitWidth: 30; onClicked: root.shift(-1) }
            PaneBtn { anchors.right: parent.right; text: "›"; tone: root.tone; implicitWidth: 30; onClicked: root.shift(1) }
            PaneBtn {
                anchors.centerIn: parent
                text: "Today"
                tone: root.tone
                onClicked: { root.viewYear = clock.date.getFullYear(); root.viewMonth = clock.date.getMonth(); }
            }
        }

        // Header row: a week column, then Monday to Sunday.
        Grid {
            id: grid
            columns: 8
            width: parent.width
            readonly property real cw: width / 8
            Text { width: grid.cw; height: 20; horizontalAlignment: Text.AlignHCenter; text: "Wk"; color: Theme.faint; font.family: Theme.mono; font.pointSize: Theme.pt(8.5) }
            Repeater {
                model: root.days
                Text {
                    required property string modelData
                    required property int index
                    width: grid.cw
                    height: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: index >= 5 ? Theme.rhodolite : Theme.amLabel
                    font.family: Theme.mono
                    font.weight: Font.DemiBold
                    font.pointSize: Theme.pt(8.5)
                }
            }
            Repeater {
                model: root.weeks * 8
                Item {
                    id: cell
                    required property int index
                    readonly property int col: index % 8
                    readonly property int wk: Math.floor(index / 8)
                    readonly property int dayNum: wk * 7 + (col - 1) - root.lead + 1
                    readonly property bool inMonth: col > 0 && dayNum >= 1 && dayNum <= root.dim
                    readonly property bool today: inMonth && root.viewYear === clock.date.getFullYear() && root.viewMonth === clock.date.getMonth() && dayNum === clock.date.getDate()
                    width: grid.cw
                    height: 30
                    Rectangle {
                        visible: cell.today
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: Theme.tealFill
                        border.width: 1
                        border.color: Theme.teal
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.col === 0 ? root.isoWeek(root.viewYear, root.viewMonth, Math.max(1, Math.min(root.dim, cell.wk * 7 - root.lead + 1))) : cell.inMonth ? cell.dayNum : ""
                        color: cell.col === 0 ? Theme.faint : cell.today ? Theme.tealLt : cell.col >= 6 ? Theme.rhodolite : Theme.body
                        font.family: Theme.mono
                        font.weight: cell.today ? Font.Bold : Font.Medium
                        font.pointSize: Theme.pt(cell.col === 0 ? 9 : 11)
                    }
                }
            }
        }
    }
}
