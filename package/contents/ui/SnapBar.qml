import QtQuick
import "../code/i18n.js" as I

// The snap bar itself. Collapsed it is just a small handle, expanded it
// shows a thumbnail for every layout.
Item {
    id: bar

    property var layouts: []
    property var theme: null
    property real uiScale: 1.0
    property int thumbW: 72
    property real aspect: 0.5625
    property int perRow: 0
    property int cornerR: 8
    property real bgOpacity: 0.96
    property int hoverLayout: -1
    property int hoverZone: -1
    property bool showName: false
    property bool expanded: true
    property int animDuration: 220
    property int easingType: Easing.OutCubic

    readonly property real s: uiScale
    readonly property int pad: Math.round(12 * s)
    readonly property int gapT: Math.round(12 * s)
    readonly property int tw: Math.max(24, Math.round(thumbW * s))
    readonly property int th: Math.max(14, Math.round(tw * aspect))
    readonly property int count: layouts ? layouts.length : 0
    readonly property int cols: Math.max(1, perRow > 0 ? Math.min(perRow, count) : count)
    readonly property int rows: Math.max(1, Math.ceil(count / cols))
    readonly property int nameH: showName ? Math.round(24 * s) : 0
    readonly property int fullW: pad * 2 + cols * tw + (cols - 1) * gapT
    readonly property int fullH: pad * 2 + rows * th + (rows - 1) * gapT + nameH
    readonly property int pillW: Math.round(Math.min(fullW, 132 * s))
    readonly property int pillH: Math.round(16 * s)

    readonly property color cBg: theme ? theme.barBg : "#2b2b2b"
    readonly property color cBorder: theme ? theme.barBorder : Qt.rgba(1, 1, 1, 0.1)
    readonly property color cZone: theme ? theme.zone : "#5a5a5a"
    readonly property color cZoneBorder: theme ? theme.zoneBorder : Qt.rgba(1, 1, 1, 0.12)
    readonly property color cAccent: theme ? theme.accent : "#4cc2ff"
    readonly property color cText: theme ? theme.text : "white"

    width: expanded ? fullW : pillW
    height: expanded ? fullH : pillH
    Behavior on width  { NumberAnimation { duration: bar.animDuration; easing.type: bar.easingType } }
    Behavior on height { NumberAnimation { duration: bar.animDuration; easing.type: bar.easingType } }

    // Soft shadow built from a few transparent rings. A real blur would need
    // an extra layer and costs more than it's worth for a short-lived popup.
    Repeater {
        model: 7
        Rectangle {
            required property int index
            anchors.fill: parent
            anchors.margins: -(index + 1) * bar.s
            anchors.topMargin: -(index + 1) * bar.s + bar.s
            anchors.bottomMargin: -(index + 1) * bar.s - 2 * bar.s
            radius: bg.radius + (index + 1) * bar.s
            color: "transparent"
            border.width: Math.max(1, bar.s)
            border.color: Qt.rgba(0, 0, 0, 0.11 * (1 - index / 7))
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Math.min(height / 2, bar.cornerR * bar.s)
        color: Qt.rgba(bar.cBg.r, bar.cBg.g, bar.cBg.b, bar.bgOpacity)
        border.width: 1
        border.color: bar.cBorder
    }

    // grip line shown while collapsed
    Rectangle {
        anchors.centerIn: parent
        width: Math.round(36 * bar.s)
        height: Math.max(3, Math.round(4 * bar.s))
        radius: height / 2
        color: bar.cZone
        opacity: bar.expanded ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: inner
            width: bar.fullW
            height: bar.fullH
            x: Math.round((parent.width - bar.fullW) / 2)
            opacity: bar.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Math.round(bar.animDuration * 0.7) } }

            Grid {
                x: bar.pad
                y: bar.pad
                columns: bar.cols
                rowSpacing: bar.gapT
                columnSpacing: bar.gapT

                Repeater {
                    id: rep
                    model: bar.layouts

                    delegate: Item {
                        id: thumb
                        required property var modelData
                        required property int index
                        readonly property bool layoutHot: index === bar.hoverLayout
                        width: bar.tw
                        height: bar.th

                        Repeater {
                            model: thumb.modelData.zones
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool hot: thumb.layoutHot && index === bar.hoverZone
                                readonly property real g: Math.max(1, Math.round(1.5 * bar.s))
                                readonly property int x1: Math.round(modelData.x * thumb.width + (modelData.x > 0.001 ? g : 0))
                                readonly property int y1: Math.round(modelData.y * thumb.height + (modelData.y > 0.001 ? g : 0))
                                readonly property int x2: Math.round((modelData.x + modelData.w) * thumb.width - (modelData.x + modelData.w < 0.999 ? g : 0))
                                readonly property int y2: Math.round((modelData.y + modelData.h) * thumb.height - (modelData.y + modelData.h < 0.999 ? g : 0))
                                x: x1
                                y: y1
                                width: Math.max(2, x2 - x1)
                                height: Math.max(2, y2 - y1)
                                radius: Math.max(2, Math.round(3 * bar.s))
                                color: hot ? bar.cAccent : bar.cZone
                                border.width: 1
                                border.color: hot ? Qt.lighter(bar.cAccent, 1.25) : bar.cZoneBorder
                                Behavior on color { ColorAnimation { duration: 90 } }
                            }
                        }
                    }
                }
            }

            Text {
                visible: bar.showName
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(bar.pad * 0.6)
                width: parent.width - 2 * bar.pad
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: bar.cText
                opacity: 0.85
                font.pixelSize: Math.round(12 * bar.s)
                text: (bar.hoverLayout >= 0 && bar.hoverLayout < bar.count)
                      ? bar.layouts[bar.hoverLayout].name + (bar.hoverZone >= 0 ? "  ·  " + I.tr("Zone %1", bar.hoverZone + 1) : "")
                      : I.tr("Drop the window onto a zone")
            }
        }
    }

    // Which layout/zone sits under (px, py)? Coordinates are in fromItem space.
    function hit(fromItem, px, py) {
        if (!expanded) return { layout: -1, zone: -1 };
        for (let i = 0; i < rep.count; i++) {
            const t = rep.itemAt(i);
            if (!t) continue;
            const p = t.mapFromItem(fromItem, px, py);
            if (p.x < 0 || p.y < 0 || p.x >= t.width || p.y >= t.height) continue;
            const zx = p.x / t.width, zy = p.y / t.height;
            const zs = layouts[i].zones;
            for (let j = 0; j < zs.length; j++) {
                const z = zs[j];
                if (zx >= z.x && zx < z.x + z.w && zy >= z.y && zy < z.y + z.h)
                    return { layout: i, zone: j };
            }
        }
        return { layout: -1, zone: -1 };
    }
}
