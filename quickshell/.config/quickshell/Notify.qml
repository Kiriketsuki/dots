import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification service. It is on by default. QS_NOTIFY=0 turns it off.
// QS_NOTIFY_DEMO=1 shows the toast and list UI with fake records and never touches D-Bus.
Scope {
    id: root
    property var screenRef: null
    readonly property bool active: Theme.notifyEnabled || Theme.notifyDemo
    property bool listOpen: false
    // Quiet (do not disturb): new notifications go to the list but show no toast.
    property bool quiet: false
    property var toasts: []
    property var history: []
    property int seq: 0

    function record(n, fake) {
        seq += 1;
        return {
            id: seq,
            app: n.appName && n.appName.length ? n.appName : "Notification",
            summary: n.summary,
            body: n.body,
            urgent: fake ? n.urgent : n.urgency === NotificationUrgency.Critical,
            time: Qt.formatDateTime(new Date(), "hh:mm"),
            actions: fake ? [] : n.actions.map(a => a),
            source: fake ? null : n
        };
    }

    function push(rec) {
        if (!quiet)
            toasts = [rec].concat(toasts).slice(0, 4);
        history = [rec].concat(history).slice(0, 50);
    }

    function dropToast(id) { toasts = toasts.filter(r => r.id !== id); }
    function dropHistory(id) {
        const r = history.find(x => x.id === id);
        if (r && r.source)
            r.source.dismiss();
        history = history.filter(x => x.id !== id);
        dropToast(id);
    }

    // Dismisses every notification, so each sender also hears that it closed.
    function clearAll() {
        const all = history;
        history = [];
        toasts = [];
        all.forEach(r => { if (r.source) r.source.dismiss(); });
    }

    IpcHandler {
        target: "notify"
        function toggleList(): void { root.listOpen = !root.listOpen; }
        function clearAll(): void { root.clearAll(); }
        function toggleQuiet(): void { root.quiet = !root.quiet; }
    }

    LazyLoader {
        active: Theme.notifyEnabled
        NotificationServer {
            keepOnReload: true
            actionsSupported: true
            bodySupported: true
            imageSupported: false
            onNotification: n => {
                n.tracked = true;
                const rec = root.record(n, false);
                root.push(rec);
                n.closed.connect(() => {
                    root.history = root.history.filter(x => x.id !== rec.id);
                    root.dropToast(rec.id);
                });
            }
        }
    }

    Timer {
        interval: 1500
        running: Theme.notifyDemo
        onTriggered: {
            root.push(root.record({ appName: "Slack #ads-daily", summary: "Standup moved to 10:15", body: "Joachim: pushing standup 15 min, the depot sync is running late.", urgent: true }, true));
            root.push(root.record({ appName: "Mail", summary: "Build finished", body: "All checks passed.", urgent: false }, true));
        }
    }

    LazyLoader {
        active: root.active
        NotifyView { notify: root; screenRef: root.screenRef }
    }
}
