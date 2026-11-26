import QtQuick
import Quickshell.Services.Pipewire

Cell {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    label: "Vol · " + (muted ? "muted" : Math.round(vol * 100))
    labelColor: Theme.emerald
    onWheeled: dy => {
        if (sink && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (dy > 0 ? 0.05 : -0.05)));
    }

    Item {
        width: 58
        height: 8
        Gauge {
            endColor: Theme.emerald
            y: 3
            width: 58
            value: root.muted ? 0 : root.vol
        }
    }
}
