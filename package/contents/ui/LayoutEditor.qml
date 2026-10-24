import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/layouts.js" as L
import "../code/i18n.js" as I

// Visual editor for custom split layouts.
// Click a zone to select it, double-click to split it, drag a divider to
// resize. Dividers stick to common fractions unless snapping is off.
ColumnLayout {
    id: ed

    property var tree: L.split("v", 0.5, L.leaf(), L.leaf())
    property string selected: ""
    property bool snapping: true
    property real aspect: 0.5625
    property color accent: "#3daee9"
    property color zoneColor: "#555555"
    property color fg: "white"
    property color accentText: "white"
    property color lineColor: Qt.rgba(1, 1, 1, 0.15)
    property color stageColor: "#1e1e1e"

    readonly property var geo: L.compute(tree)
    readonly property int zoneCount: geo.zones.length
    readonly property int maxZones: 16
    readonly property bool hasSelection: L.isZonePath(tree, selected) && zoneCount > 0

    spacing: 10

    function applyTree(t) {
        tree = t;
        if (!L.isZonePath(tree, selected)) selected = L.firstZonePath(tree);
    }
    function splitSelected(d) {
        if (zoneCount >= maxZones) return;
        const p = hasSelection ? selected : L.firstZonePath(tree);
        tree = L.splitZone(tree, p, d);
        selected = p + "a";
    }
    function removeSelected() {
        if (!hasSelection || zoneCount <= 1) return;
        applyTree(L.removeZone(tree, selected));
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        AccentButton {
            text: I.tr("Split side by side")
            icon.name: "view-split-left-right"
            enabled: ed.zoneCount < ed.maxZones
            onClicked: ed.splitSelected("v")
        }
        AccentButton {
            text: I.tr("Split top and bottom")
            icon.name: "view-split-top-bottom"
            enabled: ed.zoneCount < ed.maxZones
            onClicked: ed.splitSelected("h")
        }
        AccentButton {
            text: I.tr("Remove zone")
            icon.name: "edit-delete"
            enabled: ed.hasSelection && ed.zoneCount > 1
            onClicked: ed.removeSelected()
        }
        ComboBox {
            id: tpl
            width: 220
            model: L.templates().map(function (t) { return I.layoutName(t.name); })
            displayText: I.tr("Load template…")
            onActivated: function (i) {
                ed.tree = L.clone(L.templates()[i].tree);
                ed.selected = L.firstZonePath(ed.tree);
            }
        }
    }

    Item {
        id: stage
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120

        Rectangle {
            id: area
            width: Math.min(stage.width, stage.height / ed.aspect)
            height: width * ed.aspect
            anchors.centerIn: parent
            radius: 10
            color: ed.stageColor
            border.width: 1
            border.color: ed.lineColor

            Repeater {
                model: ed.geo.zones.length
                delegate: Rectangle {
                    id: zoneRect
                    required property int index
                    readonly property var zd: ed.geo.zones[index] || ({ path: "", x: 0, y: 0, w: 0, h: 0 })
                    readonly property bool sel: zd.path === ed.selected
                    readonly property real g: 4
                    x: Math.round(zd.x * area.width) + g
                    y: Math.round(zd.y * area.height) + g
                    width: Math.max(4, Math.round(zd.w * area.width) - 2 * g)
                    height: Math.max(4, Math.round(zd.h * area.height) - 2 * g)
                    radius: 6
                    color: sel ? Qt.rgba(ed.accent.r, ed.accent.g, ed.accent.b, 0.35)
                               : (zoneMouse.containsMouse ? Qt.lighter(ed.zoneColor, 1.15) : ed.zoneColor)
                    border.width: sel ? 2 : 1
                    border.color: sel ? ed.accent : ed.lineColor
                    Behavior on color { ColorAnimation { duration: 90 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: zoneRect.index + 1
                            font.pixelSize: Math.max(12, Math.min(28, zoneRect.height / 4))
                            font.bold: true
                            color: ed.fg
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: zoneRect.width > 70 && zoneRect.height > 50
                            text: Math.round(zoneRect.zd.w * 100) + " × " + Math.round(zoneRect.zd.h * 100) + " %"
                            opacity: 0.7
                            color: ed.fg
                        }
                    }

                    MouseArea {
                        id: zoneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: ed.selected = zoneRect.zd.path
                        onDoubleClicked: {
                            ed.selected = zoneRect.zd.path;
                            ed.splitSelected(zoneRect.width >= zoneRect.height ? "v" : "h");
                        }
                    }
                }
            }

            // dividers sit above the zones so they can be grabbed
            Repeater {
                model: ed.geo.dividers.length
                delegate: Item {
                    id: div
                    required property int index
                    readonly property var d: ed.geo.dividers[index] || ({ path: "", d: "v", nx: 0, ny: 0, nw: 0, nh: 0, pos: 0, r: 0.5 })
                    readonly property bool vert: d.d === "v"
                    readonly property bool active: dm.pressed || dm.containsMouse
                    x: vert ? Math.round(d.pos * area.width) - 7 : Math.round(d.nx * area.width)
                    y: vert ? Math.round(d.ny * area.height) : Math.round(d.pos * area.height) - 7
                    width: vert ? 14 : Math.round(d.nw * area.width)
                    height: vert ? Math.round(d.nh * area.height) : 14

                    Rectangle {
                        anchors.centerIn: parent
                        width: div.vert ? (div.active ? 4 : 2) : parent.width - 16
                        height: div.vert ? parent.height - 16 : (div.active ? 4 : 2)
                        radius: 2
                        color: div.active ? ed.accent : "transparent"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: div.vert ? 8 : 34
                        height: div.vert ? 34 : 8
                        radius: 4
                        color: div.active ? ed.accent : Qt.rgba(ed.fg.r, ed.fg.g, ed.fg.b, 0.35)
                    }
                    Rectangle {
                        visible: dm.pressed
                        anchors.centerIn: parent
                        width: pct.implicitWidth + 14
                        height: pct.implicitHeight + 6
                        radius: height / 2
                        color: ed.accent
                        Label {
                            id: pct
                            anchors.centerIn: parent
                            color: ed.accentText
                            font.bold: true
                            text: Math.round(div.d.r * 100) + " / " + (100 - Math.round(div.d.r * 100))
                        }
                    }

                    MouseArea {
                        id: dm
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: div.vert ? Qt.SplitHCursor : Qt.SplitVCursor
                        onPositionChanged: function (mouse) {
                            if (!pressed) return;
                            const p = mapToItem(area, mouse.x, mouse.y);
                            const r = div.vert ? (p.x / area.width - div.d.nx) / Math.max(0.0001, div.d.nw)
                                               : (p.y / area.height - div.d.ny) / Math.max(0.0001, div.d.nh);
                            ed.tree = L.setRatio(ed.tree, div.d.path, L.snapRatio(r, ed.snapping));
                        }
                    }
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        opacity: 0.65
        text: I.tr("Click a zone to select it · double-click to split · drag the dividers") + "  ·  "
              + I.tr("%1 of %2 zones", ed.zoneCount, ed.maxZones)
    }
}
