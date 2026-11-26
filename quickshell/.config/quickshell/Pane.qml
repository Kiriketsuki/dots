import QtQuick

// Popup surface in the mock's .pane style: dark glass, a hairline ring, corner marks and a
// mono heading over a violet to teal rule. Corners stay square.
Rectangle {
    id: root
    property string heading: ""
    property string rightText: ""
    property bool need: false
    // Heading colour. Each pane takes the gem colour of the cell that opens it.
    property color tone: Theme.sky
    property real paneWidth: 0
    default property alias body: bodyCol.data

    implicitWidth: paneWidth > 0 ? paneWidth : inner.implicitWidth + 36
    implicitHeight: inner.implicitHeight + 30
    color: Theme.paneBg
    border.width: 1
    border.color: need ? Theme.goldLine : Theme.paneBorder

    // Faint 16 px grid.
    Canvas {
        anchors.fill: parent
        anchors.margins: 1
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = "rgba(159,208,240,0.03)";
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let x = 0; x < width; x += 16) {
                ctx.moveTo(x + 0.5, 0);
                ctx.lineTo(x + 0.5, height);
            }
            for (let y = 0; y < height; y += 16) {
                ctx.moveTo(0, y + 0.5);
                ctx.lineTo(width, y + 0.5);
            }
            ctx.stroke();
        }
    }

    // Corner marks, 8 px, inset 4 px.
    Item {
        anchors.fill: parent
        anchors.margins: 4
        opacity: 0.7
        Repeater {
            model: [
                { ax: 0, ay: 0 }, { ax: 1, ay: 0 }, { ax: 0, ay: 1 }, { ax: 1, ay: 1 }
            ]
            Item {
                required property var modelData
                width: 8
                height: 8
                x: modelData.ax ? parent.width - 8 : 0
                y: modelData.ay ? parent.height - 8 : 0
                Rectangle { color: Theme.amLt; width: 8; height: 1; y: modelData.ay ? 7 : 0 }
                Rectangle { color: Theme.amLt; width: 1; height: 8; x: modelData.ax ? 7 : 0 }
            }
        }
    }

    Column {
        id: inner
        x: 18
        y: 14
        width: root.width - 36
        spacing: 10

        Item {
            width: parent.width
            height: headLeft.implicitHeight + 9
            Text {
                id: headLeft
                text: root.heading
                color: root.need ? Theme.gold : root.tone
                font.family: Theme.mono
                font.weight: Font.DemiBold
                font.pointSize: Theme.pt(9.5)
                font.letterSpacing: 1.52
                font.capitalization: Font.AllUppercase
            }
            Text {
                anchors.right: parent.right
                width: Math.min(implicitWidth, parent.width - headLeft.implicitWidth - 16)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                text: root.rightText
                color: root.need ? Theme.gold : root.tone
                font: headLeft.font
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.amMid }
                    GradientStop { position: 0.46; color: Theme.teal }
                    GradientStop { position: 0.92; color: Qt.rgba(32 / 255, 150 / 255, 156 / 255, 0) }
                }
            }
        }

        Column {
            id: bodyCol
            width: parent.width
            spacing: 10
        }
    }
}
