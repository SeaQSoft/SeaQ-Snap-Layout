import QtQuick
import QtQuick.Controls

// On/off switch in the system accent color.
Switch {
    id: s
    readonly property color accent: s.palette.highlight
    readonly property color ink: s.palette.windowText
    hoverEnabled: true
    padding: 2
    spacing: 8
    implicitWidth: s.text !== "" ? implicitContentWidth + leftPadding + rightPadding
                                 : indicator.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(indicator.implicitHeight, implicitContentHeight) + topPadding + bottomPadding

    indicator: Rectangle {
        implicitWidth: 40
        implicitHeight: 22
        x: s.text !== "" ? (s.mirrored ? s.width - width - s.rightPadding : s.leftPadding) : s.leftPadding
        y: s.topPadding + (s.availableHeight - height) / 2
        radius: height / 2
        opacity: s.enabled ? 1 : 0.45
        color: s.checked ? (s.hovered ? Qt.lighter(s.accent, 1.08) : s.accent)
                         : Qt.rgba(s.ink.r, s.ink.g, s.ink.b, s.hovered ? 0.24 : 0.17)
        border.width: 1
        border.color: s.checked ? Qt.darker(s.accent, 1.12) : Qt.rgba(s.ink.r, s.ink.g, s.ink.b, 0.22)
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: s.checked ? parent.width - width - 2 : 2
            color: "white"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.15)
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        Rectangle {          // keyboard focus
            anchors.fill: parent
            anchors.margins: -3
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(s.accent.r, s.accent.g, s.accent.b, 0.6)
            visible: s.visualFocus
        }
    }

    contentItem: Label {
        visible: s.text !== ""
        text: s.text
        font: s.font
        color: s.ink
        verticalAlignment: Text.AlignVCenter
        leftPadding: s.text !== "" && !s.mirrored ? s.indicator.width + s.spacing : 0
        rightPadding: s.text !== "" && s.mirrored ? s.indicator.width + s.spacing : 0
    }
}
