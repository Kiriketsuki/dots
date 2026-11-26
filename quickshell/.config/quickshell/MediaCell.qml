import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Cell {
    id: root
    // Prefer a playing player, else the first one.
    readonly property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) || (list.length ? list[0] : null);
    }
    readonly property string line: player ? [player.trackArtist, player.trackTitle].filter(s => s && s.length).join(" · ") : ""

    label: "Now playing"
    icon: "music"
    labelColor: Theme.rhodolite
    // A click opens the media pane. MainBar wires that up.

    TextMetrics { id: tm; text: root.line; font.family: Theme.mono; font.pointSize: Theme.pt(12); font.weight: Font.Medium }
    Val {
        width: Math.min(tm.width + 2, 280)
        text: root.line !== "" ? root.line : "Nothing playing"
        color: root.line !== "" ? Theme.body : Theme.faint
    }
}
