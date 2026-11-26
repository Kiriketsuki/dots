pragma Singleton
import QtQuick
import Quickshell

// Design tokens copied from the approved Observatory mock (slot-b-v2).
Singleton {
    // Surfaces
    readonly property color glass: Qt.rgba(13 / 255, 21 / 255, 38 / 255, 0.84)
    readonly property color paneBg: Qt.rgba(14 / 255, 20 / 255, 44 / 255, 0.95)
    readonly property color paneBorder: Qt.rgba(163 / 255, 131 / 255, 227 / 255, 0.3)
    readonly property color rule: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.16)

    // Text
    readonly property color text: "#f6f1e9"
    readonly property color body: "#e8e2d6"
    readonly property color muted: "#b3a998"
    readonly property color faint: "#8a93ad"

    // Brand
    readonly property color amMid: "#7e52c4"
    readonly property color amLt: "#a383e3"
    readonly property color amLabel: "#b9a2ec"
    readonly property color teal: "#20969c"
    readonly property color tealLt: "#6fd3d6"
    readonly property color sky: "#9fd0f0"

    // Chrysaki gem colours, lifted a little so they read on the dark glass. Each bar cell
    // takes one, so the bar is not all amethyst.
    readonly property color cerulean: "#5aa9ec"
    readonly property color topaz: "#e08a3c"
    readonly property color peridot: "#b4bf3a"
    readonly property color rhodolite: "#d0609f"
    readonly property color bronze: "#c9a27a"
    readonly property color emerald: "#2fb38a"

    // Gold means "needs attention" and nothing else.
    readonly property color gold: "#e8c27a"
    readonly property color warn: "#fbb13c"
    readonly property color err: "#f29aa2"

    // Derived colours
    readonly property color ringEmpty: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.22)
    readonly property color ringOcc: Qt.rgba(90 / 255, 169 / 255, 236 / 255, 0.7)
    readonly property color tealFill: Qt.rgba(111 / 255, 211 / 255, 214 / 255, 0.12)
    readonly property color gaugeTick: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.28)
    readonly property color gaugeTrack: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.08)
    readonly property color goldLine: Qt.rgba(232 / 255, 194 / 255, 122 / 255, 0.65)

    // Fonts: Space Mono for labels, numbers and the clock. Space Grotesk for titles and pane text.
    // Both live in ~/.local/share/fonts/space, from the Google Fonts repository.
    readonly property string mono: "Space Mono"
    readonly property string ui: "Space Grotesk"

    // Sizes
    readonly property int mainHeight: 38
    // DP-2 is the Prism+ 27 inch screen with workspaces 11 to 20. Notifications show there.
    readonly property string mainMonitor: "DP-2"
    // One bar only, on the main monitor. The side monitors have no bar.
    readonly property bool singleBar: true

    // Flags. Notifications stay off until the user opts in, so swaync keeps the bus.
    readonly property bool notifyEnabled: Quickshell.env("QS_NOTIFY") !== "0"
    readonly property bool notifyDemo: Quickshell.env("QS_NOTIFY_DEMO") === "1"

    // Qt font sizes are in points. This converts CSS pixels at 96 dpi.
    function pt(px) {
        return px * 0.75;
    }

    function lerp(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    // usaKi tiers: under 50 teal, from 50 amber, from 75 rose.
    function tierColor(f) {
        if (f === null || f === undefined)
            return faint;
        return f >= 0.75 ? err : f >= 0.5 ? warn : tealLt;
    }
}
