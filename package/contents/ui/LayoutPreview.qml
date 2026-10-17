import QtQuick
import "../code/layouts.js" as L

// Small read-only picture of a layout, used on the layout cards.
Item {
    id: lp
    property string treeJson: ""
    property real aspect: 0.5625
    property color zoneColor: "#666666"
    property color borderColor: Qt.rgba(1, 1, 1, 0.15)
    property color frameColor: "transparent"
    readonly property var zones: L.zones(L.parseTree(treeJson))

    Rectangle {
        id: box
        width: Math.min(lp.width, lp.height / lp.aspect)
        height: width * lp.aspect
        anchors.centerIn: parent
        color: lp.frameColor
        radius: 6

        Repeater {
            model: lp.zones
            delegate: Rectangle {
                required property var modelData
                readonly property real g: 2
                readonly property int x1: Math.round(modelData.x * box.width + (modelData.x > 0.001 ? g : 0))
                readonly property int y1: Math.round(modelData.y * box.height + (modelData.y > 0.001 ? g : 0))
                readonly property int x2: Math.round((modelData.x + modelData.w) * box.width - (modelData.x + modelData.w < 0.999 ? g : 0))
                readonly property int y2: Math.round((modelData.y + modelData.h) * box.height - (modelData.y + modelData.h < 0.999 ? g : 0))
                x: x1; y: y1
                width: Math.max(2, x2 - x1)
                height: Math.max(2, y2 - y1)
                radius: 4
                color: lp.zoneColor
                border.width: 1
                border.color: lp.borderColor
            }
        }
    }
}
