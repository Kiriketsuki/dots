pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU use from /proc/stat and RAM use from /proc/meminfo, both sampled every 2 s.
Singleton {
    id: root

    property real usage: 0
    property real ram: 0
    property real prevTotal: 0
    property real prevIdle: 0

    function parse(text) {
        const line = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const total = line.slice(0, 8).reduce((a, b) => a + b, 0);
        const idle = line[3] + line[4];
        if (prevTotal > 0 && total > prevTotal)
            usage = 1 - (idle - prevIdle) / (total - prevTotal);
        prevTotal = total;
        prevIdle = idle;
    }

    // RAM in use is (MemTotal - MemAvailable) / MemTotal.
    function parseMem(text) {
        const total = parseFloat((text.match(/^MemTotal:\s+(\d+)/m) || [0, 0])[1]);
        const avail = parseFloat((text.match(/^MemAvailable:\s+(\d+)/m) || [0, 0])[1]);
        if (total > 0)
            ram = (total - avail) / total;
    }

    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: root.parseMem(mem.text())
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.parse(stat.text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            mem.reload();
        }
    }
}
