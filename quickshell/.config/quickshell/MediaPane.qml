import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Media pane: cover art, title, artist, album, a position bar and the transport buttons.
// With more than one player it also lists them, and a click picks the one to control.
PaneWindow {
    id: root
    readonly property color tone: Theme.rhodolite
    readonly property var players: Mpris.players.values
    // Identity of the player the user picked. Empty means the automatic choice.
    property string picked: ""
    readonly property var player: {
        const list = players;
        const chosen = list.find(p => p.identity === picked);
        return chosen || list.find(p => p.isPlaying) || (list.length ? list[0] : null);
    }
    readonly property real len: player && player.lengthSupported ? player.length : 0
    readonly property real pos: player && player.positionSupported ? player.position : 0

    function clock(s) {
        const t = Math.max(0, Math.floor(s));
        const m = Math.floor(t / 60);
        return m + ":" + (t % 60 < 10 ? "0" : "") + (t % 60);
    }

    // Position only updates by signal, so poll while the pane shows a playing track.
    Timer {
        interval: 1000
        running: root.open && root.player && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Pane {
        paneWidth: 420
        tone: root.tone
        heading: "☾ Media"
        rightText: root.player ? root.player.identity : ""

        Text {
            visible: !root.player
            text: "No media player is running."
            color: Theme.faint
            font.family: Theme.ui
            font.pointSize: Theme.pt(12.5)
        }

        Row {
            visible: !!root.player
            spacing: 14
            Rectangle {
                width: 96
                height: 96
                color: Theme.gaugeTrack
                border.width: 1
                border.color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.35)
                Image {
                    id: art
                    anchors.fill: parent
                    anchors.margins: 1
                    source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 192
                    sourceSize.height: 192
                }
                Text {
                    visible: art.status !== Image.Ready
                    anchors.centerIn: parent
                    text: "☾"
                    color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.5)
                    font.pointSize: Theme.pt(32)
                }
            }
            Column {
                width: 420 - 36 - 96 - 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.ui
                    font.pointSize: Theme.pt(17)
                }
                Text {
                    width: parent.width
                    text: root.player ? root.player.trackArtist : ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    color: Theme.body
                    font.family: Theme.ui
                    font.pointSize: Theme.pt(13)
                }
                Text {
                    width: parent.width
                    text: root.player ? root.player.trackAlbum : ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.ui
                    font.pointSize: Theme.pt(12)
                }
            }
        }

        // Position bar. A click seeks when the player allows it.
        Item {
            visible: !!root.player
            width: parent.width
            height: 18
            Text {
                id: tl
                anchors.verticalCenter: parent.verticalCenter
                text: root.clock(root.pos)
                color: Theme.muted
                font.family: Theme.mono
                font.pointSize: Theme.pt(10)
            }
            Gauge {
                id: pg
                x: tl.implicitWidth + 10
                width: parent.width - 2 * (tl.implicitWidth + 10)
                height: 6
                anchors.verticalCenter: parent.verticalCenter
                value: root.len > 0 ? root.pos / root.len : 0
                endColor: root.tone
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: !!root.player && root.player.canSeek && root.len > 0
                    onClicked: mouse => {
                        root.player.position = Math.max(0, Math.min(1, (mouse.x - 6) / pg.width)) * root.len;
                    }
                }
            }
            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: root.len > 0 ? root.clock(root.len) : "--:--"
                color: Theme.muted
                font.family: Theme.mono
                font.pointSize: Theme.pt(10)
            }
        }

        Row {
            visible: !!root.player
            spacing: 6
            PaneBtn { text: "⏮ Prev"; tone: root.tone; enabled: !!root.player && root.player.canGoPrevious; onClicked: root.player.previous() }
            PaneBtn {
                text: root.player && root.player.isPlaying ? "⏸ Pause" : "▶ Play"
                tone: root.tone
                active: !!root.player && root.player.isPlaying
                enabled: !!root.player && root.player.canTogglePlaying
                onClicked: root.player.togglePlaying()
            }
            PaneBtn { text: "Next ⏭"; tone: root.tone; enabled: !!root.player && root.player.canGoNext; onClicked: root.player.next() }
        }

        // Other players, when there is more than one.
        Column {
            visible: root.players.length > 1
            width: parent.width
            Repeater {
                model: root.players
                Item {
                    id: pr
                    required property var modelData
                    readonly property bool cur: modelData === root.player
                    width: parent.width
                    height: 26
                    DashedLine { vertical: false; width: parent.width; height: 1 }
                    Text {
                        x: 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: pr.cur ? "●" : "○"
                        color: pr.cur ? root.tone : Theme.faint
                        font.pointSize: Theme.pt(10)
                    }
                    Text {
                        x: 22
                        width: 90
                        anchors.verticalCenter: parent.verticalCenter
                        text: pr.modelData.identity
                        color: pr.cur ? Theme.text : Theme.muted
                        elide: Text.ElideRight
                        font.family: Theme.mono
                        font.weight: Font.DemiBold
                        font.pointSize: Theme.pt(9.5)
                    }
                    Text {
                        x: 120
                        width: parent.width - 120 - 62
                        anchors.verticalCenter: parent.verticalCenter
                        text: pr.modelData.trackTitle || ""
                        color: Theme.muted
                        elide: Text.ElideRight
                        font.family: Theme.ui
                        font.pointSize: Theme.pt(11.5)
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: pr.modelData.isPlaying ? "playing" : "paused"
                        color: pr.modelData.isPlaying ? Theme.tealLt : Theme.faint
                        font.family: Theme.mono
                        font.pointSize: Theme.pt(9)
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.picked = pr.modelData.identity }
                }
            }
        }
    }
}
