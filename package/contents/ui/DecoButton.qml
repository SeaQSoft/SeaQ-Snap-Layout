import QtQuick
import QtQuick.Controls
import "../code/i18n.js" as I

// Title bar button for the frameless fallback editor window (normally KWin
// draws the real decoration). It tries to look like your decoration's button:
//   1. Aurorae themes (SVG based decorations): the theme's
//      own button artwork is drawn, see AuroraeGlyph.qml
//   2. anything else (Breeze, Klassy, ...): icons from your icon theme
// Each step sits in its own Loader, so a missing QML module only drops us to
// the next fallback instead of breaking the whole window.
Item {
    id: btn

    property string kind: "X"          // M app icon, I minimize, A maximize, X close
    property var app
    signal activated()

    readonly property string tip: kind === "M" ? "" : kind === "X" ? I.tr("Close") : kind === "I" ? I.tr("Minimize")
                                 : (app.dlgMaximized ? I.tr("Restore") : I.tr("Maximize"))

    readonly property string auroraeFile: kind === "X" ? "close" : kind === "I" ? "minimize" : (app.dlgMaximized ? "restore" : "maximize")
    readonly property string iconName: kind === "X" ? "window-close" : kind === "I" ? "window-minimize"
                                     : (app.dlgMaximized ? "window-restore" : "window-maximize")

    readonly property bool useAurorae: kind !== "M" && app.auroraeName !== "" && aurorae.status === Loader.Ready && aurorae.item && aurorae.item.ok

    // same size the decoration gives its own buttons
    width: kind === "X" ? app.decoCloseW : (kind === "A" ? app.decoMaxW : app.decoButtonH)
    height: app.decoButtonH

    // menu button: the decoration shows the window icon there
    Image {
        visible: btn.kind === "M"
        anchors.centerIn: parent
        source: visible ? "../icons/snapmagic.png" : ""
        sourceSize: Qt.size(Math.round(btn.height * 0.8), Math.round(btn.height * 0.8))
    }

    Loader {
        id: aurorae
        anchors.fill: parent
        active: btn.kind !== "M" && btn.app.auroraeName !== ""
        source: "AuroraeGlyph.qml"
        visible: btn.useAurorae
        onStatusChanged: if (status === Loader.Error) console.warn("[kdesnaplayout] could not load the Aurorae button renderer (org.kde.ksvg missing?)")
        onLoaded: {
            item.themeName = Qt.binding(() => btn.app.auroraeName);
            item.file = Qt.binding(() => btn.auroraeFile);
            item.hovered = Qt.binding(() => ma.containsMouse);
            item.pressed = Qt.binding(() => ma.pressed);
        }
    }

    // icon-theme fallback with a round hover highlight, close turns red
    Rectangle {
        visible: btn.kind !== "M" && !btn.useAurorae
        anchors.centerIn: parent
        width: Math.min(btn.width, btn.height); height: width
        radius: width / 2
        color: ma.containsMouse ? (btn.kind === "X" ? "#da4453" : Qt.rgba(btn.app.ui.text.r, btn.app.ui.text.g, btn.app.ui.text.b, 0.15))
                                : "transparent"
        Loader {
            id: icon
            anchors.centerIn: parent
            source: "ThemeIcon.qml"
            onLoaded: {
                item.name = Qt.binding(() => btn.iconName);
                item.width = Qt.binding(() => Math.round(btn.height * 0.6));
                item.height = Qt.binding(() => Math.round(btn.height * 0.6));
            }
        }
        Label {
            // last resort if no icon component could be loaded
            anchors.centerIn: parent
            visible: icon.status !== Loader.Ready
            text: btn.kind === "X" ? "✕" : btn.kind === "I" ? "–" : "▢"
            color: btn.app.ui.text
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (btn.kind !== "M") btn.activated()
        onDoubleClicked: if (btn.kind === "M") btn.app.closeSettings()   // same as a real window
    }

    ToolTip.visible: ma.containsMouse && tip !== ""
    ToolTip.delay: 700
    ToolTip.text: tip
}
