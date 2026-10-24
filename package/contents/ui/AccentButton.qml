import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl as QCI

// Push button in the system accent color: normal buttons get a light accent
// tint, highlighted, checked and pressed ones are filled. Drawn here instead
// of by the widget style, so it looks the same with every Plasma style.
Button {
    id: b
    readonly property color accent: b.palette.highlight
    readonly property color accentText: b.palette.highlightedText
    readonly property color ink: b.palette.buttonText
    readonly property bool solid: b.highlighted || b.checked || b.down

    padding: 6
    leftPadding: b.text !== "" ? 14 : 8
    rightPadding: b.text !== "" ? 14 : 8
    spacing: 6
    icon.width: 16
    icon.height: 16
    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(32, implicitContentHeight + topPadding + bottomPadding)
    hoverEnabled: true

    background: Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: 7
        color: !b.enabled ? Qt.rgba(b.ink.r, b.ink.g, b.ink.b, 0.05)
             : b.solid ? (b.down ? Qt.darker(b.accent, 1.15) : (b.hovered ? Qt.lighter(b.accent, 1.08) : b.accent))
             : Qt.rgba(b.accent.r, b.accent.g, b.accent.b, b.hovered ? 0.24 : 0.12)
        border.width: 1
        border.color: !b.enabled ? Qt.rgba(b.ink.r, b.ink.g, b.ink.b, 0.12)
                    : b.solid ? Qt.darker(b.accent, 1.12)
                    : Qt.rgba(b.accent.r, b.accent.g, b.accent.b, b.hovered ? 0.8 : 0.5)
        Behavior on color { ColorAnimation { duration: 90 } }
        Rectangle {          // keyboard focus
            anchors.fill: parent
            anchors.margins: -3
            radius: parent.radius + 3
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(b.accent.r, b.accent.g, b.accent.b, 0.6)
            visible: b.visualFocus
        }
    }

    contentItem: QCI.IconLabel {
        spacing: b.spacing
        mirrored: b.mirrored
        display: b.display
        icon: b.icon
        text: b.text
        font: b.font
        color: !b.enabled ? Qt.rgba(b.ink.r, b.ink.g, b.ink.b, 0.4) : (b.solid ? b.accentText : b.ink)
    }
}
