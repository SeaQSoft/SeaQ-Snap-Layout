import QtQuick
import QtQuick.Controls

// Horizontal slider in the system accent color.
Slider {
    id: sl
    readonly property color accent: sl.palette.highlight
    readonly property color ink: sl.palette.windowText
    hoverEnabled: true
    implicitWidth: 200
    implicitHeight: 26

    background: Rectangle {
        x: sl.leftPadding
        y: sl.topPadding + sl.availableHeight / 2 - height / 2
        width: sl.availableWidth
        height: 4
        radius: 2
        opacity: sl.enabled ? 1 : 0.45
        color: Qt.rgba(sl.ink.r, sl.ink.g, sl.ink.b, 0.18)
        Rectangle {
            width: sl.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: sl.accent
        }
    }

    handle: Rectangle {
        x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
        y: sl.topPadding + sl.availableHeight / 2 - height / 2
        implicitWidth: 18
        implicitHeight: 18
        radius: 9
        opacity: sl.enabled ? 1 : 0.6
        color: sl.pressed ? Qt.darker("white", 1.06) : "white"
        border.width: 2
        border.color: sl.enabled ? sl.accent : Qt.rgba(sl.ink.r, sl.ink.g, sl.ink.b, 0.3)
        scale: sl.pressed ? 1.12 : (sl.hovered ? 1.06 : 1)
        Behavior on scale { NumberAnimation { duration: 90 } }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(sl.accent.r, sl.accent.g, sl.accent.b, 0.5)
            visible: sl.visualFocus
        }
    }
}
