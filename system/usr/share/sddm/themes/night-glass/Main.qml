import QtQuick

// Night Glass login screen for SDDM. It uses the colours, fonts and pane shape of
// the Quickshell bar. Test it as a normal user with:
//   sddm-greeter-qt6 --test-mode --theme <this folder>
Rectangle {
    id: root
    width: 1920
    height: 1080

    // Tokens copied from quickshell/.config/quickshell/Theme.qml.
    readonly property color paneBg: Qt.rgba(14 / 255, 20 / 255, 44 / 255, 0.86)
    readonly property color paneBorder: Qt.rgba(163 / 255, 131 / 255, 227 / 255, 0.3)
    readonly property color fieldBorder: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.22)
    readonly property color text: "#f6f1e9"
    readonly property color muted: "#b3a998"
    readonly property color faint: "#8a93ad"
    readonly property color amMid: "#7e52c4"
    readonly property color amLt: "#a383e3"
    readonly property color teal: "#20969c"
    readonly property color tealLt: "#6fd3d6"
    readonly property color sky: "#9fd0f0"
    readonly property color err: "#f29aa2"

    property int sessionIndex: sessionModel.lastIndex
    property string message: ""

    function pt(px) {
        return px * 0.75;
    }

    function login() {
        root.message = "";
        sddm.login(userField.text, passField.text, root.sessionIndex);
    }

    FontLoader { id: mono; source: "fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: monoBold; source: "fonts/SpaceMono-Bold.ttf" }
    FontLoader { id: grotesk; source: "fonts/SpaceGrotesk.ttf" }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = "Wrong password. Try again.";
            passField.text = "";
            passField.forceActiveFocus();
        }
    }

    // Tri-primary night sky, the same order as the dots mark: emerald, navy, violet.
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0; color: "#081c1a" }
        GradientStop { position: 0.45; color: "#0a1230" }
        GradientStop { position: 1; color: "#160c30" }
    }

    // The aerie from tetsuhiro_webpage, rendered at the arrival stop. The gradient
    // above stays as the fallback when the image is missing.
    Image {
        anchors.fill: parent
        source: config.background || "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Night Glass tint. It is darker on the left, so the clock reads over the sky.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(6 / 255, 10 / 255, 26 / 255, 0.72) }
            GradientStop { position: 0.45; color: Qt.rgba(6 / 255, 10 / 255, 26 / 255, 0.25) }
            GradientStop { position: 1; color: Qt.rgba(6 / 255, 10 / 255, 26 / 255, 0.5) }
        }
    }

    // Faint 32 px grid, as in the panes.
    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = "rgba(159,208,240,0.035)";
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let x = 0; x < width; x += 32) {
                ctx.moveTo(x + 0.5, 0);
                ctx.lineTo(x + 0.5, height);
            }
            for (let y = 0; y < height; y += 32) {
                ctx.moveTo(0, y + 0.5);
                ctx.lineTo(width, y + 0.5);
            }
            ctx.stroke();
        }
    }

    // Session names, read by index for the session button.
    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item {
            required property string name
        }
    }

    // Clock, left of centre.
    Column {
        anchors { left: parent.left; leftMargin: parent.width * 0.09; verticalCenter: parent.verticalCenter }
        spacing: 6
        Text {
            id: clock
            text: Qt.formatTime(new Date(), config.clockFormat || "HH:mm")
            color: root.text
            font.family: mono.name
            font.pointSize: root.pt(140)
        }
        Text {
            id: date
            text: Qt.formatDate(new Date(), config.dateFormat || "dddd, d MMMM")
            color: root.sky
            font.family: mono.name
            font.pointSize: root.pt(26)
            font.letterSpacing: 2
            font.capitalization: Font.AllUppercase
        }
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), config.clockFormat || "HH:mm");
                date.text = Qt.formatDate(new Date(), config.dateFormat || "dddd, d MMMM");
            }
        }
    }

    // The sign-in pane, right of centre.
    Rectangle {
        id: pane
        width: 420
        height: paneCol.implicitHeight + 48
        anchors { right: parent.right; rightMargin: parent.width * 0.11; verticalCenter: parent.verticalCenter }
        color: root.paneBg
        border.width: 1
        border.color: root.paneBorder

        // Corner marks, 10 px, inset 5 px.
        Repeater {
            model: [{ ax: 0, ay: 0 }, { ax: 1, ay: 0 }, { ax: 0, ay: 1 }, { ax: 1, ay: 1 }]
            Item {
                required property var modelData
                width: 10
                height: 10
                x: modelData.ax ? pane.width - 15 : 5
                y: modelData.ay ? pane.height - 15 : 5
                opacity: 0.7
                Rectangle { color: root.amLt; width: 10; height: 1; y: parent.modelData.ay ? 9 : 0 }
                Rectangle { color: root.amLt; width: 1; height: 10; x: parent.modelData.ax ? 9 : 0 }
            }
        }

        Column {
            id: paneCol
            x: 28
            y: 24
            width: pane.width - 56
            spacing: 14

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "dots-icon.svg"
                sourceSize: Qt.size(96, 96)
                width: 96
                height: 96
            }

            // Heading over the violet to teal rule.
            Item {
                width: parent.width
                height: heading.implicitHeight + 10
                Text {
                    id: heading
                    text: "Sign in"
                    color: root.sky
                    font.family: monoBold.name
                    font.pointSize: root.pt(12)
                    font.letterSpacing: 1.8
                    font.capitalization: Font.AllUppercase
                }
                Text {
                    anchors.right: parent.right
                    text: sddm.hostName
                    color: root.faint
                    font: heading.font
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: root.amMid }
                        GradientStop { position: 0.46; color: root.teal }
                        GradientStop { position: 0.92; color: "transparent" }
                    }
                }
            }

            FieldLabel { text: "User" }
            Rectangle {
                width: parent.width
                height: 44
                color: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.04)
                border.width: 1
                border.color: userField.activeFocus ? root.teal : root.fieldBorder
                TextInput {
                    id: userField
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    // SDDM forgets the last user after some updates. The theme default covers that.
                    text: userModel.lastUser || config.defaultUser || ""
                    color: root.text
                    font.family: grotesk.name
                    font.pointSize: root.pt(17)
                    KeyNavigation.tab: passField
                    Keys.onReturnPressed: passField.forceActiveFocus()
                }
            }

            FieldLabel { text: "Password" }
            Rectangle {
                width: parent.width
                height: 44
                color: Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.04)
                border.width: 1
                border.color: root.message !== "" ? root.err : passField.activeFocus ? root.teal : root.fieldBorder
                TextInput {
                    id: passField
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "◆"
                    color: root.text
                    font.family: grotesk.name
                    font.pointSize: root.pt(17)
                    focus: true
                    KeyNavigation.backtab: userField
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed: root.login()
                }
            }

            Text {
                width: parent.width
                height: 18
                text: root.message !== "" ? root.message : (sddm.capsLockOn ? "Caps Lock is on" : "")
                color: root.message !== "" ? root.err : "#e8c27a"
                font.family: mono.name
                font.pointSize: root.pt(11)
            }

            Row {
                width: parent.width
                spacing: 10
                GlassButton {
                    width: parent.width - 130
                    text: "Session: " + (sessions.count > 0 && sessions.itemAt(root.sessionIndex) ? sessions.itemAt(root.sessionIndex).name : "default")
                    onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessions.count)
                }
                GlassButton {
                    width: 120
                    text: "Sign in"
                    accent: true
                    onClicked: root.login()
                }
            }
        }
    }

    // Power buttons, bottom right.
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 32 }
        spacing: 10
        GlassButton { text: "Suspend"; visible: sddm.canSuspend; onClicked: sddm.suspend() }
        GlassButton { text: "Reboot"; visible: sddm.canReboot; onClicked: sddm.reboot() }
        GlassButton { text: "Shut down"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }

    component FieldLabel: Text {
        color: root.amLt
        font.family: mono.name
        font.pointSize: root.pt(10)
        font.letterSpacing: 1.5
        font.capitalization: Font.AllUppercase
    }

    component GlassButton: Rectangle {
        id: btn
        property string text: ""
        property bool accent: false
        signal clicked
        implicitWidth: label.implicitWidth + 28
        height: 34
        color: accent ? Qt.rgba(32 / 255, 150 / 255, 156 / 255, ma.containsMouse ? 0.32 : 0.2) : ma.containsMouse ? Qt.rgba(159 / 255, 208 / 255, 240 / 255, 0.08) : "transparent"
        border.width: 1
        border.color: accent ? root.teal : ma.containsMouse ? root.sky : root.fieldBorder
        Text {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, btn.width - 16)
            elide: Text.ElideRight
            text: btn.text
            color: btn.accent || ma.containsMouse ? root.text : root.muted
            font.family: monoBold.name
            font.pointSize: root.pt(10.5)
            font.letterSpacing: 1.2
            font.capitalization: Font.AllUppercase
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
