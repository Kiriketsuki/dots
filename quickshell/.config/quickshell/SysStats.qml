import QtQuick
import Quickshell
import Quickshell.Io

// System readings for the System pane: per-core use, memory, load, CPU temperature, uptime and the
// top five processes. One shell call reads it all. It only runs while `polling` is true, so a
// closed pane costs nothing.
Item {
    id: root
    property bool polling: false

    property var cores: []
    property real memUsed: 0
    property real memTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property string load: ""
    property real tempC: -1
    property real uptimeSec: 0
    property var procs: []

    property var prev: ({})

    function refresh() {
        if (!probe.running)
            probe.running = true;
    }

    function parse(text) {
        const sec = {};
        let cur = "cpu";
        text.split("\n").forEach(l => {
            if (l.startsWith("@")) {
                cur = l.slice(1).trim();
                sec[cur] = [];
            } else {
                (sec[cur] = sec[cur] || []).push(l);
            }
        });

        // Per-core use from the change in jiffies since the last sample.
        const next = {};
        const out = [];
        (sec.cpu || []).forEach(l => {
            const m = l.match(/^cpu(\d+)\s+(.*)$/);
            if (!m)
                return;
            const v = m[2].trim().split(/\s+/).map(Number);
            const total = v.slice(0, 8).reduce((a, b) => a + b, 0);
            const idle = v[3] + v[4];
            const p = prev[m[1]];
            next[m[1]] = { total: total, idle: idle };
            out.push(p && total > p.total ? 1 - (idle - p.idle) / (total - p.total) : 0);
        });
        prev = next;
        cores = out;

        const mem = {};
        (sec.mem || []).forEach(l => {
            const m = l.match(/^(\w+):\s+(\d+)/);
            if (m)
                mem[m[1]] = parseInt(m[2]) * 1024;
        });
        memTotal = mem.MemTotal || 0;
        memUsed = memTotal - (mem.MemAvailable || 0);
        swapTotal = mem.SwapTotal || 0;
        swapUsed = swapTotal - (mem.SwapFree || 0);

        const la = ((sec.load || [])[0] || "").trim().split(/\s+/);
        load = la.length >= 3 ? la.slice(0, 3).join("  ") : "";
        uptimeSec = parseFloat(((sec.up || [])[0] || "0").split(" ")[0]) || 0;
        const t = parseInt(((sec.temp || [])[0] || "").trim());
        tempC = isNaN(t) ? -1 : t / 1000;

        // The first ps line is the header row.
        procs = (sec.ps || []).slice(1).map(l => l.trim()).filter(l => l !== "").map(l => {
            const m = l.match(/^(\d+)\s+(.+?)\s+([\d.]+)\s+([\d.]+)$/);
            return m ? { pid: m[1], comm: m[2], cpu: parseFloat(m[3]), mem: parseFloat(m[4]) } : null;
        }).filter(x => x !== null);
    }

    Process {
        id: probe
        command: ["sh", "-c", [
                "grep '^cpu' /proc/stat",
                "echo @mem; grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo",
                "echo @load; cat /proc/loadavg",
                "echo @up; cat /proc/uptime",
                // The package temperature: k10temp (AMD), coretemp (Intel) or the x86_pkg_temp zone.
                "echo @temp; t=''; for h in /sys/class/hwmon/hwmon*; do case \"$(cat $h/name 2>/dev/null)\" in k10temp|coretemp) t=$(cat $h/temp1_input 2>/dev/null); break;; esac; done; if [ -z \"$t\" ]; then for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type 2>/dev/null)\" = x86_pkg_temp ] && t=$(cat $z/temp) && break; done; fi; echo $t",
                "echo @ps; ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6"
            ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 2000
        running: root.polling
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
