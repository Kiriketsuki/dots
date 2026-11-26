pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Network state from nmcli, polled every 10 s, plus byte rates from /proc/net/dev every 2 s.
// With no wifi device the wifi tile falls back to the wired connection name and is read only.
Singleton {
    id: root
    property bool loaded: false
    property bool hasWifi: true
    property bool radioOn: false
    property string ssid: ""
    property string wired: ""
    // Signal strength of the active wifi row, 0 to 100.
    property int strength: 0
    readonly property int bars: ssid === "" ? 0 : strength <= 25 ? 1 : strength <= 50 ? 2 : strength <= 75 ? 3 : 4
    property real rxRate: 0
    property real txRate: 0
    property real prevRx: -1
    property real prevTx: -1

    readonly property bool readOnly: !hasWifi
    readonly property bool on: hasWifi ? radioOn : wired !== ""
    readonly property string value: !loaded ? "…" : hasWifi ? (radioOn ? (ssid !== "" ? ssid : "Searching") : "Off") : (wired !== "" ? wired : "No link")
    // What the bar cell shows.
    readonly property string kind: !loaded ? "..." : ssid !== "" ? "wifi" : wired !== "" ? "wired" : "offline"
    readonly property string name: !loaded ? "..." : ssid !== "" ? ssid : wired !== "" ? wired : "offline"

    function refresh() {
        if (!probe.running)
            probe.running = true;
    }

    function toggle() {
        if (!hasWifi)
            return;
        Quickshell.execDetached(["nmcli", "radio", "wifi", radioOn ? "off" : "on"]);
        settle.restart();
    }

    function fmt(bps) {
        if (bps >= 1e6)
            return (bps / 1e6).toFixed(1) + "M";
        if (bps >= 1e3)
            return Math.round(bps / 1e3) + "K";
        return Math.round(bps) + "B";
    }

    function parse(text) {
        const kv = {};
        text.split("\n").forEach(l => {
            const i = l.indexOf("=");
            if (i > 0)
                kv[l.slice(0, i)] = l.slice(i + 1).trim();
        });
        hasWifi = parseInt(kv.haswifi || "0") > 0;
        radioOn = kv.radio === "enabled";
        ssid = (kv.ssid || "").replace(/\\:/g, ":");
        wired = kv.wired || "";
        strength = parseInt(kv.sig || "0") || 0;
        loaded = true;
    }

    // Sums the physical links. Loopback, containers, bridges and tunnels are skipped.
    function parseRates(text) {
        let rx = 0, tx = 0;
        text.split("\n").slice(2).forEach(l => {
            const m = l.trim().match(/^([^:]+):\s*(.*)$/);
            if (!m || /^(lo|veth|br-|docker|tailscale|virbr)/.test(m[1]))
                return;
            const f = m[2].split(/\s+/).map(Number);
            rx += f[0];
            tx += f[8];
        });
        if (prevRx >= 0 && rx >= prevRx && tx >= prevTx) {
            rxRate = (rx - prevRx) / 2;
            txRate = (tx - prevTx) / 2;
        }
        prevRx = rx;
        prevTx = tx;
    }

    Process {
        id: probe
        command: ["sh", "-c", [
                "echo radio=$(nmcli -t -f WIFI g)",
                "echo haswifi=$(nmcli -t -f TYPE dev | grep -c '^wifi$')",
                "echo ssid=$(nmcli -t -f active,ssid dev wifi | sed -n 's/^yes://p' | head -1)",
                "echo sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi | sed -n 's/^\\*://p' | head -1)",
                "echo wired=$(nmcli -t -f NAME,TYPE con show --active | grep ':802-3-ethernet$' | head -1 | cut -d: -f1)"
            ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    FileView {
        id: dev
        path: "/proc/net/dev"
        onLoaded: root.parseRates(dev.text())
    }

    // The radio takes a moment to change, so read again after a short wait.
    Timer { id: settle; interval: 1800; onTriggered: root.refresh() }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: dev.reload()
    }
}
