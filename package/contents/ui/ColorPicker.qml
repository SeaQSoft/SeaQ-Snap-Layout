import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/i18n.js" as I

// Inline color picker: saturation/value square, hue strip and a hex field.
// Kept inside the editor window on purpose; separate dialog windows are
// unreliable when created from a KWin script.
ColumnLayout {
    id: picker

    property color value: "#4cc2ff"
    property color lineColor: Qt.rgba(1, 1, 1, 0.15)
    signal picked(color c)

    property real hue: 0
    property real sat: 1
    property real val: 1
    property bool syncing: false

    spacing: 10

    function hex(c) {
        const h = (x) => ("0" + Math.round(x * 255).toString(16)).slice(-2);
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }

    function loadFrom(c) {
        syncing = true;
        hue = c.hsvHue < 0 ? hue : c.hsvHue;
        sat = c.hsvSaturation;
        val = c.hsvValue;
        syncing = false;
    }

    function emit() {
        if (syncing) return;
        picked(Qt.hsva(hue, sat, val, 1));
    }

    Component.onCompleted: loadFrom(value)
    onValueChanged: if (hex(value) !== hex(Qt.hsva(hue, sat, val, 1))) loadFrom(value)

    RowLayout {
        spacing: 12
        Layout.fillWidth: true

        // saturation (x) / brightness (y)
        Rectangle {
            id: sv
            Layout.preferredWidth: 220
            Layout.preferredHeight: 140
            radius: 8
            border.width: 1
            border.color: picker.lineColor
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "white" }
                GradientStop { position: 1; color: Qt.hsva(picker.hue, 1, 1, 1) }
            }
            Rectangle {
                anchors.fill: parent
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "black" }
                }
            }
            Rectangle {
                width: 14; height: 14; radius: 7
                x: picker.sat * sv.width - 7
                y: (1 - picker.val) * sv.height - 7
                color: "transparent"
                border.width: 2
                border.color: picker.val > 0.5 ? "black" : "white"
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function upd(m) {
                    picker.sat = Math.max(0, Math.min(1, m.x / sv.width));
                    picker.val = Math.max(0, Math.min(1, 1 - m.y / sv.height));
                    picker.emit();
                }
                onPressed: (m) => upd(m)
                onPositionChanged: (m) => upd(m)
            }
        }

        // hue strip
        Rectangle {
            id: hueBar
            Layout.preferredWidth: 22
            Layout.preferredHeight: 140
            radius: 6
            border.width: 1
            border.color: picker.lineColor
            gradient: Gradient {
                GradientStop { position: 0.000; color: Qt.hsva(0.000, 1, 1, 1) }
                GradientStop { position: 0.167; color: Qt.hsva(0.167, 1, 1, 1) }
                GradientStop { position: 0.333; color: Qt.hsva(0.333, 1, 1, 1) }
                GradientStop { position: 0.500; color: Qt.hsva(0.500, 1, 1, 1) }
                GradientStop { position: 0.667; color: Qt.hsva(0.667, 1, 1, 1) }
                GradientStop { position: 0.833; color: Qt.hsva(0.833, 1, 1, 1) }
                GradientStop { position: 1.000; color: Qt.hsva(0.999, 1, 1, 1) }
            }
            Rectangle {
                x: -3
                width: parent.width + 6
                height: 6
                radius: 3
                y: picker.hue * hueBar.height - 3
                color: "transparent"
                border.width: 2
                border.color: "white"
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function upd(m) {
                    picker.hue = Math.max(0, Math.min(0.999, m.y / hueBar.height));
                    picker.emit();
                }
                onPressed: (m) => upd(m)
                onPositionChanged: (m) => upd(m)
            }
        }

        ColumnLayout {
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 40
                radius: 8
                color: Qt.hsva(picker.hue, picker.sat, picker.val, 1)
                border.width: 1
                border.color: picker.lineColor
            }
            TextField {
                id: hexField
                Layout.preferredWidth: 110
                text: picker.hex(Qt.hsva(picker.hue, picker.sat, picker.val, 1))
                validator: RegularExpressionValidator { regularExpression: /^#?[0-9a-fA-F]{6}$/ }
                onEditingFinished: {
                    if (!acceptableInput) return;
                    const t = text.charAt(0) === "#" ? text : "#" + text;
                    picker.loadFrom(Qt.color(t));
                    picker.picked(Qt.color(t));
                }
            }
        }
    }
}
