import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../code/i18n.js" as I
import "../code/tiling.js" as T

// Animated live preview for the settings pages: a small screen where the
// windows act out what the feature does (screen edges, magnet, tiling,
// swapping). Same look as the snap bar preview on the Appearance page.
// Every scene is a list of frames; a frame says where each window is, the
// cursor, the preview outline and a caption. The windows glide between them.
Rectangle {
    id: demo
    property var app
    property string kind: "edges"         // edges | magnet | tiling | swap
    property bool running: true
    property bool active: true            // feature switched on (else dimmed)
    readonly property var cfg: app ? app.settings : null

    Layout.fillWidth: true
    implicitHeight: 300
    radius: 12
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.darker(demo.app ? demo.app.pal.accent : "#3daee9", 2.4) }
        GradientStop { position: 1.0; color: Qt.darker(demo.app ? demo.app.pal.accent : "#3daee9", 1.4) }
    }

    Label {
        anchors.top: parent.top; anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: I.tr("Live preview")
        color: "white"; opacity: 0.75
        font.pointSize: Math.max(7, Qt.application.font.pointSize - 1)
    }

    // ------------------------------------------------------------ screen
    Rectangle {
        id: bezel
        readonly property real sw: Math.min(demo.width - 60, (demo.height - 92) * 16 / 9)
        width: sw + 14; height: sw * 9 / 16 + 14
        anchors.horizontalCenter: parent.horizontalCenter
        y: 32
        radius: 9
        color: "#15181d"
        opacity: demo.active ? 1 : 0.45
        Rectangle {
            id: scr
            x: 7; y: 7
            width: bezel.sw; height: bezel.sw * 9 / 16
            radius: 4
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.darker(demo.app ? demo.app.pal.accent : "#3daee9", 2.0) }
                GradientStop { position: 1.0; color: Qt.darker(demo.app ? demo.app.pal.accent : "#3daee9", 1.3) }
            }

            // where the window will land
            Rectangle {
                id: pv
                readonly property var now: demo.frame.pv || null
                property var r: null
                onNowChanged: if (now) r = now
                visible: opacity > 0.01
                opacity: now ? 1 : 0
                x: (r ? r[0] : 0.5) * scr.width; y: (r ? r[1] : 0.5) * scr.height
                width: (r ? r[2] : 0) * scr.width; height: (r ? r[3] : 0) * scr.height
                radius: 5
                color: Qt.rgba(1, 1, 1, 0.16)
                border.width: 2
                border.color: Qt.rgba(1, 1, 1, 0.75)
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Rectangle {            // the swap arrows
                    anchors.centerIn: parent
                    visible: !!demo.frame.swap
                    width: 30; height: 30; radius: 15
                    color: Qt.rgba(1, 1, 1, 0.9)
                    Label { anchors.centerIn: parent; text: "⇄"; color: "#1b1e23"; font.bold: true }
                }
            }

            // the windows
            Repeater {
                model: demo.names
                delegate: Rectangle {
                    id: mw
                    required property string modelData
                    required property int index
                    readonly property var cur: demo.frame.w ? demo.frame.w[modelData] : null
                    property var last: null
                    onCurChanged: if (cur) last = cur
                    // a closed window fades where it was
                    readonly property var r: cur || last
                    readonly property bool lifted: (demo.frame.lift || "") === modelData
                    z: lifted ? 10 : (demo.frame.top === modelData ? 5 : index)
                    opacity: cur ? 1 : 0
                    scale: cur ? 1 : 0.85
                    x: (r ? r[0] : 0.4) * scr.width
                    y: (r ? r[1] : 0.4) * scr.height
                    width: Math.max(6, (r ? r[2] : 0.2) * scr.width)
                    height: Math.max(6, (r ? r[3] : 0.2) * scr.height)
                    radius: 4
                    color: Qt.rgba(1, 1, 1, index === 0 ? 0.95 : 0.8)
                    border.width: lifted ? 2 : 0
                    border.color: demo.app ? demo.app.ui.accent : "#3daee9"
                    Behavior on x { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Rectangle {        // title bar
                        width: parent.width; height: Math.min(10, parent.height / 3); radius: 4
                        color: Qt.rgba(0, 0, 0, 0.5)
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 3; color: parent.color }
                    }
                    Label {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 4
                        text: mw.modelData
                        color: "#1b1e23"
                        font.bold: true
                        visible: parent.height > 22
                    }
                }
            }

            // a thin glowing line where two edges stick (magnet)
            Rectangle {
                property var l: demo.frame.glow || null
                visible: opacity > 0.01
                opacity: l ? 1 : 0
                x: (l ? l[0] : 0) * scr.width - 2; y: (l ? l[1] : 0) * scr.height
                width: 4; height: (l ? l[2] : 0) * scr.height
                radius: 2
                color: "white"
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on x { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                property var l: demo.frame.glowH || null
                visible: opacity > 0.01
                opacity: l ? 1 : 0
                x: (l ? l[0] : 0) * scr.width; y: (l ? l[1] : 0) * scr.height - 2
                height: 4; width: (l ? l[2] : 0) * scr.width
                radius: 2
                color: "white"
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on y { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
            }

            // the mouse pointer
            Canvas {
                id: cursor
                property var c: demo.frame.cur || null
                width: 14; height: 18
                z: 20
                visible: opacity > 0.01
                opacity: c ? 1 : 0
                x: (c ? c[0] : 0.5) * scr.width - 1; y: (c ? c[1] : 0.5) * scr.height - 1
                Behavior on x { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: demo.speed; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                onPaint: {
                    const g = getContext("2d");
                    g.reset();
                    g.beginPath();
                    g.moveTo(1, 1); g.lineTo(1, 15); g.lineTo(5, 11.5); g.lineTo(8, 17); g.lineTo(10.5, 16); g.lineTo(7.6, 10.4); g.lineTo(12.5, 10.4);
                    g.closePath();
                    g.fillStyle = "white"; g.fill();
                    g.lineWidth = 1.2; g.strokeStyle = "#111"; g.stroke();
                }
            }
        }
    }

    // caption under the screen
    Label {
        anchors.top: bezel.bottom; anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: demo.active ? (demo.frame.text || "") : I.tr("Switched off")
        color: "white"
        font.bold: true
    }

    // ------------------------------------------------------------ scenes
    property int speed: 480
    property var frames: []
    property var names: []
    property int step: 0
    readonly property var frame: frames.length ? frames[step % frames.length] : ({})

    function build() {
        const f = [];
        if (kind === "edges") {
            names = ["A"];
            const mid = [0.3, 0.3, 0.4, 0.42];
            const topAct = cfg ? cfg.edgeTop : 0;
            const topR = topAct === 2 ? [0, 0, 1, 0.5] : [0, 0, 1, 1];
            const topText = topAct === 1 ? I.tr("Top edge: full screen") : (topAct === 2 ? I.tr("Top edge: top half") : I.tr("Top edge: maximize"));
            f.push({ w: { A: mid }, cur: [0.5, 0.33], text: I.tr("Drag a window against an edge…") });
            f.push({ w: { A: [0.02, 0.3, 0.4, 0.42] }, lift: "A", cur: [0.01, 0.4], pv: [0, 0, 0.5, 1], text: I.tr("Left edge: left half") });
            f.push({ w: { A: [0, 0, 0.5, 1] }, cur: [0.12, 0.03], text: I.tr("Left edge: left half") });
            f.push({ w: { A: mid }, lift: "A", cur: [0.5, 0.33], text: I.tr("Drag a window against an edge…") });
            if (topAct !== 3) {
                f.push({ w: { A: [0.3, 0, 0.4, 0.42] }, lift: "A", cur: [0.5, 0.005], pv: topR, text: topText });
                f.push({ w: { A: topR }, cur: [0.5, 0.03], text: topText });
                f.push({ w: { A: mid }, lift: "A", cur: [0.5, 0.33], text: I.tr("Drag a window against an edge…") });
            }
            f.push({ w: { A: [0.58, 0.56, 0.4, 0.42] }, lift: "A", cur: [0.99, 0.99], pv: [0.5, 0.5, 0.5, 0.5], text: I.tr("Corner: a quarter") });
            f.push({ w: { A: [0.5, 0.5, 0.5, 0.5] }, cur: [0.75, 0.53], text: I.tr("Corner: a quarter") });
        } else if (kind === "magnet") {
            names = ["A", "B", "C"];
            const g = cfg && cfg.magnetGap ? 0.012 : 0;
            // the whole screen is used: B and C fill the right side,
            // A comes from the left and ends up filling the left side
            const aw = 0.34, ah = 0.55, ay = 0.2;
            const right = function (edge, split) {
                return { B: [edge + g, 0, 1 - edge - g, split - g / 2],
                         C: [edge + g, split + g / 2, 1 - edge - g, 1 - split - g / 2] };
            };
            const scene = function (a, edge, split) { const r = right(edge, split); return { A: a, B: r.B, C: r.C }; };
            const e0 = 0.5, s0 = 0.5;
            const full = function (edge) { return [0, 0, edge, 1]; };
            f.push({ w: scene([0.04, ay, aw, ah], e0, s0), cur: [0.21, ay + 0.02], text: I.tr("Move a window towards others…") });
            f.push({ w: scene([0.1, ay, aw, ah], e0, s0), lift: "A", cur: [0.27, ay + 0.02], text: I.tr("Move a window towards others…") });
            f.push({ w: scene([e0 - aw, ay, aw, ah], e0, s0), lift: "A", cur: [e0 - aw / 2, ay + 0.02], glow: [e0, ay, ah], text: I.tr("Close by, the edges stick together") });
            f.push({ w: scene(full(e0), e0, s0), cur: [0.01, 0.98], glow: [e0, 0, 1], text: I.tr("Resizing snaps too – here to the full height") });
            // sticky edges: one shared edge, all neighbours follow
            f.push({ w: scene(full(e0), e0, s0), cur: [e0, 0.4], glow: [e0, 0, 1], text: I.tr("Drag a shared edge…") });
            f.push({ w: scene(full(e0 + 0.14), e0 + 0.14, s0), cur: [e0 + 0.14, 0.4], glow: [e0 + 0.14, 0, 1], text: I.tr("…the neighbours grow and shrink with it") });
            f.push({ w: scene(full(e0 - 0.12), e0 - 0.12, s0), cur: [e0 - 0.12, 0.4], glow: [e0 - 0.12, 0, 1], text: I.tr("…the neighbours grow and shrink with it") });
            f.push({ w: scene(full(e0 - 0.12), e0 - 0.12, s0 + 0.18), cur: [0.75, s0 + 0.18], glowH: [e0 - 0.12, s0 + 0.18, 1 - e0 + 0.12], text: I.tr("…in every direction") });
            f.push({ w: scene(full(e0), e0, s0), cur: [0.75, s0], text: I.tr("…in every direction") });
        } else if (kind === "tiling") {
            names = ["1", "2", "3", "4"];
            // laid out on a 1600×900 screen (the layouts round to pixels), then scaled
            const o = { gap: 14, margin: 14, ratio: cfg ? cfg.tileRatio / 100 : 0.55, masters: cfg ? cfg.tileMasters : 1,
                        flip: cfg ? cfg.tileFlip : false, single: cfg ? cfg.tileSingleWidth / 100 : 1 };
            const tl = app ? app.tilerItem : null;
            const layoutFor = function (n) { return tl ? tl.layoutFor(n) : "tile"; };
            const at = function (n) {
                const kindN = layoutFor(n);
                const oo = Object.assign({ zones: tl ? tl.zonesOf(kindN) : null }, o);
                const rs = T.arrange(kindN, n, { x: 0, y: 0, width: 1600, height: 900 }, oo);
                const w = {};
                for (let i = 0; i < n; i++) w[names[i]] = [rs[i].x / 1600, rs[i].y / 900, rs[i].width / 1600, rs[i].height / 900];
                return w;
            };
            f.push({ w: at(1), text: I.tr("One window") });
            f.push({ w: at(2), top: "2", text: I.tr("A new window joins") });
            f.push({ w: at(3), top: "3", text: I.tr("A new window joins") });
            f.push({ w: at(4), top: "4", text: I.tr("A new window joins") });
            const w3 = at(3), three = {};
            three["1"] = w3["1"]; three["2"] = w3["2"]; three["4"] = w3["3"];
            f.push({ w: three, text: I.tr("One closes – the others fill the gap") });
            const w2 = at(2);
            f.push({ w: { "1": w2["1"], "4": w2["2"] }, text: I.tr("One closes – the others fill the gap") });
        } else if (kind === "swap") {
            names = ["A", "B"];
            const L = [0.015, 0.03, 0.475, 0.94], R = [0.51, 0.03, 0.475, 0.94];
            f.push({ w: { A: L, B: R }, cur: [0.25, 0.06], text: I.tr("Grab window A…") });
            f.push({ w: { A: [0.33, 0.2, 0.475, 0.6], B: R }, lift: "A", top: "A", cur: [0.56, 0.23], text: I.tr("…drag it onto window B…") });
            f.push({ w: { A: [0.5, 0.22, 0.475, 0.6], B: R }, lift: "A", top: "A", cur: [0.74, 0.25], pv: R, swap: true, text: I.tr("…drag it onto window B…") });
            f.push({ w: { A: R, B: L }, top: "A", cur: [0.74, 0.25], text: I.tr("…let go: they trade places") });
            f.push({ w: { A: R, B: L }, top: "A", cur: [0.74, 0.25], text: I.tr("…let go: they trade places") });
        }
        frames = f;
        step = 0;
    }

    Timer {
        interval: 1150
        repeat: true
        running: demo.running && demo.active && demo.frames.length > 0
        onTriggered: demo.step = (demo.step + 1) % demo.frames.length
    }

    onKindChanged: build()
    onAppChanged: build()
    Component.onCompleted: build()
    // rebuild when the settings behind a scene change
    Connections {
        target: demo.cfg
        ignoreUnknownSignals: true
        function onEdgeTopChanged() { if (demo.kind === "edges") demo.build(); }
        function onMagnetGapChanged() { if (demo.kind === "magnet") demo.build(); }
        function onTileLayoutChanged() { if (demo.kind === "tiling") demo.build(); }
        function onTileRatioChanged() { if (demo.kind === "tiling") demo.build(); }
        function onTileMastersChanged() { if (demo.kind === "tiling") demo.build(); }
        function onTileFlipChanged() { if (demo.kind === "tiling") demo.build(); }
        function onTileRulesOnChanged() { if (demo.kind === "tiling") demo.build(); }
        function onTileRulesChanged() { if (demo.kind === "tiling") demo.build(); }
        function onTileSingleWidthChanged() { if (demo.kind === "tiling") demo.build(); }
    }
}
