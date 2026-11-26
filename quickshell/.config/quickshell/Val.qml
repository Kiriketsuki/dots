import QtQuick

// Value text. Mono by default, Inter when `ui` is set.
Text {
    property bool ui: false
    color: Theme.body
    font.family: ui ? Theme.ui : Theme.mono
    font.weight: ui ? Font.Normal : Font.Medium
    font.pointSize: Theme.pt(ui ? 12.5 : 12)
    elide: Text.ElideRight
}
