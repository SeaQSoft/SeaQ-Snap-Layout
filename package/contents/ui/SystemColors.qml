import QtQuick
import org.kde.kirigami as Kirigami

// Container for the editor. Inside a Plasma dialog, Kirigami controls would
// otherwise take their colors from the Plasma style, which can be dark while
// the color scheme is light. Here every color is set from the system color
// scheme (app.sysPalette), and the children inherit it.
Item {
    id: box
    property var app
    readonly property var p: app.sysPalette

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.textColor: p.windowText
    Kirigami.Theme.disabledTextColor: Qt.rgba(p.windowText.r, p.windowText.g, p.windowText.b, 0.5)
    Kirigami.Theme.backgroundColor: p.window
    Kirigami.Theme.alternateBackgroundColor: p.alternateBase
    Kirigami.Theme.highlightColor: p.highlight
    Kirigami.Theme.highlightedTextColor: p.highlightedText
    Kirigami.Theme.hoverColor: p.highlight
    Kirigami.Theme.focusColor: p.highlight
    Kirigami.Theme.linkColor: p.highlight
    Kirigami.Theme.activeTextColor: p.highlight
}
