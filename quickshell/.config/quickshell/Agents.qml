pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live agent sessions: claude processes that are children of the `t3 serve` process.
// The T3 stats cache and the t3 CLI give no global working-thread count.
// `count` is the number of sessions. `sessions` holds one entry per process with its project
// folder, model and run time.
Singleton {
    id: root

    property int count: 0
    property var sessions: []

    function parse(text) {
        const list = text.split("\n").filter(l => l.trim() !== "").map(l => {
            const f = l.split("\t");
            const cwd = f[2] || "";
            // A T3 worktree path ends in project/branch, so show both parts.
            const parts = cwd.split("/").filter(s => s !== "");
            const wt = cwd.indexOf("/worktrees/") >= 0 && parts.length >= 2;
            const m = (f[3] || "").match(/--model[= ]\s*(\S+)/);
            return {
                pid: f[0],
                secs: parseInt(f[1]) || 0,
                cwd: cwd,
                project: parts.length ? (wt ? parts[parts.length - 2] + "/" + parts[parts.length - 1] : parts[parts.length - 1]) : "?",
                model: m ? m[1] : "default"
            };
        });
        sessions = list;
        count = list.length;
    }

    Process {
        id: probe
        command: ["sh", "-c", "p=$(pgrep -f '^/[^ ]*/t3 serve' | head -1); [ -n \"$p\" ] && for c in $(pgrep -P \"$p\" -f claude); do printf '%s\\t%s\\t%s\\t%s\\n' \"$c\" \"$(ps -o etimes= -p $c | tr -d ' ')\" \"$(readlink /proc/$c/cwd)\" \"$(tr '\\0' ' ' </proc/$c/cmdline)\"; done; true"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!probe.running)
                probe.running = true;
        }
    }
}
