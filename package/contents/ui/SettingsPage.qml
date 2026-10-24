import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/layouts.js" as L
import "../code/i18n.js" as I
import "../code/keys.js" as K

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
        AccentSlider {
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
        AccentSwitch { checked: swr.checked; onToggled: swr.toggled(checked) }
    }

    // a feature with its switch and a link to its page
    component FeatureRow: SettingRow {
        id: fr
        property int page: 0
        property string key
        ToolButton {
            icon.name: "go-next"
            display: AbstractButton.IconOnly
            text: I.tr("Settings")
            ToolTip.visible: hovered; ToolTip.text: text
            onClicked: pages.currentIndex = fr.page
        }
        AccentSwitch { checked: win.cfg[fr.key]; onToggled: win.cfg[fr.key] = checked }
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

    // A small monitor used by the illustrations. Children go onto its screen.
    component Monitor: Rectangle {
        id: mon
        default property alias content: screenArea.data
        property real screenW: Math.min(width - 48, (height - 54) * 16 / 10)
        property real screenH: screenW * 10 / 16
        property alias screen: screenArea
        Layout.fillWidth: true
        implicitHeight: 250
        radius: 10
        color: Qt.rgba(win.ui.text.r, win.ui.text.g, win.ui.text.b, 0.04)
        border.width: 1
        border.color: win.ui.line
        Rectangle {          // bezel
            id: bezel
            width: mon.screenW + 14; height: mon.screenH + 14
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            radius: 9
            color: "#1b1e23"
            border.width: 1; border.color: "#3a3f47"
            Rectangle {      // screen
                id: screenArea
                x: 7; y: 7; width: mon.screenW; height: mon.screenH
                radius: 4
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.darker(win.ui.accent, 2.6) }
                    GradientStop { position: 1.0; color: Qt.darker(win.ui.accent, 1.7) }
                }
            }
        }
        Rectangle {          // neck
            width: 26; height: 12
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: bezel.bottom
            color: "#2a2e35"
        }
        Rectangle {          // foot
            width: 96; height: 6; radius: 3
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: bezel.bottom; anchors.topMargin: 12
            color: "#2a2e35"
        }
    }

    // One zone on the monitor drawing.
    component ZoneTile: Rectangle {
        id: zt
        property string label
        property bool on: true
        radius: 5
        color: on ? Qt.rgba(win.ui.accent.r, win.ui.accent.g, win.ui.accent.b, 0.32) : Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: on ? Qt.lighter(win.ui.accent, 1.5) : Qt.rgba(1, 1, 1, 0.18)
        Label {
            anchors.centerIn: parent
            width: parent.width - 8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: zt.label
            color: "white"
            opacity: zt.on ? 0.95 : 0.35
            font.bold: true
            font.pointSize: Math.max(7, Qt.application.font.pointSize - 1)
        }
    }

    // A tiny window with a title bar.
    component MiniWindow: Rectangle {
        property real shade: 0.92
        radius: 4
        color: Qt.rgba(1, 1, 1, shade)
        Rectangle { width: parent.width; height: 12; radius: 4; color: Qt.rgba(0, 0, 0, 0.45)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 4; color: parent.color } }
    }

    // Support buttons in the colors of the services (PayPal blue, coffee yellow).
    component DonateButton: Rectangle {
        id: db
        property string label
        property string sub
        property string url
        property color fill
        property color ink: "white"
        property string glyph: ""
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 62
        radius: 12
        color: dbMa.pressed ? Qt.darker(fill, 1.15) : (dbMa.containsMouse ? Qt.lighter(fill, 1.08) : fill)
        scale: dbMa.pressed ? 0.98 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 90 } }
        Row {
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: db.glyph
                font.pixelSize: 24
                color: db.ink
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text { text: db.label; color: db.ink; font.pixelSize: 15; font.weight: Font.Bold }
                Text { text: db.sub; color: db.ink; opacity: 0.75; font.pixelSize: 11 }
            }
        }
        MouseArea {
            id: dbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(db.url)
        }
        Accessible.role: Accessible.Link
        Accessible.name: db.label
    }

    // A hint with a warning stripe, e.g. when KDE's own helper does the same job.
    component NoticeCard: Rectangle {
        id: nc
        property string text
        Layout.fillWidth: true
        implicitHeight: ncLabel.implicitHeight + 28
        radius: 10
        color: Qt.rgba(0.96, 0.6, 0.15, 0.12)
        border.width: 1
        border.color: Qt.rgba(0.96, 0.6, 0.15, 0.55)
        Rectangle { width: 4; radius: 2; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 8; color: "#f39c1f" }
        Label {
            id: ncLabel
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 22; anchors.rightMargin: 16
            wrapMode: Text.WordWrap
            text: nc.text
        }
    }

    // "Ctrl+Alt+Left" drawn as key caps
    component KeyChip: Row {
        id: kc
        property int code: 0
        spacing: 3
        Repeater {
            model: K.toText(kc.code).split("+").filter(function (p) { return p !== ""; })
            delegate: Rectangle {
                required property string modelData
                implicitWidth: Math.max(22, capLabel.implicitWidth + 12)
                implicitHeight: capLabel.implicitHeight + 6
                radius: 4
                color: win.ui.card
                border.width: 1
                border.color: Qt.rgba(win.ui.text.r, win.ui.text.g, win.ui.text.b, 0.3)
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 2; radius: 2; color: Qt.rgba(win.ui.text.r, win.ui.text.g, win.ui.text.b, 0.18) }
                Label { id: capLabel; anchors.centerIn: parent; text: parent.modelData; font.pointSize: Math.max(7, Qt.application.font.pointSize - 1) }
            }
        }
    }

    // One action on the Keyboard page: current keys, and when opened the usual
    // alternatives plus a builder for any other combination.
    component KeyRow: ColumnLayout {
        id: kr
        property var action
        readonly property bool editing: win.editingAction === action.id
        readonly property var codes: { win.app.shortcuts.revision; return win.app.shortcuts.keys[action.id] || []; }
        // the key this action gets from the chosen scheme
        readonly property int schemeCode: K.schemeKey(action, win.currentScheme())
        readonly property bool isDefault: kr.codes.length === (kr.schemeCode ? 1 : 0)
                                          && (kr.schemeCode === 0 || kr.codes[0] === kr.schemeCode)
        property int mods: 0
        Layout.fillWidth: true
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Label { text: I.tr(kr.action.text); Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Repeater { model: kr.codes; delegate: KeyChip { required property int modelData; code: modelData } }
            Label { visible: kr.codes.length === 0; text: I.tr("None"); opacity: 0.5 }
            ToolButton {
                icon.name: "edit-undo"
                display: AbstractButton.IconOnly
                text: I.tr("Reset to default")
                ToolTip.visible: hovered; ToolTip.text: text
                // keeps its space so the rows stay aligned
                opacity: kr.isDefault ? 0 : 1
                enabled: !kr.isDefault && win.app.shortcuts.available
                onClicked: win.resetKey(kr.action)
            }
            ToolButton {
                icon.name: kr.editing ? "dialog-close" : "document-edit"
                display: AbstractButton.IconOnly
                text: kr.editing ? I.tr("Close") : I.tr("Change")
                ToolTip.visible: hovered; ToolTip.text: text
                enabled: win.app.shortcuts.available
                onClicked: {
                    win.editingAction = kr.editing ? "" : kr.action.id;
                    const c = kr.codes.length ? kr.codes[0] : K.defaultKey(kr.action);
                    kr.mods = c ? K.modifiers(c) : (K.CTRL | K.ALT);
                    keyBox.currentIndex = Math.max(0, K.KEYS.findIndex(function (k) { return k[1] === K.baseKey(c); }));
                }
            }
        }
        Rectangle {
            visible: kr.editing
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            implicitHeight: edCol.implicitHeight + 32
            radius: 10
            color: Qt.rgba(win.ui.accent.r, win.ui.accent.g, win.ui.accent.b, 0.07)
            border.width: 1
            border.color: Qt.rgba(win.ui.accent.r, win.ui.accent.g, win.ui.accent.b, 0.45)
            ColumnLayout {
                id: edCol
                // everything wraps inside the panel, nothing may stick out
                x: 16; y: 16
                width: parent.width - 32
                spacing: 8
                Label { text: I.tr("Usual combinations"); font.bold: true; opacity: 0.8 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: K.suggestions(kr.action)
                        delegate: AccentButton {
                            required property int modelData
                            text: K.toText(modelData)
                            highlighted: kr.codes.indexOf(modelData) >= 0
                            onClicked: win.assignKey(kr.action, modelData)
                        }
                    }
                }
                Label { text: I.tr("Your own combination"); font.bold: true; opacity: 0.8; Layout.topMargin: 6 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [["Meta", K.META], ["Ctrl", K.CTRL], ["Alt", K.ALT], ["Shift", K.SHIFT]]
                        delegate: AccentButton {
                            required property var modelData
                            text: modelData[0]
                            checkable: true
                            checked: (kr.mods & modelData[1]) !== 0
                            onToggled: kr.mods = checked ? (kr.mods | modelData[1]) : (kr.mods & ~modelData[1])
                        }
                    }
                    Label { text: "+"; height: keyBox.height; verticalAlignment: Text.AlignVCenter; leftPadding: 2; rightPadding: 2 }
                    ComboBox {
                        id: keyBox
                        width: 130
                        model: K.KEYS.map(function (k) { return k[0]; })
                    }
                    AccentButton {
                        text: I.tr("Set")
                        icon.name: "dialog-ok-apply"
                        highlighted: true
                        enabled: kr.mods !== 0 || K.KEYS[keyBox.currentIndex][0].indexOf("F") === 0
                        onClicked: win.assignKey(kr.action, kr.mods | K.KEYS[keyBox.currentIndex][1])
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: win.ui.line }
                Flow {
                    Layout.fillWidth: true
                    layoutDirection: I.isRtl() ? Qt.LeftToRight : Qt.RightToLeft
                    spacing: 6
                    AccentButton {
                        text: I.tr("Close")
                        icon.name: "dialog-close"
                        onClicked: win.editingAction = ""
                    }
                    AccentButton {
                        text: I.tr("Remove")
                        icon.name: "edit-clear"
                        enabled: kr.codes.length > 0
                        onClicked: win.assignKey(kr.action, 0)
                    }
                    AccentButton {
                        text: I.tr("Reset to default")
                        icon.name: "edit-undo"
                        enabled: !kr.isDefault
                        onClicked: win.resetKey(kr.action)
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: win.ui.line; opacity: 0.6 }
    }

    // ------------------------------------------------------- keyboard logic
    property string editingAction: ""
    property var conflicts: []          // [{ action, code, owners }]

    Connections {
        target: win.app.shortcuts
        function onConflict(action, code, owners) {
            const rest = win.conflicts.filter(function (c) { return !(c.action === action && c.code === code); });
            rest.push({ action: action, code: code, owners: owners });
            win.conflicts = rest;
        }
    }

    function assignKey(action, code) {
        win.conflicts = win.conflicts.filter(function (c) { return c.action !== action.id; });
        app.shortcuts.assign(action.id, app.shortcutText(action), code);
        editingAction = "";
    }

    function applyScheme(scheme) {
        cfg.keyScheme = scheme.id;
        conflicts = [];
        for (let i = 0; i < K.ACTIONS.length; i++) {
            const a = K.ACTIONS[i];
            const code = K.schemeKey(a, scheme);
            // actions without a key in this scheme keep what they have,
            // "No shortcuts" clears everything
            if (code || scheme.id === "none") app.shortcuts.assign(a.id, app.shortcutText(a), code);
        }
    }

    function takeOver(c) {
        conflicts = conflicts.filter(function (x) { return x !== c; });
        const a = K.actionById(c.action);
        app.shortcuts.reassign(a.id, app.shortcutText(a), c.code, c.owners);
    }

    function currentScheme() {
        const i = K.SCHEMES.findIndex(function (x) { return x.id === cfg.keyScheme; });
        return K.SCHEMES[i >= 0 ? i : 0];
    }

    // back to the key of the chosen scheme (or no key, if the scheme has none)
    function resetKey(action) {
        assignKey(action, K.schemeKey(action, currentScheme()));
    }

    function resetAllKeys() {
        conflicts = [];
        editingAction = "";
        const sc = currentScheme();
        for (let i = 0; i < K.ACTIONS.length; i++) {
            const a = K.ACTIONS[i];
            app.shortcuts.assign(a.id, app.shortcutText(a), K.schemeKey(a, sc));
        }
    }

    function takeOverAll() {
        const list = conflicts.slice();
        for (let i = 0; i < list.length; i++) takeOver(list[i]);
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
                text: I.tr("SeaQ Snap Layout – Settings editor")
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
                Layout.preferredWidth: 270
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
                            Label { text: "SeaQ Snap Layout"; font.bold: true; font.pointSize: Qt.application.font.pointSize + 2 }
                            Label { text: I.tr("for KDE · v%1", win.app.version); opacity: 0.6 }
                        }
                    }

                    // the page list scrolls on its own when the window is low,
                    // so it never runs into the feature switches below
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: navCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ColumnLayout {
                            id: navCol
                            width: parent.width
                            spacing: 4
                            Repeater {
                                // h: section header shown above the entry
                                model: [
                                    { t: I.tr("General"),              i: "preferences-system-windows", p: 0, h: "" },
                                    { t: I.tr("Appearance"),           i: "preferences-desktop-color", p: 1, h: I.tr("Snap bar") },
                                    { t: I.tr("Behavior & Animation"), i: "preferences-desktop-animations", p: 2, h: "" },
                                    { t: I.tr("Layouts"),              i: "view-grid", p: 3, h: "" },
                                    { t: I.tr("Screen edges"),         i: "transform-move", p: 4, h: I.tr("More ways to snap") },
                                    { t: I.tr("Window magnet"),        i: "snap-bounding-box", p: 5, h: "" },
                                    { t: I.tr("Keyboard shortcuts"),   i: "preferences-desktop-keyboard-shortcut", p: 6, h: "" },
                                    { t: I.tr("About & Help"),         i: "help-about", p: 7, h: " " }
                                ]
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        visible: modelData.h !== ""
                                        text: modelData.h.trim()
                                        Layout.fillWidth: true
                                        Layout.topMargin: 14
                                        Layout.leftMargin: 10
                                        Layout.rightMargin: 6
                                        Layout.bottomMargin: 4
                                        wrapMode: Text.WordWrap
                                        lineHeight: 1.1
                                        opacity: 0.55
                                        font.bold: true
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 0.3
                                        font.pointSize: Math.max(7, Qt.application.font.pointSize - 1.5)
                                    }
                                    SideItem {
                                        text: modelData.t
                                        iconName: modelData.i
                                        current: pages.currentIndex === modelData.p
                                        onClicked: pages.currentIndex = modelData.p
                                    }
                                }
                            }
                        }
                    }

                    // every feature can be switched on its own, right from here
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        implicitHeight: featCol.implicitHeight + 20
                        radius: 8
                        color: win.ui.card
                        border.width: 1
                        border.color: win.ui.line
                        ColumnLayout {
                            id: featCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6
                            Repeater {
                                model: [
                                    { t: I.tr("Snap bar"), k: "snapEnabled" },
                                    { t: I.tr("Screen edges"), k: "edgeEnabled" },
                                    { t: I.tr("Window magnet"), k: "magnetEnabled" },
                                    { t: I.tr("Shortcuts"), k: "keysEnabled" }
                                ]
                                // fixed row height: some styles draw their switch larger
                                // than its implicit size, rows must not overlap then
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.max(30, featSw.implicitHeight + 4)
                                    spacing: 8
                                    Label {
                                        text: modelData.t
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        elide: Text.ElideRight
                                        leftPadding: 4
                                    }
                                    AccentSwitch {
                                        id: featSw
                                        Layout.alignment: Qt.AlignVCenter
                                        checked: win.cfg[modelData.k]
                                        onToggled: win.cfg[modelData.k] = checked
                                    }
                                }
                            }
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
                            subtitle: I.tr("Four ways to snap windows. Each one can be switched on and off on its own.")
                        }

                        Card {
                            title: I.tr("Features")
                            FeatureRow {
                                text: I.tr("Snap bar"); page: 1; key: "snapEnabled"
                                desc: I.tr("Drag a window to the top edge of the screen and drop it onto a zone.")
                            }
                            FeatureRow {
                                text: I.tr("Screen edges"); page: 4; key: "edgeEnabled"
                                desc: I.tr("Push a window against an edge or corner: maximize, halves, quarters.")
                            }
                            FeatureRow {
                                text: I.tr("Window magnet"); page: 5; key: "magnetEnabled"
                                desc: I.tr("Windows stick to each other and to the screen edges.")
                            }
                            FeatureRow {
                                text: I.tr("Keyboard shortcuts"); page: 6; key: "keysEnabled"
                                desc: I.tr("Snap the active window with key combinations.")
                            }
                        }

                        Card {
                            title: I.tr("Previews")
                            SwitchRow {
                                text: I.tr("Snap bar preview")
                                desc: I.tr("Shows where the window lands while a zone of the snap bar is highlighted. Off: no preview at all.")
                                checked: win.cfg.showPreview
                                onToggled: (v) => win.cfg.showPreview = v
                            }
                            SwitchRow {
                                text: I.tr("Screen edges preview")
                                desc: I.tr("Shows where the window lands at an edge or corner. Off: no preview at all.")
                                checked: win.cfg.edgePreview
                                onToggled: (v) => win.cfg.edgePreview = v
                            }
                            SwitchRow {
                                text: I.tr("Show previews in the accent color")
                                desc: I.tr("Off: a neutral frame – only for the previews that are switched on.")
                                checked: win.cfg.previewAccent
                                onToggled: (v) => win.cfg.previewAccent = v
                            }
                            SwitchRow {
                                text: I.tr("Pause KDE's edge tiling and its preview")
                                desc: I.tr("Turn this off if you prefer KDE's own outline – then switch the screen edges preview above off.")
                                checked: win.cfg.kdeEdgesOff
                                onToggled: (v) => win.cfg.kdeEdgesOff = v
                            }
                        }

                        Card {
                            title: I.tr("Snapping")
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
                                text: I.tr("Window classes that are never snapped, one per line.")
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
                                text: I.tr("KDE has its own screen edge actions and window snapping. When the same feature is on here, turn KDE's off: System Settings → Window Management → Screen Edges, and Window Behavior → Movement.")
                            }
                        }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            AccentButton { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupGeneral) }
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
                            AccentButton { text: I.tr("Test on screen"); icon.name: "media-playback-start"; onClicked: win.app.demoBar() }
                            AccentButton { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupAppearance) }
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
                            AccentButton { text: I.tr("Test animation"); icon.name: "media-playback-start"; onClicked: win.app.demoBar() }
                            AccentButton { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupBehavior) }
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
                            AccentButton { text: I.tr("New layout"); icon.name: "list-add"; highlighted: true; onClicked: win.newLayout() }
                            Item { Layout.fillWidth: true }
                            AccentButton { text: I.tr("Restore default layouts"); icon.name: "edit-reset"; onClicked: win.askReset() }
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

                // ================================================== screen edges
                ScrollView {
                    id: svE
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: svE.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle {
                            title: I.tr("Screen edges")
                            subtitle: I.tr("Push a window against an edge or a corner of the screen and it fills that part. Works with or without the snap bar.")
                        }

                        // what each edge does, drawn on a small monitor
                        Monitor {
                            id: edgeMap
                            opacity: win.cfg.edgeEnabled ? 1 : 0.5
                            readonly property real g: 6                                  // gap between tiles
                            readonly property real sw: screenW
                            readonly property real sh: screenH
                            readonly property real cw: Math.max(sw * 0.15, sw * win.cfg.edgeCornerSize / 100)
                            readonly property real ch: Math.max(sh * 0.2, sh * win.cfg.edgeCornerSize / 100)
                            ZoneTile {   // top
                                x: edgeMap.cw + edgeMap.g; y: edgeMap.g
                                width: edgeMap.sw - 2 * edgeMap.cw - 2 * edgeMap.g; height: edgeMap.ch - edgeMap.g
                                on: win.cfg.edgeTop !== 3
                                label: [I.tr("Maximize"), I.tr("Fullscreen"), I.tr("Top half"), I.tr("Off")][Math.max(0, Math.min(3, win.cfg.edgeTop))]
                            }
                            ZoneTile {   // bottom
                                x: edgeMap.cw + edgeMap.g; y: edgeMap.sh - edgeMap.ch
                                width: edgeMap.sw - 2 * edgeMap.cw - 2 * edgeMap.g; height: edgeMap.ch - edgeMap.g
                                on: win.cfg.edgeBottom; label: I.tr("Bottom half")
                            }
                            ZoneTile {   // left
                                x: edgeMap.g; y: edgeMap.ch + edgeMap.g
                                width: edgeMap.cw - edgeMap.g; height: edgeMap.sh - 2 * edgeMap.ch - 2 * edgeMap.g
                                on: win.cfg.edgeSides; label: I.tr("Left half")
                            }
                            ZoneTile {   // right
                                x: edgeMap.sw - edgeMap.cw; y: edgeMap.ch + edgeMap.g
                                width: edgeMap.cw - edgeMap.g; height: edgeMap.sh - 2 * edgeMap.ch - 2 * edgeMap.g
                                on: win.cfg.edgeSides; label: I.tr("Right half")
                            }
                            Repeater {
                                model: 4
                                ZoneTile {
                                    required property int index
                                    width: edgeMap.cw - edgeMap.g; height: edgeMap.ch - edgeMap.g
                                    x: index % 2 === 0 ? edgeMap.g : edgeMap.sw - edgeMap.cw
                                    y: index < 2 ? edgeMap.g : edgeMap.sh - edgeMap.ch
                                    on: win.cfg.edgeCorners
                                    label: "¼"
                                }
                            }
                            MiniWindow {   // the window being pushed
                                width: edgeMap.sw * 0.26; height: edgeMap.sh * 0.3
                                x: (edgeMap.sw - width) / 2; y: (edgeMap.sh - height) / 2 + 4
                            }
                        }

                        Card {
                            title: I.tr("Edges and corners")
                            SwitchRow {
                                text: I.tr("Use screen edges")
                                desc: I.tr("Independent of the snap bar. Each edge can be switched on its own.")
                                checked: win.cfg.edgeEnabled
                                onToggled: (v) => win.cfg.edgeEnabled = v
                            }
                            SettingRow {
                                text: I.tr("Top edge")
                                enabled: win.cfg.edgeEnabled
                                ComboBox {
                                    implicitWidth: 230
                                    model: [I.tr("Maximize"), I.tr("Fullscreen"), I.tr("Top half"), I.tr("Off")]
                                    currentIndex: Math.max(0, Math.min(3, win.cfg.edgeTop))
                                    onActivated: (i) => win.cfg.edgeTop = i
                                }
                            }
                            SwitchRow {
                                text: I.tr("Left and right edge: half of the screen")
                                enabled: win.cfg.edgeEnabled
                                checked: win.cfg.edgeSides
                                onToggled: (v) => win.cfg.edgeSides = v
                            }
                            SwitchRow {
                                text: I.tr("Bottom edge: bottom half")
                                enabled: win.cfg.edgeEnabled
                                checked: win.cfg.edgeBottom
                                onToggled: (v) => win.cfg.edgeBottom = v
                            }
                            SwitchRow {
                                text: I.tr("Corners: quarter of the screen")
                                enabled: win.cfg.edgeEnabled
                                checked: win.cfg.edgeCorners
                                onToggled: (v) => win.cfg.edgeCorners = v
                            }
                        }

                        Card {
                            title: I.tr("Smart fill")
                            SwitchRow {
                                text: I.tr("Fit around windows that are already snapped")
                                desc: I.tr("If a window sits at the bottom, the top edge gives the top half instead of maximizing. Halves and quarters also leave snapped windows uncovered.")
                                enabled: win.cfg.edgeEnabled
                                checked: win.cfg.edgeSmart
                                onToggled: (v) => win.cfg.edgeSmart = v
                            }
                        }

                        Card {
                            title: I.tr("Feel")
                            SliderRow {
                                text: I.tr("Distance to the edge")
                                desc: I.tr("How close the cursor has to get to the edge.")
                                enabled: win.cfg.edgeEnabled
                                from: 1; to: 40; unit: "px"
                                value: win.cfg.edgeDistance
                                onMoved: (v) => win.cfg.edgeDistance = v
                            }
                            SliderRow {
                                text: I.tr("Push delay")
                                desc: I.tr("How long the window has to rest against the edge – a small push. 0 = at once.")
                                enabled: win.cfg.edgeEnabled
                                from: 0; to: 600; step: 10; unit: "ms"
                                value: win.cfg.edgeDelay
                                onMoved: (v) => win.cfg.edgeDelay = v
                            }
                            SliderRow {
                                text: I.tr("Corner size")
                                desc: I.tr("Part of each side that counts as corner.")
                                enabled: win.cfg.edgeEnabled && win.cfg.edgeCorners
                                from: 5; to: 40; unit: "%"
                                value: win.cfg.edgeCornerSize
                                onMoved: (v) => win.cfg.edgeCornerSize = v
                            }
                        }

                        Card {
                            title: I.tr("Hold to fill")
                            SwitchRow {
                                text: I.tr("Hold at the edge to fill the free space")
                                desc: I.tr("A short push gives the half or quarter. Keep the window at the edge a moment longer and it grows up to the next window – the preview shows it.")
                                enabled: win.cfg.edgeEnabled
                                checked: win.cfg.edgeFill
                                onToggled: (v) => win.cfg.edgeFill = v
                            }
                            SliderRow {
                                text: I.tr("Hold time")
                                desc: I.tr("How long the window has to stay at the edge before it grows.")
                                enabled: win.cfg.edgeEnabled && win.cfg.edgeFill
                                from: 200; to: 2000; step: 50; unit: "ms"
                                value: win.cfg.edgeFillDelay
                                onMoved: (v) => win.cfg.edgeFillDelay = v
                            }
                        }

                        Card {
                            title: I.tr("Preview")
                            SwitchRow {
                                text: I.tr("Screen edges preview")
                                desc: I.tr("Shows where the window lands at an edge or corner. Off: no preview at all.")
                                enabled: win.cfg.edgeEnabled
                                checked: win.cfg.edgePreview
                                onToggled: (v) => win.cfg.edgePreview = v
                            }
                            SwitchRow {
                                text: I.tr("Show previews in the accent color")
                                desc: I.tr("Off: a neutral frame – only for the previews that are switched on.")
                                checked: win.cfg.previewAccent
                                onToggled: (v) => win.cfg.previewAccent = v
                            }
                        }

                        Card {
                            title: I.tr("KDE's own edge tiling")
                            SwitchRow {
                                text: I.tr("Pause KDE's edge tiling and its preview")
                                desc: I.tr("KDE's own maximize and tile at the screen edges – with its outline – pause while SeaQ Snap Layout runs, so only one preview appears. Your KDE settings are not changed: switch this off, disable or remove SeaQ Snap Layout and KDE's own behavior is back.")
                                checked: win.cfg.kdeEdgesOff
                                onToggled: (v) => win.cfg.kdeEdgesOff = v
                            }
                        }

                        NoticeCard {
                            visible: win.cfg.edgeEnabled && !win.cfg.kdeEdgesOff && (win.app.kdeMaximizeTop || win.app.kdeQuickTile)
                            text: I.tr("KDE's own screen edge actions are still on, so two helpers react to the same drag. Turn off “Maximize” and “Tile” in System Settings → Window Management → Screen Edges.")
                        }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            AccentButton { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupEdges) }
                        }
                        Item { implicitHeight: 16 }
                    }
                }

                // ================================================== window magnet
                ScrollView {
                    id: svM
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: svM.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle {
                            title: I.tr("Window magnet")
                            subtitle: I.tr("While you move or resize a window, its edges stick to nearby windows and to the screen edges.")
                        }

                        // two windows sticking together, with the snap band between them
                        Monitor {
                            id: magMap
                            opacity: win.cfg.magnetEnabled ? 1 : 0.5
                            readonly property real band: Math.min(magMap.screenW * 0.12, Math.max(4, win.cfg.magnetDistance * 0.9))
                            MiniWindow {
                                id: wa
                                x: magMap.screenW * 0.1; y: magMap.screenH * 0.2
                                width: magMap.screenW * 0.36; height: magMap.screenH * 0.6
                            }
                            Rectangle {   // where the other window clicks into place
                                x: wa.x + wa.width; y: wa.y; width: magMap.band; height: wa.height
                                color: Qt.rgba(win.ui.accent.r, win.ui.accent.g, win.ui.accent.b, 0.45)
                                border.width: 1; border.color: Qt.lighter(win.ui.accent, 1.5)
                            }
                            MiniWindow {
                                id: wb
                                shade: 0.72
                                x: wa.x + wa.width + magMap.band * 0.6; y: wa.y + magMap.screenH * 0.08
                                width: magMap.screenW * 0.34; height: wa.height - magMap.screenH * 0.08
                                Label {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 6
                                    text: "⟵ " + win.cfg.magnetDistance + " px"
                                    color: "#1b1e23"; font.bold: true
                                }
                            }
                        }

                        Card {
                            title: I.tr("Magnet")
                            SwitchRow {
                                text: I.tr("Use the window magnet")
                                desc: I.tr("Independent of the snap bar and the screen edges.")
                                checked: win.cfg.magnetEnabled
                                onToggled: (v) => win.cfg.magnetEnabled = v
                            }
                            SliderRow {
                                text: I.tr("Snap distance")
                                desc: I.tr("How close an edge has to come before it clicks into place.")
                                enabled: win.cfg.magnetEnabled
                                from: 2; to: 64; unit: "px"
                                value: win.cfg.magnetDistance
                                onMoved: (v) => win.cfg.magnetDistance = v
                            }
                            SliderRow {
                                text: I.tr("Resistance against overlapping")
                                desc: I.tr("How far you have to push a window into another one before it lets go. 0 = windows can overlap freely.")
                                enabled: win.cfg.magnetEnabled
                                from: 0; to: 200; step: 4; unit: "px"
                                value: win.cfg.magnetResist
                                onMoved: (v) => win.cfg.magnetResist = v
                            }
                            SwitchRow {
                                text: I.tr("Stick to other windows")
                                enabled: win.cfg.magnetEnabled
                                checked: win.cfg.magnetWindows
                                onToggled: (v) => win.cfg.magnetWindows = v
                            }
                            SwitchRow {
                                text: I.tr("Stick to the screen edges")
                                enabled: win.cfg.magnetEnabled
                                checked: win.cfg.magnetScreen
                                onToggled: (v) => win.cfg.magnetScreen = v
                            }
                            SwitchRow {
                                text: I.tr("Also while resizing")
                                enabled: win.cfg.magnetEnabled
                                checked: win.cfg.magnetResize
                                onToggled: (v) => win.cfg.magnetResize = v
                            }
                            SwitchRow {
                                text: I.tr("Keep the gap between windows")
                                desc: I.tr("Windows stop at “Gap between windows” from the General page instead of touching.")
                                enabled: win.cfg.magnetEnabled && win.cfg.magnetWindows
                                checked: win.cfg.magnetGap
                                onToggled: (v) => win.cfg.magnetGap = v
                            }
                        }

                        Card {
                            title: I.tr("Sticky edges")
                            SwitchRow {
                                text: I.tr("Resize touching windows together")
                                desc: I.tr("When you resize a window, windows that touch it move their shared edge along – nothing overlaps, no gap opens.")
                                checked: win.cfg.stickyEnabled
                                onToggled: (v) => win.cfg.stickyEnabled = v
                            }
                            SwitchRow {
                                text: I.tr("Keep stacked windows in line")
                                desc: I.tr("Windows above each other keep their left and right edges together, windows side by side their top and bottom edges.")
                                enabled: win.cfg.stickyEnabled
                                checked: win.cfg.stickyAligned
                                onToggled: (v) => win.cfg.stickyAligned = v
                            }
                            SwitchRow {
                                text: I.tr("Shake to let go")
                                desc: I.tr("Shake the mouse while resizing and the other windows jump back.")
                                enabled: win.cfg.stickyEnabled
                                checked: win.cfg.stickyShake
                                onToggled: (v) => win.cfg.stickyShake = v
                            }
                            SwitchRow {
                                text: I.tr("Fade the other windows")
                                desc: I.tr("While resizing, windows that do not follow are shown transparent.")
                                enabled: win.cfg.stickyEnabled
                                checked: win.cfg.stickyDim
                                onToggled: (v) => win.cfg.stickyDim = v
                            }
                        }

                        Card {
                            title: I.tr("KDE's own window snapping")
                            SwitchRow {
                                text: I.tr("Pause KDE's snap zones while the magnet is on")
                                desc: I.tr("So only one magnet pulls at a window. Your KDE settings are not changed: switch this off, disable or remove SeaQ Snap Layout and KDE's own snapping is back.")
                                enabled: win.cfg.magnetEnabled
                                checked: win.cfg.kdeSnapOff
                                onToggled: (v) => win.cfg.kdeSnapOff = v
                            }
                        }

                        NoticeCard {
                            visible: win.cfg.magnetEnabled && !win.cfg.kdeSnapOff && (win.app.kdeWindowSnap > 0 || win.app.kdeBorderSnap > 0)
                            text: I.tr("KDE's own window snapping is on as well. For one consistent feel, set its snap zones to “None” in System Settings → Window Management → Window Behavior → Movement.")
                        }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            AccentButton { text: I.tr("Recommended values"); icon.name: "edit-undo"; onClicked: win.app.resetGroup(win.app.groupMagnet) }
                        }
                        Item { implicitHeight: 16 }
                    }
                }

                // ====================================================== keyboard
                ScrollView {
                    id: svK
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        x: 28
                        width: svK.availableWidth - 56
                        spacing: 16
                        Item { implicitHeight: 12 }
                        PageTitle {
                            title: I.tr("Keyboard shortcuts")
                            subtitle: I.tr("Snap the active window with the keyboard. These are normal KDE global shortcuts – you also find them in System Settings → Shortcuts → KWin.")
                        }

                        Card {
                            title: I.tr("Shortcuts")
                            SwitchRow {
                                text: I.tr("Use keyboard shortcuts")
                                desc: I.tr("Off: the keys stay assigned but do nothing.")
                                checked: win.cfg.keysEnabled
                                onToggled: (v) => win.cfg.keysEnabled = v
                            }
                            SettingRow {
                                text: I.tr("Key scheme")
                                desc: I.tr("Sets the keys of all actions at once. You can still change single keys below.")
                                ComboBox {
                                    id: schemeBox
                                    implicitWidth: 250
                                    textRole: "t"
                                    model: K.SCHEMES.map(function (s) { return { t: I.tr(s.text), id: s.id }; })
                                    currentIndex: Math.max(0, K.SCHEMES.findIndex(function (s) { return s.id === win.cfg.keyScheme; }))
                                }
                                AccentButton {
                                    text: I.tr("Apply")
                                    enabled: win.app.shortcuts.available
                                    onClicked: win.applyScheme(K.SCHEMES[schemeBox.currentIndex])
                                }
                            }
                            SettingRow {
                                text: I.tr("Reset all keys")
                                desc: I.tr("Gives every action the key of the chosen scheme again and removes keys the scheme does not have.")
                                AccentButton {
                                    text: I.tr("Reset all")
                                    icon.name: "edit-undo"
                                    enabled: win.app.shortcuts.available
                                    onClicked: win.resetAllKeys()
                                }
                            }
                            Label {
                                visible: !win.app.shortcuts.available
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                color: win.ui.negative
                                text: I.tr("KDE's shortcut service did not answer. You can still set the keys in System Settings → Shortcuts → KWin.")
                            }
                        }

                        // keys that another program already uses
                        Card {
                            visible: win.conflicts.length > 0
                            title: I.tr("Keys already in use")
                            Repeater {
                                model: win.conflicts
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Label {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: I.tr("%1 is used by “%2”.", K.toText(modelData.code),
                                                   modelData.owners.map(function (o) { return o.name + " (" + o.app + ")"; }).join(", ") || "?")
                                              + " " + I.tr("Wanted for: %1", I.tr(K.actionById(modelData.action).text))
                                    }
                                    AccentButton {
                                        text: I.tr("Take it over")
                                        onClicked: win.takeOver(modelData)
                                    }
                                }
                            }
                            RowLayout {
                                Item { Layout.fillWidth: true }
                                AccentButton { text: I.tr("Take over all"); visible: win.conflicts.length > 1; onClicked: win.takeOverAll() }
                                AccentButton { text: I.tr("Keep them"); onClicked: win.conflicts = [] }
                            }
                        }

                        Repeater {
                            model: K.GROUPS
                            delegate: Card {
                                id: groupCard
                                required property var modelData
                                title: I.tr(modelData.text)
                                Repeater {
                                    model: K.ACTIONS.filter(function (a) { return a.group === groupCard.modelData.id; })
                                    delegate: KeyRow { required property var modelData; action: modelData }
                                }
                            }
                        }

                        Card {
                            title: I.tr("Good to know")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: I.tr("The snapping actions use the same gaps as the snap bar and remember the size before snapping: “Restore the size before snapping” brings it back.")
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
                            title: I.tr("Support SeaQ Snap Layout")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                opacity: 0.8
                                text: I.tr("If you like SeaQ Snap Layout, you can support its development – thank you!")
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                DonateButton {
                                    label: I.tr("Donate with PayPal")
                                    sub: "paypal.me/SeaQSoft"
                                    url: "https://paypal.me/SeaQSoft"
                                    fill: "#0070ba"
                                    glyph: "♥"
                                }
                                DonateButton {
                                    label: I.tr("Buy me a coffee")
                                    sub: "buymeacoffee.com/seaq"
                                    url: "https://buymeacoffee.com/seaq"
                                    fill: "#ffdd00"
                                    ink: "#1d1d1f"
                                    glyph: "☕"
                                }
                            }
                        }
                        Card {
                            title: I.tr("How it works")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: I.tr("Grab a window by its title bar and drag it up. The snap bar slides down; drop the window onto a zone and it fills exactly that area. Drag it away again and it gets its old size back.")
                            }
                        }
                        Card {
                            title: I.tr("More ways to snap")
                            Repeater {
                                model: [
                                    [I.tr("Screen edges"), I.tr("Push a window against an edge or corner: maximize, halves, quarters.")],
                                    [I.tr("Window magnet"), I.tr("Windows stick to each other and to the screen edges.")],
                                    [I.tr("Keyboard shortcuts"), I.tr("Snap the active window with key combinations.")]
                                ]
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label { text: modelData[0]; font.bold: true }
                                    Label { text: modelData[1]; Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.8 }
                                }
                            }
                        }
                        Card {
                            title: I.tr("Opening the settings editor")
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: I.tr("System Settings → Window Management → KWin Scripts → gear icon next to “SeaQ Snap Layout” → “Open Snap Layout settings editor” → OK.")
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
                    AccentButton { text: I.tr("Cancel"); onClicked: editorPopup.close() }
                    AccentButton { text: I.tr("Save"); highlighted: true; icon.name: "document-save"; onClicked: win.saveEditor() }
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
                    AccentButton { text: I.tr("Cancel"); onClicked: confirm.visible = false }
                    AccentButton {
                        text: I.tr("Yes"); highlighted: true
                        onClicked: { confirm.visible = false; if (confirm.action) confirm.action(); }
                    }
                }
            }
        }
    }
}
