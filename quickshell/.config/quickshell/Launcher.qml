import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// Launcher in the pane style. It replaces rofi. Tab and Shift+Tab switch modes.
// `qs ipc call launcher toggle apps` opens it. The IPC calls at the end also let a
// script set the query, read the rows and pick one with no keyboard.
Scope {
    id: root

    property bool shown: false
    property string mode: "apps"
    property string query: ""
    property int current: 0
    property var rows: []
    property var targetScreen: Quickshell.screens[0]
    // A power row waits for a second Enter. This holds the key of that row.
    property string confirmKey: ""
    // A dry run logs each command and runs none. QS_LAUNCHER_DRY=1 or IPC turns it on.
    property bool dryRun: Quickshell.env("QS_LAUNCHER_DRY") === "1"
    property string lastRun: ""
    // The last pointer position over a row, in window coordinates.
    property point lastHover: Qt.point(-1, -1)

    property var windowList: []
    property var clipList: []
    property var emojiList: []
    property var profileList: []

    readonly property var modes: ["apps", "windows", "calc", "clipboard", "emoji", "firefox", "power"]
    readonly property var modeInfo: ({
        apps: { label: "Apps", hint: "Search apps. Type a sum such as 12*4 to calculate.", tone: Theme.teal },
        windows: { label: "Windows", hint: "Search open windows", tone: Theme.cerulean },
        calc: { label: "Calc", hint: "Type a sum. Enter copies the result.", tone: Theme.peridot },
        clipboard: { label: "Clipboard", hint: "Search clipboard history. Enter copies.", tone: Theme.topaz },
        emoji: { label: "Emoji", hint: "Search emoji. Enter copies.", tone: Theme.gold },
        firefox: { label: "Firefox", hint: "Pick a Firefox profile", tone: Theme.rhodolite },
        power: { label: "Power", hint: "Lock, suspend, log out, reboot or shut down", tone: Theme.amLt }
    })
    readonly property color tone: modeInfo[mode].tone
    readonly property string scripts: String(Qt.resolvedUrl("scripts")).replace("file://", "")

    // Mode and query

    function open(m) {
        const mon = Hyprland.focusedMonitor;
        targetScreen = Quickshell.screens.find(s => mon && s.name === mon.name) || Quickshell.screens[0];
        mode = modes.indexOf(m) >= 0 ? m : "apps";
        query = "";
        confirmKey = "";
        lastHover = Qt.point(-1, -1);
        refreshSource();
        rebuild();
        shown = true;
    }

    function close() {
        shown = false;
        confirmKey = "";
    }

    function toggle(m) {
        if (shown && (m === "" || m === mode))
            close();
        else
            open(m || "apps");
    }

    function setMode(m) {
        mode = m;
        confirmKey = "";
        refreshSource();
        rebuild();
    }

    function cycle(step) {
        const i = modes.indexOf(mode);
        setMode(modes[(i + step + modes.length) % modes.length]);
    }

    function setQuery(text) {
        query = text;
        confirmKey = "";
        rebuild();
    }

    function move(step) {
        if (rows.length === 0)
            return;
        current = Math.max(0, Math.min(rows.length - 1, current + step));
        confirmKey = "";
    }

    function refreshSource() {
        if (mode === "windows")
            clientsProc.running = true;
        else if (mode === "clipboard")
            clipProc.running = true;
        else if (mode === "firefox")
            profilesProc.running = true;
    }

    // Search

    // A plain substring scores highest, a prefix more so. Letters in order with gaps
    // score lower. -1 means no match.
    function score(hay, q) {
        if (q === "")
            return 1;
        const h = hay.toLowerCase();
        const at = h.indexOf(q);
        if (at === 0)
            return 3000 - h.length;
        if (at > 0)
            return 2000 - at * 4 - h.length;
        let pos = -1;
        let gaps = 0;
        for (let i = 0; i < q.length; i++) {
            const next = h.indexOf(q[i], pos + 1);
            if (next < 0)
                return -1;
            if (pos >= 0)
                gaps += next - pos - 1;
            pos = next;
        }
        return 1000 - gaps * 3 - h.length;
    }

    function ranked(items, textOf, limit) {
        const q = query.trim().toLowerCase();
        const out = [];
        for (const it of items) {
            const s = score(textOf(it), q);
            if (s >= 0)
                out.push({ it: it, s: s });
        }
        if (q !== "")
            out.sort((a, b) => b.s - a.s);
        return out.slice(0, limit).map(o => o.it);
    }

    // Returns the result as text, or null when the text is not a sum. Only digits,
    // operators, brackets and spaces pass, so the evaluated text cannot call anything.
    function calc(text, needOperator) {
        const expr = text.trim().replace(/^=/, "").replace(/,/g, "");
        if (!/^[0-9+\-*/().%^\s]+$/.test(expr) || !/[0-9]/.test(expr))
            return null;
        if (needOperator && !/[0-9)]\s*[+\-*/%^]\s*[0-9(]/.test(expr))
            return null;
        try {
            // JS reads ^ as XOR. The calculator reads it as a power.
            const v = Function('"use strict"; return (' + expr.replace(/\^/g, "**") + ");")();
            return typeof v === "number" && isFinite(v) ? String(Number(v.toPrecision(12))) : null;
        } catch (e) {
            return null;
        }
    }

    function apps() {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        return all.sort((a, b) => a.name.localeCompare(b.name));
    }

    function rebuild() {
        const r = [];
        if (mode === "apps") {
            const v = calc(query, true);
            if (v !== null)
                r.push({ title: "= " + v, sub: "Enter copies the result", glyph: "=", act: () => copy(v) });
            for (const e of ranked(apps(), e => [e.name, e.genericName, e.keywords.join(" ")].join(" "), 60))
                r.push({ title: e.name, sub: e.genericName || e.comment || "", icon: e.icon, act: () => launch(e) });
        } else if (mode === "calc") {
            const v = calc(query, false);
            r.push(v !== null
                ? { title: "= " + v, sub: "Enter copies the result", glyph: "=", act: () => copy(v) }
                : { title: query === "" ? "Type a sum" : "Not a sum", sub: "Numbers, + - * / % ^ and brackets", glyph: "=", act: () => {} });
        } else if (mode === "windows") {
            for (const c of ranked(windowList, c => c.title + " " + c.cls, 60)) {
                const entry = DesktopEntries.heuristicLookup(c.cls);
                r.push({ title: c.title || c.cls, sub: c.cls + "  ·  workspace " + c.ws, icon: entry ? entry.icon : "", act: () => focusWindow(c.address) });
            }
        } else if (mode === "clipboard") {
            for (const c of ranked(clipList, c => c.text, 100))
                r.push({ title: c.text, sub: "#" + c.id, glyph: "#", act: () => copyClip(c.line) });
        } else if (mode === "emoji") {
            for (const e of ranked(emojiList, e => e.name, 80))
                r.push({ title: e.name, sub: "", glyph: e.char, glyphFont: "Noto Color Emoji", act: () => copy(e.char) });
        } else if (mode === "firefox") {
            for (const p of ranked(profileList, p => p, 40))
                r.push({ title: p, sub: "Firefox profile", glyph: "◆", act: () => run([scripts + "/firefox_profiles.sh", "--open", p]) });
        } else if (mode === "power") {
            const items = [
                { key: "lock", title: "Lock", sub: "Lock the screen", glyph: "◇", confirm: false },
                { key: "suspend", title: "Suspend", sub: "Pause music, mute, then suspend", glyph: "◐", confirm: true },
                { key: "logout", title: "Log out", sub: "End the Hyprland session", glyph: "⇥", confirm: true },
                { key: "hibernate", title: "Hibernate", sub: "Save to disk and power off", glyph: "◒", confirm: true },
                { key: "reboot", title: "Reboot", sub: "Restart the computer", glyph: "↻", confirm: true },
                { key: "shutdown", title: "Shut down", sub: "Power off the computer", glyph: "⏻", confirm: true }
            ];
            for (const p of ranked(items, p => p.title, 10))
                r.push({ key: p.key, title: p.title, sub: p.sub, glyph: p.glyph, confirm: p.confirm, act: () => run([scripts + "/power.sh", p.key]) });
        }
        rows = r;
        current = 0;
    }

    // Actions

    function pick(i) {
        const row = rows[i];
        if (!row)
            return;
        current = i;
        if (row.confirm && confirmKey !== row.key) {
            confirmKey = row.key;
            return;
        }
        row.act();
        close();
    }

    function run(cmd) {
        lastRun = JSON.stringify(cmd);
        if (dryRun) {
            console.log("launcher dry run: " + lastRun);
            return;
        }
        Quickshell.execDetached(cmd);
    }

    function launch(entry) {
        if (entry.runInTerminal) {
            run(["ghostty", "-e"].concat(entry.command));
            return;
        }
        lastRun = "app " + entry.id;
        if (dryRun) {
            console.log("launcher dry run: " + lastRun);
            return;
        }
        entry.execute();
    }

    function copy(text) {
        run(["wl-copy", "--", text]);
    }

    function copyClip(line) {
        // The line goes in as an argument, so no part of it reaches the shell as code.
        run(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", line]);
    }

    function focusWindow(address) {
        run(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + address + "\" })"]);
    }

    // Sources

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(text)
                        .filter(c => c.mapped && c.workspace.id > 0)
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                        .map(c => ({ title: c.title, cls: c["class"], ws: c.workspace.name, address: c.address }));
                } catch (e) {
                    console.warn("launcher: hyprctl clients gave bad JSON: " + e);
                    root.windowList = [];
                }
                if (root.mode === "windows")
                    root.rebuild();
            }
        }
    }

    Process {
        id: clipProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clipList = text.split("\n").filter(l => l !== "").slice(0, 300).map(l => {
                    const tab = l.indexOf("\t");
                    return { id: l.slice(0, tab), text: l.slice(tab + 1), line: l };
                });
                if (root.mode === "clipboard")
                    root.rebuild();
            }
        }
    }

    Process {
        id: profilesProc
        command: [root.scripts + "/firefox_profiles.sh", "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.profileList = text.split("\n").filter(l => l !== "").map(l => l.split("\t")[0]);
                if (root.mode === "firefox")
                    root.rebuild();
            }
        }
    }

    FileView {
        id: emojiFile
        path: String(Qt.resolvedUrl("data/emoji.tsv")).replace("file://", "")
        onLoaded: {
            root.emojiList = emojiFile.text().split("\n").filter(l => l !== "").map(l => {
                const tab = l.indexOf("\t");
                return { char: l.slice(0, tab), name: l.slice(tab + 1) };
            });
        }
    }

    // Window

    PanelWindow {
        id: win
        visible: root.shown
        screen: root.targetScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) input.forceActiveFocus()

        // A click outside the box closes the launcher.
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(5 / 255, 8 / 255, 18 / 255, 0.28)
        }
        // A click on the box itself must not reach the close area below it.
        MouseArea {
            anchors.fill: box
        }

        Pane {
            id: box
            paneWidth: 660
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.16)
            heading: root.modeInfo[root.mode].label
            rightText: (root.dryRun ? "dry run  ·  " : "") + root.rows.length + (root.rows.length === 1 ? " result" : " results")
            tone: root.tone

            Row {
                spacing: 6
                Repeater {
                    model: root.modes
                    PaneBtn {
                        required property string modelData
                        text: root.modeInfo[modelData].label
                        tone: root.modeInfo[modelData].tone
                        active: root.mode === modelData
                        onClicked: {
                            root.setMode(modelData);
                            input.forceActiveFocus();
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                color: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.04)
                border.width: 1
                border.color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.5)

                Text {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: input.text === ""
                    text: root.modeInfo[root.mode].hint
                    color: Theme.faint
                    font.family: Theme.ui
                    font.pointSize: Theme.pt(15)
                }

                TextInput {
                    id: input
                    anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    selectionColor: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.4)
                    font.family: Theme.ui
                    font.pointSize: Theme.pt(15)
                    clip: true
                    onTextEdited: root.setQuery(text)

                    Keys.onPressed: event => {
                        const k = event.key;
                        if (k === Qt.Key_Escape) {
                            if (root.confirmKey !== "")
                                root.confirmKey = "";
                            else
                                root.close();
                        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                            root.pick(root.current);
                        } else if (k === Qt.Key_Down || (k === Qt.Key_N && event.modifiers & Qt.ControlModifier)) {
                            root.move(1);
                        } else if (k === Qt.Key_Up || (k === Qt.Key_P && event.modifiers & Qt.ControlModifier)) {
                            root.move(-1);
                        } else if (k === Qt.Key_PageDown) {
                            root.move(8);
                        } else if (k === Qt.Key_PageUp) {
                            root.move(-8);
                        } else if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
                            root.cycle(-1);
                        } else if (k === Qt.Key_Tab) {
                            root.cycle(1);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
            }

            ListView {
                id: list
                width: parent.width
                height: 40 * 9
                clip: true
                spacing: 2
                model: root.rows
                currentIndex: root.current
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: LauncherRow {
                    width: list.width
                    selected: index === root.current
                    confirming: root.confirmKey !== "" && modelData.key === root.confirmKey
                    tone: root.tone
                    onHovered: (i, pos) => {
                        if (pos.x === root.lastHover.x && pos.y === root.lastHover.y)
                            return;
                        const first = root.lastHover.x < 0;
                        root.lastHover = pos;
                        // The first event after open only records where the pointer is.
                        if (!first)
                            root.current = i;
                    }
                    onPicked: i => root.pick(i)
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.rows.length === 0
                    text: "No match"
                    color: Theme.faint
                    font.family: Theme.mono
                    font.pointSize: Theme.pt(11)
                }
            }
        }
    }

    Connections {
        target: root
        function onQueryChanged() {
            if (input.text !== root.query)
                input.text = root.query;
        }
    }

    IpcHandler {
        target: "launcher"
        function open(mode: string): void { root.open(mode); }
        function close(): void { root.close(); }
        function toggle(mode: string): void { root.toggle(mode); }
        function setQuery(text: string): void { root.setQuery(text); }
        function pick(index: int): void { root.pick(index); }
        function setDry(on: bool): void { root.dryRun = on; }
        // A hot reload turns dry run off. A test checks this before any pick.
        function isDry(): bool { return root.dryRun; }
        function lastRun(): string { return root.lastRun; }
        function rows(): string {
            return root.rows.slice(0, 12).map((r, i) => (i === root.current ? "> " : "  ") + r.title + (r.sub ? "  |  " + r.sub : "")).join("\n");
        }
    }
}
