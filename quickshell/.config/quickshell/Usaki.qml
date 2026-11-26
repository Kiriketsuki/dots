pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// usaKi pool status from ~/.cache/cliproxy/<pool>.status.json, refreshed every 30 s.
Singleton {
    id: root

    readonly property var poolNames: ["work", "personal"]
    readonly property int staleAfter: 600
    property var raws: ({})
    property real now: Date.now() / 1000

    readonly property var pools: {
        const out = {};
        for (const k in raws)
            out[k] = compute(raws[k], now);
        return out;
    }
    readonly property var work: pools["work"] || null

    function value(used, resetEpoch, hoursLeft, updated) {
        if (used === null || used === undefined)
            return null;
        let reset = null;
        if (resetEpoch !== null && resetEpoch !== undefined)
            reset = resetEpoch;
        else if (hoursLeft !== null && hoursLeft !== undefined)
            reset = updated + hoursLeft * 3600;
        // A window whose reset has passed counts as empty.
        if (reset !== null && reset <= now)
            return 0;
        return used;
    }

    function mean(list) {
        const v = list.filter(x => x !== null);
        return v.length ? v.reduce((a, b) => a + b, 0) / v.length : null;
    }

    function compute(raw, nowSec) {
        const upd = raw.updated_epoch || 0;
        const seats = (raw.seats || []).map(s => ({
                    name: s.seat,
                    state: s.state || "",
                    week: value(s.week_used, s.week_reset_epoch, s.week_hours_left, upd),
                    five: value(s.five_hour_used, s.five_hour_reset_epoch, s.five_hour_hours_left, upd),
                    weekReset: (s.week_reset_epoch !== null && s.week_reset_epoch !== undefined) ? s.week_reset_epoch : ((s.week_hours_left !== null && s.week_hours_left !== undefined) ? upd + s.week_hours_left * 3600 : null)
                }));
        return {
            name: raw.pool,
            age: nowSec - upd,
            stale: nowSec - upd > staleAfter,
            next: raw.next_seat || "",
            seats: seats,
            five: mean(seats.map(s => s.five)),
            week: mean(seats.map(s => s.week)),
            open: seats.filter(s => s.state === "open").length,
            leftEar: seats.some(s => s.week !== null && s.week >= 0.75),
            rightEar: seats.some(s => s.five !== null && s.five >= 0.75)
        };
    }

    function set(name, text) {
        try {
            const next = Object.assign({}, raws);
            next[name] = JSON.parse(text);
            raws = next;
        } catch (e) {
            console.warn("usaki: bad JSON in " + name + " status file: " + e);
        }
    }

    Instantiator {
        id: readers
        model: root.poolNames
        delegate: FileView {
            id: fv
            required property string modelData
            path: Quickshell.env("HOME") + "/.cache/cliproxy/" + modelData + ".status.json"
            watchChanges: true
            onFileChanged: reload()
            onLoaded: root.set(modelData, fv.text())
            onLoadFailed: error => console.warn("usaki: cannot read " + path + " (" + error + ")")
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            root.now = Date.now() / 1000;
            for (let i = 0; i < readers.count; i++)
                readers.objectAt(i).reload();
        }
    }
}
