pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Logitech MX Master 4 through the Solaar CLI. Ported from the old AGS lib/solaar.ts and
// lib/mouse-store.ts.
//
// Solaar is the only source for the battery and settings. `solaar show` takes several seconds
// and wakes the radio, so the poll stays slow. One queue runs every Solaar command, because two
// CLI processes must not talk to the receiver at once. Every call is asynchronous.
Singleton {
    id: root

    readonly property string device: "MX Master 4"
    // The old code treated this percent and below as low.
    readonly property int lowPercent: 20

    // unknown, absent, offline, online or error
    property string presence: "unknown"
    // -1 means unknown for each number below.
    property int battery: -1
    property bool charging: false
    property int dpi: -1
    property string ratchet: ""
    property int smartShift: -1
    property int haptic: -1
    property string detail: ""
    // Last write error per setting key.
    property var errors: ({})

    property double lastMs: 0
    property var queue: []
    property var current: null
    property bool gotText: false
    property bool gotExit: false
    property string outText: ""

    readonly property bool online: presence === "online"

    // Messages that mean "no such device here", not "the CLI broke".
    readonly property var absentMarkers: ["no device found matching", "No supported device found", "Failed to execute child process"]

    // `solaar show` prints a NUL byte inside the firmware list. `tr` removes it. The wrapper
    // prints the exit code and the last error line after the output, because the Wayland warning
    // on stderr appears even when the call works.
    readonly property string tail: "rc=$?; echo \"@@RC=$rc\"; echo '@@ERR'; grep -iE '(error|exception)' \"$e\" | tail -1; rm -f \"$e\""
    readonly property string showScript: "e=$(mktemp); solaar show \"$1\" 2>\"$e\" | tr -d '\\000'; rc=${PIPESTATUS[0]}; echo \"@@RC=$rc\"; echo '@@ERR'; grep -iE '(error|exception)' \"$e\" | tail -1; rm -f \"$e\""
    readonly property string writeScript: "e=$(mktemp); solaar config \"$1\" \"$2\" \"$3\" >/dev/null 2>\"$e\"; " + tail

    function refresh() {
        if (queue.some(j => j.kind === "show") || (current && current.kind === "show"))
            return;
        enqueue({ kind: "show" });
    }

    function refreshIfStale() {
        if (Date.now() - lastMs > 10000)
            refresh();
    }

    // Writes one setting. `patch` holds the reading fields that the write changes. The reading
    // updates first and goes back if Solaar refuses the value.
    function apply(key, value, patch) {
        const prev = {};
        Object.keys(patch).forEach(k => { prev[k] = root[k]; });
        setFields(patch);
        const e = Object.assign({}, errors);
        delete e[key];
        errors = e;
        enqueue({ kind: "write", key: key, value: String(value), prev: prev });
    }

    function setFields(f) {
        Object.keys(f).forEach(k => { root[k] = f[k]; });
    }

    function enqueue(job) {
        queue = queue.concat([job]);
        next();
    }

    function next() {
        if (runner.running || current !== null || queue.length === 0)
            return;
        const job = queue[0];
        queue = queue.slice(1);
        current = job;
        gotText = false;
        gotExit = false;
        outText = "";
        const base = ["env", "-u", "LD_PRELOAD", "bash", "-c"];
        runner.command = job.kind === "show" ? base.concat([showScript, "solaar-show", device]) : base.concat([writeScript, "solaar-write", device, job.key, job.value]);
        runner.running = true;
    }

    function finishIfDone() {
        if (!gotText || !gotExit)
            return;
        const job = current;
        current = null;
        handle(job, outText);
        next();
    }

    function readSetting(out, label) {
        const name = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const live = out.match(new RegExp("^\\s*" + name + "\\s*:\\s*(.+?)\\s*$", "m"));
        if (live)
            return live[1];
        const saved = out.match(new RegExp("^\\s*" + name + " \\(saved\\)\\s*:\\s*(.+?)\\s*$", "m"));
        return saved ? saved[1] : null;
    }

    function toInt(t) {
        if (t === null)
            return -1;
        const v = parseInt(t, 10);
        return isNaN(v) ? -1 : v;
    }

    function handle(job, text) {
        const i = text.lastIndexOf("@@RC=");
        const body = i >= 0 ? text.slice(0, i) : text;
        const rest = i >= 0 ? text.slice(i) : "";
        const rcm = rest.match(/@@RC=(\d+)/);
        const rc = rcm ? parseInt(rcm[1]) : 1;
        const errLine = (rest.split("@@ERR")[1] || "").trim().replace(/^Exception:\s*/, "");
        const failed = rc !== 0;

        if (job.kind === "show") {
            lastMs = Date.now();
            if (failed) {
                const absent = absentMarkers.some(m => errLine.indexOf(m) >= 0);
                const pres = absent ? "absent" : "error";
                if (presence !== pres)
                    console.log("Mouse: solaar show " + pres + ". " + errLine);
                presence = pres;
                detail = errLine;
                return;
            }
            const offline = /^\s*Device is offline\./m.test(body);
            const bat = body.match(/Battery:\s*(\d+)%,\s*BatteryStatus\.(\w+)/);
            const status = bat ? bat[2] : "";
            presence = offline ? "offline" : "online";
            battery = bat ? parseInt(bat[1], 10) : -1;
            charging = status.indexOf("CHARG") >= 0 && status.indexOf("DISCHARG") < 0;
            dpi = toInt(readSetting(body, "Sensitivity (DPI)"));
            const r = readSetting(body, "Scroll Wheel Ratcheted");
            ratchet = r === "Ratcheted" || r === "Freespinning" ? r : "";
            smartShift = toInt(readSetting(body, "Scroll Wheel Ratchet Speed"));
            haptic = toInt(readSetting(body, "Haptic Feedback Level"));
            detail = "";
        } else if (failed) {
            const reason = errLine !== "" ? errLine : "solaar config failed";
            console.warn("Mouse: solaar config " + job.key + " " + job.value + " failed. " + reason);
            setFields(job.prev);
            const e = Object.assign({}, errors);
            e[job.key] = reason;
            errors = e;
        }
    }

    Process {
        id: runner
        stdout: StdioCollector {
            onStreamFinished: {
                root.outText = text;
                root.gotText = true;
                root.finishIfDone();
            }
        }
        onExited: {
            root.gotExit = true;
            root.finishIfDone();
        }
    }

    // The first read waits a few seconds, so a burst of config reloads does not wake the radio each time.
    Timer {
        interval: 4000
        running: true
        onTriggered: root.refresh()
    }
    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

}
