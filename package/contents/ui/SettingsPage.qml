import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/layouts.js" as L
import "../code/i18n.js" as I

// Content of the settings editor window. Colors come from the system palette
// (app.ui); the snap bar's own colors (app.pal) are only used in previews.
Item {
    id: win

    required property var app
    // true:  frameless window, draws its own title bar and resize grips (used by main.qml)
    // false: content only, for a window that KWin decorates
    property bool framed: true
    readonly property var cfg: app.settings
    readonly property var ui: app.ui
    signal closeRequested()

    // same system colors for controls that use the Qt palette instead of Kirigami
    readonly property var sp: app.sysPalette
    palette.window: sp.window
    palette.windowText: sp.windowText
    palette.base: sp.base
    palette.alternateBase: sp.alternateBase
    palette.text: sp.text
    palette.button: sp.button
    palette.buttonText: sp.buttonText
    palette.highlight: sp.highlight
    palette.highlightedText: sp.highlightedText
    palette.placeholderText: Qt.rgba(sp.text.r, sp.text.g, sp.text.b, 0.5)
    palette.toolTipBase: sp.toolTipBase
    palette.toolTipText: sp.toolTipText
    palette.brightText: sp.brightText
    palette.mid: sp.mid
    palette.light: sp.light
    palette.dark: sp.dark

    LayoutMirroring.enabled: I.isRtl()
    LayoutMirroring.childrenInherit: true

    readonly property var swatches: ["#0078d4", "#4cc2ff", "#0099bc", "#00b294", "#10893e", "#ffb900",
                                     "#f7630c", "#e81123", "#e3008c", "#c239b3", "#8764b8", "#7a7574"]

    Rectangle {
        anchors.fill: parent
        color: win.ui.window
        radius: win.framed ? 10 : 0
        border.width: win.framed ? 1 : 0
        border.color: win.ui.line
    }

    // -------------------------------------------------------- building blocks
    component Card: Rectangle {
        id: card
        property string title: ""
        default property alias content: col.data
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 32
        radius: 10
        color: win.ui.card
        border.width: 1
        border.color: win.ui.line
        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14
            Label {
                visible: card.title !== ""
                text: card.title
                font.bold: true
                font.pointSize: Qt.application.font.pointSize + 1
            }
        }
    }

    component SettingRow: RowLayout {
        id: row
        property string text
        property string desc: ""
        default property alias control: holder.data
        Layout.fillWidth: true
        spacing: 16
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { text: row.text; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Label {
                text: row.desc
                visible: row.desc !== ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                font.pointSize: Math.max(7, Qt.application.font.pointSize - 1)
            }
        }
        RowLayout { id: holder; spacing: 8 }
    }

    component SliderRow: SettingRow {
        id: sr
        property real from: 0
        property real to: 100
        property real step: 1
        property real value: 0
        property string unit: ""
        signal moved(real v)
        Slider {
            id: sl
            implicitWidth: 230
            from: sr.from; to: sr.to; stepSize: sr.step
            snapMode: Slider.SnapAlways
            value: sr.value
            onMoved: sr.moved(value)
        }
        Label {
            text: Math.round(sl.value) + (sr.unit !== "" ? " " + sr.unit : "")
            Layout.minimumWidth: 66
            horizontalAlignment: Text.AlignRight
        }
    }

    component SwitchRow: SettingRow {
        id: swr
        property bool checked: false
        signal toggled(bool v)
        Switch { checked: swr.checked; onToggled: swr.toggled(checked) }
    }

    component PageTitle: ColumnLayout {
        id: pt
        property string title
        property string subtitle: ""
        Layout.fillWidth: true
        spacing: 4
        Label { text: pt.title; font.pointSize: Qt.application.font.pointSize + 8; font.bold: true }
        Label { text: pt.subtitle; visible: pt.subtitle !== ""; opacity: 0.7; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }

    // Sidebar entry. Not an ItemDelegate on purpose: Qt treats "&" in a
    // delegate's text as a keyboard mnemonic, which garbles "Behavior & Animation".
    component SideItem: Rectangle {
        id: si
        property string text
        property string iconName
        property bool current: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 6
        color: current ? win.ui.accent
                       : (siMouse.containsMouse ? Qt.rgba(win.ui.text.r, win.ui.text.g, win.ui.text.b, 0.08) : "transparent")
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            Loader {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: "ThemeIcon.qml"
                onLoaded: { item.name = Qt.binding(() => si.iconName); item.width = 18; item.height = 18; }
            }
            Label {
                Layout.fillWidth: true
                text: si.text
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: si.current ? win.ui.accentText : win.ui.text
            }
        }
        MouseArea { id: siMouse; anchors.fill: parent; hoverEnabled: true; onClicked: si.clicked() }
    }

    function lum(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }

    // turns "MHIAX" into what the fallback title bar can offer: M (app icon), A, X
    function decoButtons(s) {
        const out = [];
        for (const ch of String(s || "")) if ("MAX".indexOf(ch) >= 0 && out.indexOf(ch) < 0) out.push(ch);
        return out;
    }

    // ------------------------------------------------------------------ layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: win.framed ? 1 : 0
        spacing: 0

        // title bar of the frameless fallback: drag to move, double-click to maximize.
        // Height, button sizes, spacing, font and alignment come from the
        // active window decoration (see readMetrics in main.qml).
        Rectangle {
            id: titleBar
            visible: win.framed
            Layout.fillWidth: true
            Layout.preferredHeight: win.app.titleBarHeight
            color: win.ui.sidebar
            radius: 10
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 10; color: parent.color
            }

            MouseArea {
                anchors.fill: parent
                onPressed: win.app.beginWindowDrag()
                onPositionChanged: if (pressed) win.app.moveWindow()
                onReleased: win.app.endWindowDrag()
                onDoubleClicked: win.app.toggleMaximize()
            }

            Row {
                id: leftButtons
                x: win.app.decoEdgeLeft
                y: win.app.decoButtonTop
                spacing: win.app.decoSpacing
                Repeater {
                    model: win.decoButtons(win.app.buttonsLeft)
                    DecoButton {
                        required property string modelData
                        kind: modelData; app: win.app
                        onActivated: win.press(kind)
                    }
                }
            }

            Label {
                readonly property real leftEdge: leftButtons.x + leftButtons.width + win.app.titleGapLeft
                readonly property real rightEdge: titleBar.width - rightButtons.x + win.app.titleGapRight
                // centered titles use the full width, like KWin does
                readonly property real side: Math.max(leftEdge, rightEdge)
                anchors.fill: parent
                leftPadding: win.app.titleAlign === "center" ? side : leftEdge
                rightPadding: win.app.titleAlign === "center" ? side : rightEdge
                text: I.tr("KDE Snap Layout – Settings editor")
                font: win.app.titleFont
                // the theme's title color, unless it would be unreadable on our background
                readonly property real lumDiff: Math.abs(win.lum(win.app.titleColor) - win.lum(titleBar.color))
                color: win.app.titleColor.a > 0 && lumDiff > 0.4 ? win.app.titleColor : win.ui.text
                horizontalAlignment: win.app.titleAlign === "center" ? Text.AlignHCenter
                                   : (win.app.titleAlign === "right" ? Text.AlignRight : Text.AlignLeft)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Row {
                id: rightButtons
                x: titleBar.width - width - win.app.decoEdgeRight
                y: win.app.decoButtonTop
                spacing: win.app.decoSpacing
                Repeater {
                    model: win.decoButtons(win.app.buttonsRight)
                    DecoButton {
                        required property string modelData
                        kind: modelData; app: win.app
                        onActivated: win.press(kind)
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: win.ui.line; visible: win.framed }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ---------------------------------------------------------- sidebar
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: win.ui.sidebar
                radius: win.framed ? 10 : 0
                Rectangle { anchors.top: parent.top; anchors.right: parent.right; anchors.bottom: parent.bottom; width: 10; color: parent.color }
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 10; color: parent.color }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 10
                        Layout.bottomMargin: 14
                        Layout.topMargin: 6
                        Image {
                            source: "../icons/kdesnaplayout.svg"
                            sourceSize: Qt.size(40, 40)
                        }
                        ColumnLayout {
                            spacing: 0
                            Label { text: "KDE Snap Layout"; font.bold: true; font.pointSize: Qt.application.font.pointSize + 2 }
                            Label { text: I.tr("for KWin · v%1", win.app.version); opacity: 0.6 }
                        }
                    }

                    Repeater {
                        model: [
                            { t: I.tr("General"),              i: "preferences-system-windows" },
                            { t: I.tr("Appearance"),           i: "preferences-desktop-color" },
                            { t: I.tr("Behavior & Animation"), i: "preferences-desktop-animations" },
                            { t: I.tr("Layouts"),              i: "view-grid" },
                            { t: I.tr("About & Help"),         i: "help-about" }
                        ]
                        delegate: SideItem {
                            required property var modelData
                            required property int index
                            text: modelData.t
                            iconName: modelData.i
                            current: pages.currentIndex === index
                            onClicked: pages.currentIndex = index
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: activeRow.implicitHeight + 20
                        radius: 8
                        color: win.ui.card
                        border.width: 1
                        border.color: win.ui.line
                        RowLayout {
                            id: activeRow
                            anchors.fill: parent
                            anchors.margins: 10
                            Label { text: win.cfg.snapEnabled ? I.tr("Active") : I.tr("Paused"); Layout.fillWidth: true; font.bold: true }
                            Switch { checked: win.cfg.snapEnabled; onToggled: win.cfg.snapEnabled = checked }
                        }
                    }
                }
            }
            Rectangle { Layout.fillHeight: true; width: 1; color: win.ui.line }

            // ------------------------------------------------------------ pages
            StackLayout {
                id: pages
                objectName: "pages"
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                // ======================================================= general
                ScrollView {
                    id: sv0
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: sv0.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle {
                            title: I.tr("General")
                            subtitle: I.tr("Drag a window to the top edge of the screen and drop it onto a zone.")
                        }

                        Card {
                            title: I.tr("Snapping")
                            SwitchRow {
                                text: I.tr("Show the snap bar when dragging a window to the top edge")
                                checked: win.cfg.snapEnabled
                                onToggled: (v) => win.cfg.snapEnabled = v
                            }
                            SwitchRow {
                                text: I.tr("Preview where the window will land")
                                checked: win.cfg.showPreview
                                onToggled: (v) => win.cfg.showPreview = v
                            }
                            SwitchRow {
                                text: I.tr("Restore the original size when dragging a window out")
                                checked: win.cfg.restoreSize
                                onToggled: (v) => win.cfg.restoreSize = v
                            }
                        }

                        Card {
                            title: I.tr("Spacing")
                            SliderRow {
                                text: I.tr("Gap between windows")
                                from: 0; to: 48; unit: "px"
                                value: win.cfg.windowGap
                                onMoved: (v) => win.cfg.windowGap = v
                            }
                            SliderRow {
                                text: I.tr("Gap to the screen edge")
                                from: 0; to: 48; unit: "px"
                                value: win.cfg.edgeMargin
                                onMoved: (v) => win.cfg.edgeMargin = v
                            }
                        }

                        Card {
                            title: I.tr("Excluded applications")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                opacity: 0.7
                                text: I.tr("Window classes that never show the snap bar, one per line.")
                            }
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 90
                                TextArea {
                                    text: win.cfg.excludedApps
                                    placeholderText: "krita\nsteam"
                                    onTextChanged: if (text !== win.cfg.excludedApps) win.cfg.excludedApps = text
                                }
                            }
                        }

                        Card {
                            title: I.tr("Tip")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: I.tr("KDE maximizes windows that are dragged to the top edge. For smoother snapping, turn this off in System Settings → Screen Edges.")
                            }
                        }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            Button { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupGeneral) }
                        }
                        Item { implicitHeight: 16 }
                    }
                }

                // ==================================================== appearance
                ScrollView {
                    id: sv1
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: sv1.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle { title: I.tr("Appearance"); subtitle: I.tr("Colors, size and shape of the snap bar.") }

                        // Live preview. The bar is scaled down when it doesn't
                        // fit, so it is never cut off at the sides.
                        Rectangle {
                            id: stage
                            Layout.fillWidth: true
                            Layout.preferredHeight: demoHolder.height + 56
                            radius: 12
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.darker(win.app.pal.accent, 2.4) }
                                GradientStop { position: 1.0; color: Qt.darker(win.app.pal.accent, 1.4) }
                            }
                            Label {
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I.tr("Preview")
                                color: "white"
                                opacity: 0.75
                                font.pointSize: Math.max(7, Qt.application.font.pointSize - 1)
                            }
                            Item {
                                id: demoHolder
                                readonly property real fit: Math.min(1, (stage.width - 40) / Math.max(1, demoBar.fullW))
                                width: demoBar.fullW * fit
                                height: demoBar.fullH * fit
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 34
                                SnapBar {
                                    id: demoBar
                                    width: fullW
                                    height: fullH
                                    scale: demoHolder.fit
                                    transformOrigin: Item.TopLeft
                                    layouts: win.app.barLayouts
                                    theme: win.app.pal
                                    uiScale: win.cfg.barScale / 100
                                    thumbW: win.cfg.thumbWidth
                                    aspect: win.app.screenAspect
                                    perRow: win.cfg.perRow
                                    cornerR: win.cfg.cornerRadius
                                    bgOpacity: win.cfg.barOpacity / 100
                                    showName: win.cfg.showLayoutName
                                    expanded: true
                                    hoverLayout: demoCycle.li
                                    hoverZone: demoCycle.zi
                                }
                            }
                            Timer {
                                id: demoCycle
                                property int li: 0
                                property int zi: 0
                                interval: 900
                                repeat: true
                                running: win.visible && pages.currentIndex === 1
                                onTriggered: {
                                    const ls = win.app.barLayouts;
                                    if (!ls.length) return;
                                    zi++;
                                    if (li >= ls.length || zi >= ls[li].zones.length) { zi = 0; li = (li + 1) % ls.length; }
                                }
                            }
                        }

                        Card {
                            title: I.tr("Color scheme")
                            ButtonGroup { id: themeGroup }
                            Flow {
                                Layout.fillWidth: true
                                spacing: 18
                                RadioButton {
                                    text: I.tr("System")
                                    ButtonGroup.group: themeGroup
                                    checked: win.cfg.themeMode === 0
                                    onClicked: win.cfg.themeMode = 0
                                }
                                RadioButton {
                                    text: I.tr("Light")
                                    ButtonGroup.group: themeGroup
                                    checked: win.cfg.themeMode === 1
                                    onClicked: win.cfg.themeMode = 1
                                }
                                RadioButton {
                                    text: I.tr("Dark")
                                    ButtonGroup.group: themeGroup
                                    checked: win.cfg.themeMode === 2
                                    onClicked: win.cfg.themeMode = 2
                                }
                            }
                        }

                        Card {
                            title: I.tr("Accent color")
                            SwitchRow {
                                text: I.tr("Use the system accent color")
                                checked: win.cfg.useSystemAccent
                                onToggled: (v) => win.cfg.useSystemAccent = v
                            }
                            Flow {
                                id: swatchFlow
                                property bool pickerOpen: false
                                readonly property bool isCustom: win.swatches.indexOf(win.cfg.customAccent.toLowerCase()) < 0
                                Layout.fillWidth: true
                                spacing: 10
                                enabled: !win.cfg.useSystemAccent
                                opacity: enabled ? 1 : 0.4
                                Repeater {
                                    model: win.swatches
                                    delegate: Rectangle {
                                        required property string modelData
                                        readonly property bool sel: win.cfg.customAccent.toLowerCase() === modelData
                                        width: 30; height: 30; radius: 15
                                        color: modelData
                                        border.width: sel ? 3 : 1
                                        border.color: sel ? win.ui.text : win.ui.line
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { win.cfg.customAccent = parent.modelData; swatchFlow.pickerOpen = false; }
                                        }
                                    }
                                }
                                // rainbow circle: opens the free color picker
                                Item {
                                    id: rainbowSwatch
                                    width: 30; height: 30
                                    Canvas {
                                        anchors.fill: parent
                                        onPaint: {
                                            const c = getContext("2d");
                                            c.reset();
                                            const g = c.createConicalGradient(width / 2, height / 2, 0);
                                            const stops = ["#ff0000", "#ff00ff", "#0000ff", "#00ffff", "#00ff00", "#ffff00", "#ff0000"];
                                            for (let i = 0; i < stops.length; i++) g.addColorStop(i / (stops.length - 1), stops[i]);
                                            c.beginPath();
                                            c.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2);
                                            c.fillStyle = g;
                                            c.fill();
                                        }
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 14; height: 14; radius: 7
                                        visible: swatchFlow.isCustom
                                        color: win.cfg.customAccent
                                        border.width: 2
                                        border.color: "white"
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 15
                                        color: "transparent"
                                        border.width: swatchFlow.isCustom || swatchFlow.pickerOpen ? 3 : 0
                                        border.color: win.ui.text
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: swatchFlow.pickerOpen = !swatchFlow.pickerOpen
                                    }
                                    HoverHandler { id: rainbowHover }
                                    ToolTip.visible: rainbowHover.hovered
                                    ToolTip.text: I.tr("Custom color")
                                }
                            }
                            ColorPicker {
                                id: colorPicker
                                visible: swatchFlow.pickerOpen && !win.cfg.useSystemAccent
                                Layout.fillWidth: true
                                value: win.cfg.customAccent
                                lineColor: win.ui.line
                                onPicked: (c) => win.cfg.customAccent = colorPicker.hex(c)
                            }
                        }

                        Card {
                            title: I.tr("Size & shape")
                            SliderRow {
                                text: I.tr("Snap bar size")
                                from: 60; to: 200; step: 5; unit: "%"
                                value: win.cfg.barScale
                                onMoved: (v) => win.cfg.barScale = v
                            }
                            SliderRow {
                                text: I.tr("Thumbnail width")
                                from: 48; to: 160; step: 2; unit: "px"
                                value: win.cfg.thumbWidth
                                onMoved: (v) => win.cfg.thumbWidth = v
                            }
                            SliderRow {
                                text: I.tr("Corner radius")
                                from: 0; to: 24; unit: "px"
                                value: win.cfg.cornerRadius
                                onMoved: (v) => win.cfg.cornerRadius = v
                            }
                            SliderRow {
                                text: I.tr("Background opacity")
                                from: 40; to: 100; unit: "%"
                                value: win.cfg.barOpacity
                                onMoved: (v) => win.cfg.barOpacity = v
                            }
                            SettingRow {
                                text: I.tr("Layouts per row")
                                desc: I.tr("0 = all in one row")
                                SpinBox {
                                    from: 0; to: 12
                                    value: win.cfg.perRow
                                    onValueModified: win.cfg.perRow = value
                                }
                            }
                            SwitchRow {
                                text: I.tr("Show layout and zone names")
                                checked: win.cfg.showLayoutName
                                onToggled: (v) => win.cfg.showLayoutName = v
                            }
                        }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            Button { text: I.tr("Test on screen"); icon.name: "media-playback-start"; onClicked: win.app.demoBar() }
                            Button { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupAppearance) }
                        }
                        Item { implicitHeight: 16 }
                    }
                }

                // ================================================ behavior
                ScrollView {
                    id: sv2
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: sv2.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle {
                            title: I.tr("Behavior & Animation")
                            subtitle: I.tr("The default values are based on Windows 11.")
                        }

                        Card {
                            title: I.tr("Showing")
                            SliderRow {
                                text: I.tr("Trigger distance from the top edge")
                                from: 2; to: 200; unit: "px"
                                value: win.cfg.triggerDistance
                                onMoved: (v) => win.cfg.triggerDistance = v
                            }
                            SwitchRow {
                                text: I.tr("Show a small handle first")
                                checked: win.cfg.twoStage
                                onToggled: (v) => win.cfg.twoStage = v
                            }
                            SliderRow {
                                enabled: win.cfg.twoStage
                                opacity: enabled ? 1 : 0.45
                                text: I.tr("Distance at which the handle appears")
                                from: 20; to: 400; step: 5; unit: "px"
                                value: win.cfg.peekDistance
                                onMoved: (v) => win.cfg.peekDistance = v
                            }
                            SliderRow {
                                text: I.tr("Active width along the top edge")
                                from: 10; to: 100; step: 5; unit: "%"
                                value: win.cfg.activationWidth
                                onMoved: (v) => win.cfg.activationWidth = v
                            }
                            SliderRow {
                                text: I.tr("Delay before showing")
                                from: 0; to: 600; step: 10; unit: "ms"
                                value: win.cfg.showDelay
                                onMoved: (v) => win.cfg.showDelay = v
                            }
                        }

                        Card {
                            title: I.tr("Hiding")
                            SliderRow {
                                text: I.tr("Distance before the bar hides again")
                                from: 0; to: 300; step: 2; unit: "px"
                                value: win.cfg.hideMargin
                                onMoved: (v) => win.cfg.hideMargin = v
                            }
                            SliderRow {
                                text: I.tr("Delay before hiding")
                                from: 0; to: 1000; step: 10; unit: "ms"
                                value: win.cfg.hideDelay
                                onMoved: (v) => win.cfg.hideDelay = v
                            }
                        }

                        Card {
                            title: I.tr("Animation")
                            SliderRow {
                                text: I.tr("How far the bar slides down")
                                from: 0; to: 150; unit: "px"
                                value: win.cfg.slideDistance
                                onMoved: (v) => win.cfg.slideDistance = v
                            }
                            SliderRow {
                                text: I.tr("Slide-in duration")
                                from: 0; to: 1000; step: 10; unit: "ms"
                                value: win.cfg.slideInDuration
                                onMoved: (v) => win.cfg.slideInDuration = v
                            }
                            SliderRow {
                                text: I.tr("Slide-out duration")
                                from: 0; to: 1000; step: 10; unit: "ms"
                                value: win.cfg.slideOutDuration
                                onMoved: (v) => win.cfg.slideOutDuration = v
                            }
                            SettingRow {
                                text: I.tr("Motion curve")
                                ComboBox {
                                    implicitWidth: 230
                                    model: [I.tr("Smooth (default)"), I.tr("Quick"), I.tr("Bouncy"),
                                            I.tr("Dynamic"), I.tr("Soft"), I.tr("Linear")]
                                    currentIndex: win.cfg.easingStyle
                                    onActivated: (i) => win.cfg.easingStyle = i
                                }
                            }
                            SwitchRow {
                                text: I.tr("Fade in and out")
                                checked: win.cfg.fadeEnabled
                                onToggled: (v) => win.cfg.fadeEnabled = v
                            }
                        }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            Button { text: I.tr("Test animation"); icon.name: "media-playback-start"; onClicked: win.app.demoBar() }
                            Button { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupBehavior) }
                        }
                        Item { implicitHeight: 16 }
                    }
                }

                // ================================================== layouts
                ScrollView {
                    id: sv3
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        id: layoutsPage
                        x: 28
                        width: sv3.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle {
                            title: I.tr("Layouts")
                            subtitle: I.tr("Drag the cards to change the order in the snap bar. Double-click a card to edit it.")
                        }

                        RowLayout {
                            spacing: 8
                            Button { text: I.tr("New layout"); icon.name: "list-add"; highlighted: true; onClicked: win.newLayout() }
                            Item { Layout.fillWidth: true }
                            Button { text: I.tr("Restore default layouts"); icon.name: "edit-reset"; onClicked: win.askReset() }
                        }

                        GridView {
                            id: grid
                            Layout.fillWidth: true
                            Layout.preferredHeight: contentHeight + 8
                            interactive: false
                            cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 220)))
                            cellHeight: 196
                            model: win.app.layoutModel

                            moveDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
                            move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }

                            // Each cell is a drop target. Entering another cell
                            // moves the dragged card there right away; saving
                            // happens once on release.
                            delegate: DropArea {
                                id: cell
                                required property int index
                                required property string name
                                required property bool shown
                                required property string tree
                                width: grid.cellWidth
                                height: grid.cellHeight

                                onEntered: function (drag) {
                                    const from = drag.source.cellIndex;
                                    if (from !== undefined && from !== cell.index && from >= 0)
                                        win.app.layoutModel.move(from, cell.index, 1);
                                }

                                Rectangle {
                                    id: card
                                    property int cellIndex: cell.index
                                    width: grid.cellWidth - 14
                                    height: grid.cellHeight - 14
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 12
                                    color: dragArea.drag.active ? Qt.tint(win.ui.card, Qt.rgba(win.ui.accent.r, win.ui.accent.g, win.ui.accent.b, 0.15)) : win.ui.card
                                    border.width: dragArea.drag.active ? 2 : 1
                                    border.color: dragArea.drag.active ? win.ui.accent : win.ui.line
                                    opacity: cell.shown ? 1 : 0.55
                                    scale: dragArea.drag.active ? 1.04 : 1
                                    Behavior on scale { NumberAnimation { duration: 120 } }

                                    Drag.active: dragArea.drag.active
                                    Drag.source: card
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2

                                    states: State {
                                        when: dragArea.drag.active
                                        ParentChange { target: card; parent: grid }
                                        AnchorChanges { target: card; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
                                        PropertyChanges { target: card; z: 100 }
                                    }

                                    MouseArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        drag.target: card
                                        drag.threshold: 4
                                        preventStealing: true
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                        onReleased: { card.Drag.drop(); win.app.saveLayouts(); }
                                        onDoubleClicked: win.editLayout(cell.index)
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        LayoutPreview {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 92
                                            treeJson: cell.tree
                                            aspect: win.app.screenAspect
                                            zoneColor: win.ui.zone
                                            borderColor: win.ui.zoneBorder
                                            frameColor: win.ui.window
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label { text: "⠿"; opacity: 0.45 }
                                            Label { text: I.layoutName(cell.name); Layout.fillWidth: true; elide: Text.ElideRight; font.bold: true }
                                            Label { text: (cell.index + 1); opacity: 0.45 }
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            CheckBox {
                                                text: I.tr("In bar")
                                                checked: cell.shown
                                                onToggled: { win.app.layoutModel.setProperty(cell.index, "shown", checked); win.app.saveLayouts(); }
                                            }
                                            Item { Layout.fillWidth: true }
                                            ToolButton {
                                                icon.name: "document-edit"
                                                ToolTip.visible: hovered; ToolTip.text: I.tr("Edit")
                                                onClicked: win.editLayout(cell.index)
                                            }
                                            ToolButton {
                                                icon.name: "edit-copy"
                                                ToolTip.visible: hovered; ToolTip.text: I.tr("Duplicate")
                                                onClicked: win.duplicateLayout(cell.index)
                                            }
                                            ToolButton {
                                                icon.name: "edit-delete"
                                                enabled: win.app.layoutModel.count > 1
                                                ToolTip.visible: hovered; ToolTip.text: I.tr("Delete")
                                                onClicked: win.askDelete(cell.index)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Item { implicitHeight: 16 }
                    }
                }

                // ==================================================== about
                ScrollView {
                    id: sv4
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: sv4.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle { title: I.tr("About & Help") }
                        Card {
                            title: I.tr("How it works")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: I.tr("Grab a window by its title bar and drag it up. The snap bar slides down; drop the window onto a zone and it fills exactly that area. Drag it away again and it gets its old size back.")
                            }
                        }
                        Card {
                            title: I.tr("Opening the settings editor")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: I.tr("System Settings → Window Management → KWin Scripts → gear icon next to “KDE Snap Layout” → “Open Snap Layout settings editor” → OK.")
                            }
                        }
                        Card {
                            title: I.tr("Information")
                            GridLayout {
                                columns: 2
                                columnSpacing: 16
                                rowSpacing: 6
                                Label { text: I.tr("Version"); opacity: 0.7 }
                                Label { text: win.app.version }
                                Label { text: I.tr("Author"); opacity: 0.7 }
                                Label { text: win.app.author }
                                Label { text: I.tr("License"); opacity: 0.7 }
                                Label { text: "GPL-3.0-or-later" }
                                Label { text: I.tr("Settings file"); opacity: 0.7 }
                                Label { text: "~/.config/kde-snaplayout.ini" }
                            }
                        }
                        Item { implicitHeight: 16 }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------- window buttons
    function press(kind) {
        if (kind === "X") closeRequested();
        else if (kind === "A") app.toggleMaximize();
    }

    // ----------------------------------------------------------- resize grips
    component Grip: MouseArea {
        property int mode: 0     // 1 width, 2 height, 3 both
        z: 40
        visible: win.framed && !win.app.dlgMaximized
        onPressed: win.app.beginWindowDrag()
        onPositionChanged: if (pressed) win.app.resizeWindow(mode)
        onReleased: win.app.endWindowDrag()
    }
    Grip { mode: 1; width: 6; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.topMargin: win.app.titleBarHeight; anchors.bottomMargin: 18; cursorShape: Qt.SizeHorCursor }
    Grip { mode: 2; height: 6; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: 18; cursorShape: Qt.SizeVerCursor }
    Grip {
        mode: 3; width: 18; height: 18
        anchors.right: parent.right; anchors.bottom: parent.bottom
        cursorShape: Qt.SizeFDiagCursor
    }

    // ------------------------------------------------------- layout actions
    function editLayout(i) {
        const o = app.layoutModel.get(i);
        editorPopup.editIndex = i;
        editorPopup.isNew = false;
        editorPopup.originalName = o.name;
        nameField.text = I.layoutName(o.name);
        editor.tree = L.parseTree(o.tree);
        editor.selected = L.firstZonePath(editor.tree);
        editorPopup.open();
    }
    function newLayout() {
        editorPopup.editIndex = -1;
        editorPopup.isNew = true;
        editorPopup.originalName = "";
        nameField.text = I.tr("Custom layout %1", app.layoutModel.count + 1);
        editor.tree = L.split("v", 0.5, L.leaf(), L.leaf());
        editor.selected = L.firstZonePath(editor.tree);
        editorPopup.open();
    }
    function saveEditor() {
        const t = JSON.stringify(editor.tree);
        let n = nameField.text.trim() || "Layout";
        // an untouched built-in name stays translatable
        if (editorPopup.originalName && n === I.layoutName(editorPopup.originalName)) n = editorPopup.originalName;
        if (editorPopup.editIndex < 0) {
            app.layoutModel.append({ name: n, shown: true, tree: t });
        } else {
            app.layoutModel.setProperty(editorPopup.editIndex, "name", n);
            app.layoutModel.setProperty(editorPopup.editIndex, "tree", t);
        }
        app.saveLayouts();
        editorPopup.close();
    }
    function duplicateLayout(i) {
        const o = app.layoutModel.get(i);
        app.layoutModel.insert(i + 1, { name: I.tr("%1 (copy)", I.layoutName(o.name)), shown: o.shown, tree: o.tree });
        app.saveLayouts();
    }
    function askDelete(i) {
        if (i < 0 || i >= app.layoutModel.count || app.layoutModel.count <= 1) return;
        confirm.ask(I.tr("Delete layout?"), I.tr("“%1” will be removed.", I.layoutName(app.layoutModel.get(i).name)), function () {
            if (i < app.layoutModel.count && app.layoutModel.count > 1) {
                app.layoutModel.remove(i);
                app.saveLayouts();
            }
        });
    }
    function askReset() {
        confirm.ask(I.tr("Restore default layouts?"), I.tr("Your own layouts and their order will be lost."),
                    function () { app.resetLayouts(); });
    }

    // --------------------------------------------- overlays inside the window
    // No Qt Popups here: inside a KWin-created window they end up misplaced
    // or cut off at the window border.
    component Shade: Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        radius: win.framed ? 10 : 0
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons; onWheel: (w) => w.accepted = true }
    }

    Item {
        id: editorPopup
        property int editIndex: -1
        property bool isNew: false
        property string originalName: ""
        anchors.fill: parent
        anchors.topMargin: win.framed ? win.app.titleBarHeight + 1 : 0
        visible: false
        z: 50
        function open() { visible = true; }
        function close() { visible = false; }

        Shade {}
        Rectangle {
            anchors.fill: parent
            anchors.margins: 18
            radius: 14
            color: win.ui.window
            border.width: 1
            border.color: win.ui.line

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Label {
                        text: editorPopup.isNew ? I.tr("New layout") : I.tr("Edit layout")
                        font.bold: true
                        font.pointSize: Qt.application.font.pointSize + 4
                    }
                    Item { Layout.fillWidth: true }
                    Label { text: I.tr("Name:") }
                    TextField { id: nameField; Layout.preferredWidth: 240; selectByMouse: true }
                }
                LayoutEditor {
                    id: editor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 120
                    snapping: win.cfg.editorSnapping
                    aspect: win.app.screenAspect
                    accent: win.ui.accent
                    accentText: win.ui.accentText
                    zoneColor: win.ui.zone
                    fg: win.ui.text
                    lineColor: win.ui.line
                    stageColor: win.ui.card
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    CheckBox {
                        text: I.tr("Snap dividers (¼, ⅓, ½ …)")
                        checked: win.cfg.editorSnapping
                        onToggled: win.cfg.editorSnapping = checked
                    }
                    Item { Layout.fillWidth: true }
                    Button { text: I.tr("Cancel"); onClicked: editorPopup.close() }
                    Button { text: I.tr("Save"); highlighted: true; icon.name: "document-save"; onClicked: win.saveEditor() }
                }
            }
        }
    }

    Item {
        id: confirm
        property string title: ""
        property string message: ""
        property var action: null
        anchors.fill: parent
        anchors.topMargin: win.framed ? win.app.titleBarHeight + 1 : 0
        visible: false
        z: 60
        function ask(t, m, a) { title = t; message = m; action = a; visible = true; }

        Shade {}
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 420)
            height: cCol.implicitHeight + 40
            radius: 12
            color: win.ui.window
            border.width: 1
            border.color: win.ui.line
            ColumnLayout {
                id: cCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Label { text: confirm.title; font.bold: true; font.pointSize: Qt.application.font.pointSize + 2 }
                Label { text: confirm.message; wrapMode: Text.WordWrap; Layout.fillWidth: true; opacity: 0.8 }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button { text: I.tr("Cancel"); onClicked: confirm.visible = false }
                    Button {
                        text: I.tr("Yes"); highlighted: true
                        onClicked: { confirm.visible = false; if (confirm.action) confirm.action(); }
                    }
                }
            }
        }
    }
}
