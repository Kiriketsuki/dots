import QtQuick
import Quickshell
import Quickshell.Io

// One iconsmith icon from icons/build, drawn in any colour. The built SVG paints with
// currentColor, which Qt does not know, so this swaps in the colour and loads it as a data URL.
Image {
    id: root
    required property string name
    property color color: Theme.body
    property int size: 16

    width: size
    height: size
    sourceSize: Qt.size(size * 2, size * 2)
    smooth: true

    FileView {
        id: file
        path: Quickshell.shellDir + "/icons/build/" + root.name + ".svg"
        watchChanges: true
        onFileChanged: reload()
    }

    source: file.loaded ? "data:image/svg+xml;utf8," + encodeURIComponent(file.text().replace(/currentColor/g, root.color.toString())) : ""
}
