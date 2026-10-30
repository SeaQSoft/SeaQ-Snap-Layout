import QtQuick
import org.kde.plasma.core as PlasmaCore

// Short message on the screen, e.g. the active mode or the new tiling layout.
PlasmaCore.Dialog {
    id: dlg
    property var app
    property string text: ""
    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.OnScreenDisplay
    backgroundHints: PlasmaCore.Types.NoBackground
    flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    outputOnly: true
    visible: false

    readonly property var ui: app ? app.ui : null

    Item {
        id: body
        width: Math.max(220, label.implicitWidth + 48)
        height: 56
        // A Dialog takes exactly one visual item; the timer lives in it.
        Timer { id: hideTimer; interval: 1400; onTriggered: dlg.visible = false }
        Rectangle {
            anchors.fill: parent
            radius: 12
            color: dlg.ui ? Qt.rgba(dlg.ui.window.r, dlg.ui.window.g, dlg.ui.window.b, 0.94) : "#202020"
            border.width: 1
            border.color: dlg.ui ? dlg.ui.line : "#40ffffff"
        }
        Text {
            id: label
            anchors.centerIn: parent
            text: dlg.text
            color: dlg.ui ? dlg.ui.text : "white"
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
    }
    readonly property int boxW: body.width
    readonly property int boxH: body.height
    function show(t, area) {
        text = t;
        x = Math.round(area.x + (area.width - boxW) / 2);
        y = Math.round(area.y + area.height * 0.72);
        visible = true;
        hideTimer.restart();
    }
}
