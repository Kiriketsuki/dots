import QtQuick

// Tiny uppercase label that sits above a value.
Text {
    color: Theme.amLabel
    font.family: Theme.mono
    font.weight: Font.DemiBold
    font.pointSize: Theme.pt(8.5)
    font.letterSpacing: 1.36
    font.capitalization: Font.AllUppercase
    textFormat: Text.StyledText
    elide: Text.ElideRight
}
