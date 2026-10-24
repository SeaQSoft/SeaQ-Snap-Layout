import QtQuick
import QtCore
import QtQml.Models
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore
import "../code/layouts.js" as L
import "../code/i18n.js" as I
import "../code/edges.js" as E
import "../code/keys.js" as K

// SeaQ Snap Layout
// Drag a window towards the top edge, the snap bar slides down, drop the
// window on a zone and it gets resized into place.
Item {
    id: root

    readonly property string version: "1.9.0"
    readonly property string author: "SeaQ"

    property alias settings: cfg
    property alias layoutModel: layoutsList
    property alias pal: theme
    property alias sysPalette: sysPal
    property alias ui: uiColors

    // ---------------------------------------------------------------- settings
    // Everything the editor changes lives in ~/.config/kde-snaplayout.ini.
    // kwinrc is only ever read (see kwinrcReader below), never written.
    readonly property var defaultValues: ({
        snapEnabled: true, showPreview: true, restoreSize: true,
        windowGap: 0, edgeMargin: 0, excludedApps: "",
        themeMode: 0, useSystemAccent: true, customAccent: "#4cc2ff",
        barOpacity: 96, barScale: 100, thumbWidth: 72, cornerRadius: 8,
        perRow: 0, showLayoutName: false,
        triggerDistance: 24, twoStage: true, peekDistance: 140,
        activationWidth: 100, showDelay: 40, hideDelay: 150, hideMargin: 56,
        slideDistance: 12, slideInDuration: 220, slideOutDuration: 150,
        easingStyle: 0, fadeEnabled: true, editorSnapping: true,
        previewAccent: true,
        edgeEnabled: true, edgeTop: 0, edgeSides: true, edgeBottom: true, edgeCorners: true,
        edgeSmart: true, edgePreview: true, edgeDistance: 4, edgeCornerSize: 20, edgeDelay: 60,
        magnetEnabled: true, magnetDistance: 16, magnetWindows: true, magnetScreen: true,
        magnetResize: true, magnetGap: false, magnetResist: 48,
        stickyEnabled: true, stickyAligned: true, stickyShake: true, stickyDim: true,
        edgeFill: true, edgeFillDelay: 700, kdeEdgesOff: true, kdeSnapOff: true,
        keysEnabled: true, keyScheme: "ctrlalt"
    })
    readonly property var groupGeneral: ["snapEnabled", "showPreview", "restoreSize", "windowGap", "edgeMargin"]
    readonly property var groupAppearance: ["themeMode", "useSystemAccent", "customAccent", "barOpacity",
        "barScale", "thumbWidth", "cornerRadius", "perRow", "showLayoutName", "previewAccent"]
    readonly property var groupEdges: ["edgeEnabled", "edgeTop", "edgeSides", "edgeBottom", "edgeCorners",
        "edgeSmart", "edgePreview", "edgeDistance", "edgeCornerSize", "edgeDelay",
        "edgeFill", "edgeFillDelay", "kdeEdgesOff"]
    readonly property var groupMagnet: ["magnetEnabled", "magnetDistance", "magnetWindows", "magnetScreen",
        "magnetResize", "magnetGap", "magnetResist",
        "stickyEnabled", "stickyAligned", "stickyShake", "stickyDim", "kdeSnapOff"]
    readonly property var groupBehavior: ["triggerDistance", "twoStage", "peekDistance", "activationWidth",
        "showDelay", "hideDelay", "hideMargin", "slideDistance", "slideInDuration", "slideOutDuration",
        "easingStyle", "fadeEnabled"]

    function resetGroup(keys) {
        for (let i = 0; i < keys.length; i++)
            cfg[keys[i]] = defaultValues[keys[i]];
        try { cfg.sync(); } catch (e) {}
    }

    Settings {
        id: cfg
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/kde-snaplayout.ini"
        category: "General"

        property bool snapEnabled: true
        property bool showPreview: true
        property bool restoreSize: true
        property int windowGap: 0
        property int edgeMargin: 0
        property string excludedApps: ""

        property int themeMode: 0            // 0 system, 1 light, 2 dark
        property bool useSystemAccent: true
        property string customAccent: "#4cc2ff"
        property int barOpacity: 96
        property int barScale: 100
        property int thumbWidth: 72
        property int cornerRadius: 8
        property int perRow: 0
        property bool showLayoutName: false

        property int triggerDistance: 24
        property bool twoStage: true
        property int peekDistance: 140
        property int activationWidth: 100
        property int showDelay: 40
        property int hideDelay: 150
        property int hideMargin: 56
        property int slideDistance: 12
        property int slideInDuration: 220
        property int slideOutDuration: 150
        property int easingStyle: 0
        property bool fadeEnabled: true

        property bool editorSnapping: true
        property bool previewAccent: true    // previews in the accent color, or neutral

        // screen edges: push a window against an edge or corner
        property bool edgeEnabled: true
        property int edgeTop: 0              // 0 maximize, 1 fullscreen, 2 top half, 3 nothing
        property bool edgeSides: true
        property bool edgeBottom: true
        property bool edgeCorners: true
        property bool edgeSmart: true
        property bool edgePreview: true
        property int edgeDistance: 4
        property int edgeCornerSize: 20      // percent of the screen side
        property int edgeDelay: 60

        // window magnet: edges stick to other windows and the screen edge
        property bool magnetEnabled: true
        property int magnetDistance: 16
        property bool magnetWindows: true
        property bool magnetScreen: true
        property bool magnetResize: true
        property bool magnetGap: false
        property int magnetResist: 48        // px a window has to be pushed into another one
        property bool stickyEnabled: true    // touching windows resize together
        property bool stickyAligned: true    // stacked windows keep their edges in line
        property bool stickyShake: true      // shake the mouse to let them go
        property bool stickyDim: true        // fade the windows that do not follow
        property bool edgeFill: true         // held longer at an edge: grow up to the next window
        property int edgeFillDelay: 700
        property bool kdeEdgesOff: true      // KDE's own edge tiling is paused while this script runs
        property bool kdeSnapOff: true       // KDE's own snap zones are paused while the magnet is on

        property bool keysEnabled: true
        property string keyScheme: "ctrlalt"   // last scheme applied in the editor

        property string layoutsJson: ""
        property bool lastOpenFlag: false
        property int lastGearTheme: -1
    }

    // ------------------------------------------------------------------ colors
    SystemPalette { id: sysPal; colorGroup: SystemPalette.Active }

    function luma(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }

    // Colors of the snap bar. These follow the user's choice (system/light/dark
    // and the accent picker).
    QtObject {
        id: theme
        readonly property bool systemMode: cfg.themeMode === 0
        readonly property bool dark: cfg.themeMode === 2 || (systemMode && root.luma(sysPal.window) < 0.5)
        readonly property color accent: cfg.useSystemAccent ? sysPal.highlight : cfg.customAccent
        readonly property color barBg: systemMode ? sysPal.window : (dark ? "#2b2b2b" : "#f9f9f9")
        readonly property color barBorder: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)
        readonly property color text: systemMode ? sysPal.windowText : (dark ? "#ffffff" : "#1a1a1a")
        readonly property color zone: systemMode ? root.mix(sysPal.window, sysPal.windowText, dark ? 0.30 : 0.20)
                                                 : (dark ? "#575757" : "#d0d0d0")
        readonly property color zoneBorder: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
    }

    // Colors of the settings editor window. Always taken from the system,
    // regardless of what the snap bar uses.
    QtObject {
        id: uiColors
        readonly property bool dark: root.luma(sysPal.window) < 0.5
        readonly property color window: sysPal.window
        readonly property color text: sysPal.windowText
        readonly property color accent: sysPal.highlight
        readonly property color accentText: sysPal.highlightedText
        readonly property color negative: "#da4453"           // Breeze's negative text color
        readonly property color card: Qt.tint(sysPal.window, Qt.rgba(sysPal.windowText.r, sysPal.windowText.g, sysPal.windowText.b, 0.045))
        readonly property color sidebar: Qt.tint(sysPal.window, Qt.rgba(sysPal.windowText.r, sysPal.windowText.g, sysPal.windowText.b, 0.025))
        readonly property color line: Qt.rgba(sysPal.windowText.r, sysPal.windowText.g, sysPal.windowText.b, 0.12)
        readonly property color zone: root.mix(sysPal.window, sysPal.windowText, dark ? 0.30 : 0.20)
        readonly property color zoneBorder: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
    }

    // One in-curve and a matching out-curve per style, so sliding back up
    // feels like the reverse of sliding down.
    readonly property var easingIn:  [Easing.OutCubic, Easing.OutQuart, Easing.OutBack, Easing.OutExpo, Easing.InOutQuad, Easing.Linear]
    readonly property var easingOut: [Easing.InCubic,  Easing.InQuart,  Easing.InBack,  Easing.InExpo,  Easing.InOutQuad, Easing.Linear]
    readonly property int easingStyleIdx: Math.max(0, Math.min(5, cfg.easingStyle))
    readonly property int easingType: easingIn[easingStyleIdx]
    readonly property int easingOutType: easingOut[easingStyleIdx]

    // ----------------------------------------------------------------- layouts
    ListModel { id: layoutsList }
    property var barLayouts: []

    function loadLayouts() {
        layoutsList.clear();
        let arr = null;
        try { arr = cfg.layoutsJson ? JSON.parse(cfg.layoutsJson) : null; } catch (e) { arr = null; }
        if (!Array.isArray(arr) || arr.length === 0) arr = L.defaultLayouts();
        for (let i = 0; i < arr.length; i++) {
            const l = arr[i];
            layoutsList.append({
                name: String(l.name || "Layout"),
                shown: l.shown !== false,
                tree: typeof l.tree === "string" ? l.tree : JSON.stringify(l.tree)
            });
        }
        rebuildBar();
    }

    function saveLayouts() {
        const arr = [];
        for (let i = 0; i < layoutsList.count; i++) {
            const o = layoutsList.get(i);
            arr.push({ name: o.name, shown: o.shown, tree: o.tree });
        }
        cfg.layoutsJson = JSON.stringify(arr);
        try { cfg.sync(); } catch (e) {}
        rebuildBar();
    }

    function resetLayouts() {
        cfg.layoutsJson = "";
        loadLayouts();
        saveLayouts();
    }

    function rebuildBar() {
        const out = [];
        for (let i = 0; i < layoutsList.count; i++) {
            const o = layoutsList.get(i);
            if (o.shown) out.push({ name: I.layoutName(o.name), zones: L.zones(L.parseTree(o.tree)) });
        }
        barLayouts = out;
    }

    // ------------------------------------------------------------------- state
    property int barState: 0                 // 0 hidden, 1 handle, 2 open
    property bool barExpanded: false         // stays true while an open bar slides away
    property var dragWin: null
    property bool demoMode: false
    property var curOutput: null
    property rect scrGeo: Qt.rect(0, 0, 1920, 1080)
    property rect areaGeo: Qt.rect(0, 0, 1920, 1080)
    property rect virtGeo: Qt.rect(0, 0, 1920, 1080)
    readonly property real screenAspect: scrGeo.width > 0 ? scrGeo.height / scrGeo.width : 0.5625
    property int hoverLayout: -1
    property int hoverZone: -1
    property rect previewRect: Qt.rect(0, 0, 0, 0)
    property bool previewVisible: false
    property var hooked: ({})
    property var snapped: ({})
    property var dragStartSize: null
    property var pendingWin: null
    property rect pendingRect: Qt.rect(0, 0, 0, 0)
    property int reapplyCount: 0

    // screen edges and window magnet
    property string edgePending: ""          // edge under the cursor, waiting for edgeDelay
    property string edgeActive: ""           // edge that will be used on drop
    property int edgeStage: 1                // 2 = held long enough to fill the free space
    property var fillOthers: []              // rects of the other windows (hold to fill)
    property var dragOthers: []              // rects of the other windows (magnet)
    property var dragBlockers: []            // rects of tiled windows (smart fill)
    property var lastMagnet: null            // last rect the magnet produced
    property var resizeWin: null
    property var resizeStart: null
    property var resizeLast: null            // last rect KWin reported while resizing

    // sticky edges: windows that follow the one being resized
    property var stickyLinks: []             // [{ w, orig, req, link, opacity, id }]
    property var stickyFaded: []             // [{ w, opacity }]
    property var stickyMoved: ({ l: false, r: false, t: false, b: false })
    property var stickyShakeW: null
    property var stickyShakeH: null

    // ---------------------------------------------------------------- geometry
    function refreshVirtual() {
        const s = Workspace.screens;
        if (!s || s.length === 0) return;
        let x1 = Infinity, y1 = Infinity, x2 = -Infinity, y2 = -Infinity;
        for (let i = 0; i < s.length; i++) {
            const g = s[i].geometry;
            x1 = Math.min(x1, g.x); y1 = Math.min(y1, g.y);
            x2 = Math.max(x2, g.x + g.width); y2 = Math.max(y2, g.y + g.height);
        }
        virtGeo = Qt.rect(x1, y1, x2 - x1, y2 - y1);
    }

    function outputAt(p) {
        const s = Workspace.screens;
        for (let i = 0; i < s.length; i++) {
            const g = s[i].geometry;
            if (p.x >= g.x && p.x < g.x + g.width && p.y >= g.y && p.y < g.y + g.height) return s[i];
        }
        return Workspace.activeScreen;
    }

    function refreshScreen(out) {
        if (!out) return;
        curOutput = out;
        const g = out.geometry;
        scrGeo = Qt.rect(g.x, g.y, g.width, g.height);
        const a = Workspace.clientArea(KWin.MaximizeArea, out, Workspace.currentDesktop);
        areaGeo = Qt.rect(a.x, a.y, a.width, a.height);
    }

    function sameRect(a, b) {
        return Math.abs(a.x - b.x) <= 3 && Math.abs(a.y - b.y) <= 3
            && Math.abs(a.width - b.width) <= 3 && Math.abs(a.height - b.height) <= 3;
    }

    function isExcluded(w) {
        if (!cfg.excludedApps) return false;
        const rc = String(w.resourceClass || "").toLowerCase();
        const list = cfg.excludedApps.split(/[\n,;]/);
        for (let i = 0; i < list.length; i++) {
            const e = list[i].trim().toLowerCase();
            if (e && e === rc) return true;
        }
        return false;
    }

    function isEligible(w) {
        if (!w || !w.normalWindow || !w.resizeable || w.fullScreen) return false;
        return !isExcluded(w);
    }

    function rectOf(g) { return E.rect(g.x, g.y, g.width, g.height); }

    function onCurrentDesktop(w) {
        if (w.onAllDesktops) return true;
        const list = w.desktops;
        if (!list || list.length === undefined || list.length === 0) return true;
        const cur = Workspace.currentDesktop;
        for (let i = 0; i < list.length; i++) {
            if (list[i] === cur) return true;
            try { if (cur && list[i] && list[i].id === cur.id) return true; } catch (e) {}
        }
        return false;
    }

    function areaOf(w) {
        const out = w && w.output ? w.output : curOutput;
        const a = Workspace.clientArea(KWin.MaximizeArea, out, Workspace.currentDesktop);
        return E.rect(a.x, a.y, a.width, a.height);
    }

    // windows the magnet can stick to
    function otherRects(w, skip) {
        const out = [];
        const list = Workspace.stackingOrder || [];
        for (let i = 0; i < list.length; i++) {
            const o = list[i];
            if (!o || o === w || !o.normalWindow || o.minimized || o.fullScreen || !onCurrentDesktop(o)) continue;
            if (skip && skip.indexOf(o) >= 0) continue;
            out.push(rectOf(o.frameGeometry));
        }
        return out;
    }

    // Windows that are tiled on this screen: snapped by us and still in place,
    // or sitting against at least two edges of the free area (e.g. quick tiled).
    function dockedRects(w) {
        const out = [];
        const area = areaGeo;
        const list = Workspace.stackingOrder || [];
        for (let i = 0; i < list.length; i++) {
            const o = list[i];
            if (!o || o === w || !o.normalWindow || o.minimized || o.fullScreen || !onCurrentDesktop(o)) continue;
            if (o.output && curOutput && o.output !== curOutput) continue;
            const g = o.frameGeometry;
            const rec = snapped[String(o.internalId)];
            if (rec && sameRect(g, rec.rect)) { out.push(rectOf(g)); continue; }
            if (sameRect(g, area)) continue;                       // maximized: not a tile
            const tol = 4;
            const touches = (Math.abs(g.x - area.x) <= tol ? 1 : 0)
                          + (Math.abs(g.y - area.y) <= tol ? 1 : 0)
                          + (Math.abs(g.x + g.width - area.x - area.width) <= tol ? 1 : 0)
                          + (Math.abs(g.y + g.height - area.y - area.height) <= tol ? 1 : 0);
            if (touches >= 2) out.push(rectOf(g));
        }
        return out;
    }

    // edges where another screen continues: the cursor passes over there
    function blockedEdges(p) {
        const b = { left: false, right: false, top: false, bottom: false };
        const s = Workspace.screens || [];
        for (let i = 0; i < s.length; i++) {
            const g = s[i].geometry;
            if (g.x === scrGeo.x && g.y === scrGeo.y && g.width === scrGeo.width && g.height === scrGeo.height) continue;
            const inY = p.y >= g.y && p.y < g.y + g.height;
            const inX = p.x >= g.x && p.x < g.x + g.width;
            if (inY && Math.abs(g.x + g.width - scrGeo.x) <= 2) b.left = true;
            if (inY && Math.abs(g.x - (scrGeo.x + scrGeo.width)) <= 2) b.right = true;
            if (inX && Math.abs(g.y + g.height - scrGeo.y) <= 2) b.top = true;
            if (inX && Math.abs(g.y - (scrGeo.y + scrGeo.height)) <= 2) b.bottom = true;
        }
        return b;
    }

    function currentEdge(p) {
        return E.edgeAt(p, rectOf(scrGeo), {
            distance: cfg.edgeDistance, cornerPercent: cfg.edgeCornerSize,
            top: cfg.edgeTop !== 3, sides: cfg.edgeSides, bottom: cfg.edgeBottom, corners: cfg.edgeCorners
        }, blockedEdges(p));
    }

    // What dropping on an edge does: { kind: "max" | "full" | "rect", rect }
    function edgePlan(edge) {
        if (!edge) return null;
        let name = edge;
        if (edge === "top") {
            if (cfg.edgeTop === 1) return { kind: "full", rect: rectOf(scrGeo) };
            if (cfg.edgeTop === 3) return null;
            name = cfg.edgeTop === 2 ? "top" : "max";
        }
        const area = rectOf(areaGeo);
        let r = name === "max" ? area : L.targetRect(area, E.zoneFor(name), cfg.windowGap, cfg.edgeMargin);
        r = E.rect(r.x, r.y, r.width, r.height);
        let kind = name === "max" ? "max" : "rect";
        if (cfg.edgeSmart && dragBlockers.length > 0) {
            const fitted = E.fitFree(r, edge, dragBlockers, area);
            if (!sameRect(fitted, r)) { r = fitted; kind = "rect"; }
        }
        if (edgeStage === 2 && cfg.edgeFill && kind === "rect") {
            const m = cfg.edgeMargin;
            const bounds = E.rect(area.x + m, area.y + m, area.width - 2 * m, area.height - 2 * m);
            r = E.fillFree(edge, r, fillOthers, bounds, cfg.windowGap);
        }
        return { kind: kind, rect: r };
    }

    function setEdge(edge) {
        if (edge === edgePending) return;
        edgePending = edge;
        edgeTimer.stop();
        fillTimer.stop();
        edgeStage = 1;
        if (!edge) { edgeActive = ""; updatePreview(); return; }
        if (cfg.edgeDelay <= 0) { edgeActive = edge; updatePreview(); startFillTimer(); }
        else { edgeActive = ""; updatePreview(); edgeTimer.restart(); }
    }

    function magnetOptions() {
        return { distance: cfg.magnetDistance, windows: cfg.magnetWindows, screen: cfg.magnetScreen,
                 gap: cfg.magnetGap ? cfg.windowGap : 0, resist: cfg.magnetResist };
    }

    // geometry KWin reports with the step; frameGeometry can lag behind on Wayland
    function stepRect(w, r) {
        if (r && r.width > 0 && r.height > 0) return E.rect(r.x, r.y, r.width, r.height);
        return rectOf(w.frameGeometry);
    }

    function applyMagnet(w, edges, cur) {
        const g = cur || rectOf(w.frameGeometry);
        const r = E.magnet(g, dragOthers, areaOf(w), magnetOptions(), edges);
        lastMagnet = r;
        if (Math.abs(r.x - g.x) >= 1 || Math.abs(r.y - g.y) >= 1 || Math.abs(r.width - g.width) >= 1 || Math.abs(r.height - g.height) >= 1)
            w.frameGeometry = Qt.rect(r.x, r.y, r.width, r.height);
    }

    function onStepped(w, r) {
        if (w === dragWin) {
            updateDrag();
            const busy = edgePending !== "" || (barState === 2 && hoverZone >= 0);
            if (cfg.magnetEnabled && !busy) applyMagnet(w, { l: true, r: true, t: true, b: true }, stepRect(w, r));
            else lastMagnet = null;
        } else if (w === resizeWin && resizeStart) {
            const cur = stepRect(w, r);
            resizeLast = cur;
            // The window being resized belongs to KWin until the button is let go;
            // the magnet result is only applied then. The neighbours follow live.
            if (cfg.magnetEnabled && cfg.magnetResize) {
                const edges = E.resizedEdges(resizeStart, cur);
                lastMagnet = (edges.l || edges.r || edges.t || edges.b)
                    ? E.magnet(cur, dragOthers, areaOf(w), magnetOptions(), edges) : null;
            }
            if (stickyLinks.length) stickyStep(w, cur);
        }
    }

    // ------------------------------------------------------------ sticky edges
    function stickyStart(w) {
        stickyLinks = []; stickyFaded = [];
        stickyMoved = { l: false, r: false, t: false, b: false };
        const a = rectOf(w.frameGeometry);
        stickyShakeW = { val: a.width, turnVal: a.width, dir: 0, count: 0 };
        stickyShakeH = { val: a.height, turnVal: a.height, dir: 0, count: 0 };
        const area = areaOf(w);
        const opts = { tol: Math.max(0, cfg.windowGap) + 6, aligned: cfg.stickyAligned, area: area };
        const links = [], faded = [];
        const list = Workspace.stackingOrder || [];
        for (let i = 0; i < list.length; i++) {
            const o = list[i];
            if (!o || o === w || !o.normalWindow || o.minimized || !onCurrentDesktop(o)) continue;
            if (o.output && w.output && o.output !== w.output) continue;
            const b = rectOf(o.frameGeometry);
            const big = o.fullScreen || sameRect(o.frameGeometry, area);
            const link = (big || !o.resizeable || isExcluded(o)) ? null : E.stickyLink(a, b, opts);
            if (link) links.push({ w: o, orig: b, req: b, link: link, opacity: o.opacity, id: String(o.internalId) });
            else faded.push({ w: o, opacity: o.opacity, done: false });
        }
        stickyLinks = links;
        stickyFaded = links.length ? faded : [];
    }

    function stickyLimits(o, orig, area) {
        let minW = 50, minH = 50, maxW = 1e6, maxH = 1e6;
        try { if (o.minSize) { minW = Math.max(o.minSize.width || 0, Math.min(50, orig.width)); minH = Math.max(o.minSize.height || 0, Math.min(50, orig.height)); } } catch (e) {}
        try { if (o.maxSize && o.maxSize.width > 0) { maxW = o.maxSize.width; maxH = o.maxSize.height; } } catch (e) {}
        return { minW: minW, minH: minH, maxW: Math.max(minW, maxW), maxH: Math.max(minH, maxH), area: area };
    }

    function stickyStep(w, cur) {
        const s0 = resizeStart;
        stickyMoved = {
            l: stickyMoved.l || Math.abs(cur.x - s0.x) >= 1,
            r: stickyMoved.r || Math.abs(cur.x + cur.width - s0.x - s0.width) >= 1,
            t: stickyMoved.t || Math.abs(cur.y - s0.y) >= 1,
            b: stickyMoved.b || Math.abs(cur.y + cur.height - s0.y - s0.height) >= 1
        };
        if (cfg.stickyShake) {
            const turns = Math.max(E.shakeStep(stickyShakeW, cur.width, 200), E.shakeStep(stickyShakeH, cur.height, 200));
            if (turns >= 4) { stickyEnd(true); return; }
        }
        const area = areaOf(w);
        for (let i = 0; i < stickyLinks.length; i++) {
            const k = stickyLinks[i];
            const g = E.stickyRect(k.orig, k.link, cur, stickyMoved, stickyLimits(k.w, k.orig, area));
            if (g.x !== k.req.x || g.y !== k.req.y || g.width !== k.req.width || g.height !== k.req.height) {
                k.req = g;
                k.w.frameGeometry = Qt.rect(g.x, g.y, g.width, g.height);
            }
        }
        if (cfg.stickyDim) {
            for (let j = 0; j < stickyFaded.length; j++) {
                const f = stickyFaded[j];
                if (!f.done) { f.done = true; try { f.w.opacity = f.opacity * 0.45; } catch (e) {} }
            }
        }
    }

    // undo: put the neighbours back (shaken loose)
    function stickyEnd(undo) {
        for (let i = 0; i < stickyLinks.length; i++) {
            const k = stickyLinks[i];
            if (undo) k.w.frameGeometry = Qt.rect(k.orig.x, k.orig.y, k.orig.width, k.orig.height);
            else {
                // a window we snapped stays "snapped" in its new place
                const rec = snapped[k.id];
                if (rec && sameRect(Qt.rect(k.orig.x, k.orig.y, k.orig.width, k.orig.height), rec.rect))
                    rec.rect = { x: k.req.x, y: k.req.y, width: k.req.width, height: k.req.height };
            }
        }
        for (let j = 0; j < stickyFaded.length; j++) {
            const f = stickyFaded[j];
            if (f.done) { try { f.w.opacity = f.opacity; } catch (e) {} }
        }
        stickyLinks = []; stickyFaded = [];
    }

    // ----------------------------------------------------------- window hooks
    // Handlers are kept per window and disconnected when the script unloads.
    // Otherwise windows keep calling into a destroyed script after a reload.
    property var hookFns: ({})

    function hookWindow(w) {
        if (!w) return;
        const id = String(w.internalId);
        if (hooked[id]) return;
        hooked[id] = true;
        const fns = {
            w: w,
            started: function () { if (root) root.onMoveStarted(w); },
            stepped: function (r) { if (root) root.onStepped(w, r); },
            finished: function () { if (root) root.onMoveFinished(w); }
        };
        hookFns[id] = fns;
        w.interactiveMoveResizeStarted.connect(fns.started);
        w.interactiveMoveResizeStepped.connect(fns.stepped);
        w.interactiveMoveResizeFinished.connect(fns.finished);
    }

    function unhookAll() {
        for (const id in hookFns) {
            const f = hookFns[id];
            try {
                f.w.interactiveMoveResizeStarted.disconnect(f.started);
                f.w.interactiveMoveResizeStepped.disconnect(f.stepped);
                f.w.interactiveMoveResizeFinished.disconnect(f.finished);
            } catch (e) {}
        }
        hookFns = ({});
        hooked = ({});
    }

    Component.onDestruction: { restoreKdeOptions(); unhookAll(); }

    function onMoveStarted(w) {
        if (!w || !isEligible(w)) return;
        if (!w.move) {
            // resizing: the magnet and the sticky edges take part
            const mag = cfg.magnetEnabled && cfg.magnetResize;
            if (w.resize && (mag || cfg.stickyEnabled)) {
                resizeWin = w;
                resizeStart = rectOf(w.frameGeometry);
                resizeLast = null;
                lastMagnet = null;
                if (cfg.stickyEnabled) stickyStart(w); else stickyLinks = [];
                // windows that follow the resize are no magnet targets
                const skip = stickyLinks.map(function (k) { return k.w; });
                dragOthers = mag ? otherRects(w, skip) : [];
            }
            return;
        }
        if (!cfg.snapEnabled && !cfg.edgeEnabled && !cfg.magnetEnabled) return;
        reapplyTimer.stop();
        pendingWin = null;
        demoStep.stop();
        demoMode = false;

        const id = String(w.internalId);
        const rec = snapped[id];
        const fg = w.frameGeometry;
        let startW = fg.width, startH = fg.height;
        // A snapped window gets its old size back once you pull it out again.
        // Keep the cursor at the same relative spot on the title bar.
        if (rec && cfg.restoreSize && sameRect(fg, rec.rect)) {
            const c = Workspace.cursorPos;
            const ratio = (c.x - fg.x) / Math.max(1, fg.width);
            w.frameGeometry = Qt.rect(Math.round(c.x - rec.w * ratio), fg.y, rec.w, rec.h);
            startW = rec.w; startH = rec.h;
        }
        delete snapped[id];
        dragStartSize = { w: startW, h: startH };

        dragWin = w;
        refreshScreen(outputAt(Workspace.cursorPos));
        dragOthers = cfg.magnetEnabled ? otherRects(w) : [];
        dragBlockers = cfg.edgeEnabled && cfg.edgeSmart ? dockedRects(w) : [];
        fillOthers = cfg.edgeEnabled && cfg.edgeFill ? otherRects(w) : [];
        edgeStage = 1;
        lastMagnet = null;
        edgePending = ""; edgeActive = "";
        setHover(-1, -1);
        barState = 0;
        if (cfg.snapEnabled || cfg.edgeEnabled) overlayShow();
        updateDrag();
    }

    function onMoveFinished(w) {
        if (w === resizeWin) {
            const m = lastMagnet;
            if (m && !sameRect(resizeLast || w.frameGeometry, m)) {
                w.frameGeometry = Qt.rect(m.x, m.y, m.width, m.height);
                if (stickyLinks.length) stickyStep(w, m);
            }
            stickyEnd(false);
            resizeWin = null; resizeStart = null; resizeLast = null; lastMagnet = null;
            return;
        }
        if (w !== dragWin) return;
        const li = hoverLayout, zi = hoverZone;
        const area = Qt.rect(areaGeo.x, areaGeo.y, areaGeo.width, areaGeo.height);
        const z = (cfg.snapEnabled && barState === 2 && zi >= 0 && li >= 0 && li < barLayouts.length) ? barLayouts[li].zones[zi] : null;
        const plan = !z && edgeActive ? edgePlan(edgeActive) : null;
        const mag = cfg.magnetEnabled ? lastMagnet : null;
        endDrag();
        if (z) snapWindow(w, z, area);
        else if (plan) applyPlan(w, plan);
        else if (mag && !sameRect(w.frameGeometry, mag)) w.frameGeometry = Qt.rect(mag.x, mag.y, mag.width, mag.height);
    }

    function applyPlan(w, plan) {
        if (plan.kind === "full") {
            try { w.fullScreen = true; } catch (e) {}
        } else if (plan.kind === "max") {
            try { w.setMaximize(true, true); } catch (e) {}
        } else {
            snapWindowRect(w, plan.rect, dragStartSize);
        }
    }

    function endDrag() {
        dragWin = null;
        showTimer.stop();
        hideTimer.stop();
        edgeTimer.stop();
        fillTimer.stop();
        edgeStage = 1;
        edgePending = "";
        edgeActive = "";
        lastMagnet = null;
        barState = 0;
        setHover(-1, -1);
        closeTimer.restart();
    }

    function snapWindow(w, z, area) {
        const r = L.targetRect(area, z, cfg.windowGap, cfg.edgeMargin);
        snapWindowRect(w, r, dragStartSize);
    }

    // Puts a window into place and remembers its free size for later.
    function snapWindowRect(w, r, pre) {
        const rect = Qt.rect(Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height));
        try { if (w.tile) w.tile = null; } catch (e) {}
        try { if (w.maximizable) w.setMaximize(false, false); } catch (e) {}
        w.frameGeometry = rect;
        pre = pre || { w: rect.width, h: rect.height };
        snapped[String(w.internalId)] = { w: pre.w, h: pre.h, rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height } };
        // KWin's own top-edge maximize or quick tiling can kick in right after
        // the drop. Re-apply our geometry a few times to win that race.
        pendingWin = w;
        pendingRect = rect;
        reapplyCount = 0;
        reapplyTimer.restart();
    }

    // ------------------------------------------------------- drag tracking
    function updateDrag() {
        if (!dragWin && !demoMode) return;
        const p = Workspace.cursorPos;
        const out = outputAt(p);
        if (out !== curOutput) refreshScreen(out);

        const edge = dragWin && cfg.edgeEnabled ? currentEdge(p) : "";
        setEdge(edge);
        if (cfg.snapEnabled || demoMode) updateBar(p, edge);
    }

    function updateBar(p, edge) {
        const relY = p.y - areaGeo.y;
        const relX = p.x - scrGeo.x;
        const half = scrGeo.width * cfg.activationWidth / 200;
        // a corner belongs to the screen edges, the bar stays out of it
        const inCorner = edge.length === 2;
        const inX = Math.abs(relX - scrGeo.width / 2) <= half && !inCorner;

        if (barState === 2) {
            const bx = scrGeo.x + (scrGeo.width - snapBar.fullW) / 2;
            const by = areaGeo.y + cfg.slideDistance;
            const m = cfg.hideMargin;
            const inside = p.x >= bx - m && p.x <= bx + snapBar.fullW + m && p.y <= by + snapBar.fullH + m;
            if (inside) hideTimer.stop();
            else if (!hideTimer.running) hideTimer.restart();
            const h = snapBar.hit(overlayRoot, p.x - virtGeo.x, p.y - virtGeo.y);
            setHover(h.layout, h.zone);
            return;
        }

        // Handle stage: hovering the handle opens the bar even if the cursor
        // is a bit below the trigger distance.
        let overPill = false;
        if (barState === 1) {
            const px = scrGeo.x + (scrGeo.width - snapBar.pillW) / 2;
            const py = areaGeo.y + cfg.slideDistance;
            overPill = p.x >= px - 24 && p.x <= px + snapBar.pillW + 24 && p.y <= py + snapBar.pillH + 24;
        }
        const wantOpen = inX && (relY <= cfg.triggerDistance || overPill);
        const wantPeek = cfg.twoStage && inX && relY <= cfg.peekDistance;
        if (wantOpen) {
            if (barState === 0 && cfg.twoStage) barState = 1;
            if (!showTimer.running) showTimer.restart();
        } else {
            showTimer.stop();
            barState = wantPeek ? 1 : 0;
        }
    }

    function setHover(li, zi) {
        if (li === hoverLayout && zi === hoverZone) return;
        hoverLayout = li;
        hoverZone = zi;
        updatePreview();
    }

    // One preview for everything: a hovered bar zone wins over a screen edge.
    function updatePreview() {
        let r = null;
        const li = hoverLayout, zi = hoverZone;
        if (zi >= 0 && li >= 0 && li < barLayouts.length) {
            if (cfg.showPreview) r = L.targetRect(areaGeo, barLayouts[li].zones[zi], cfg.windowGap, cfg.edgeMargin);
        } else if (edgeActive && cfg.edgePreview) {
            const plan = edgePlan(edgeActive);
            if (plan) r = plan.rect;
        }
        if (r) {
            previewRect = Qt.rect(r.x - scrGeo.x, r.y - scrGeo.y, r.width, r.height);
            previewVisible = true;
        } else {
            previewVisible = false;
        }
    }

    // ------------------------------------------------------- bar animation
    // Driven by hand instead of Behaviors: a Behavior reads its duration and
    // curve from bindings that change at the same moment as the target value,
    // so it could pick the slide-in values for a slide-out.
    readonly property real barShownY: areaGeo.y - scrGeo.y + cfg.slideDistance
    readonly property real barHiddenY: -snapBar.fullH - 30

    onBarStateChanged: {
        if (barState === 2) barExpanded = true;
        else if (barState === 1) barExpanded = false;
        animateBar(barState > 0);
    }

    property bool barShown: false
    function animateBar(show) {
        if (show === barShown) return;
        barShown = show;
        slideAnim.stop();
        fadeAnim.stop();
        slideAnim.from = snapBar.y;
        slideAnim.to = show ? barShownY : barHiddenY;
        slideAnim.duration = Math.max(0, show ? cfg.slideInDuration : cfg.slideOutDuration);
        slideAnim.easing.type = show ? easingType : easingOutType;
        fadeAnim.from = snapBar.opacity;
        fadeAnim.to = (show || !cfg.fadeEnabled) ? 1 : 0;
        fadeAnim.duration = show ? Math.round(cfg.slideInDuration * 0.6) : cfg.slideOutDuration;
        slideAnim.start();
        fadeAnim.start();
    }

    // keep the bar in place when the panel layout or the screen changes
    onBarShownYChanged: if (barShown && !slideAnim.running) snapBar.y = barShownY

    function overlayShow() {
        refreshVirtual();
        closeTimer.stop();
        overlay.x = virtGeo.x;
        overlay.y = virtGeo.y;
        overlay.width = virtGeo.width;
        overlay.height = virtGeo.height;
        if (!barShown) {
            snapBar.y = barHiddenY;
            snapBar.opacity = cfg.fadeEnabled ? 0 : 1;
        }
        overlay.visible = true;
    }

    // Plays the bar on the current screen so settings can be tried out.
    function demoBar() {
        if (dragWin) return;
        demoMode = true;
        refreshScreen(outputAt(Workspace.cursorPos));
        overlayShow();
        barState = 0;
        demoStep.step = 0;
        demoStep.interval = 60;
        demoStep.restart();
    }

    // ---------------------------------------------------------- editor window
    // Frameless window with its own title bar. A normally decorated window
    // was tried: KWin never activates its own internal windows, so the
    // decoration stays grey (inactive) and offers no maximize. Drawing the
    // buttons ourselves from the active decoration theme looks better.
    property int dlgW: 1200
    property int dlgH: 880
    property bool dlgMaximized: false
    property var dlgSaved: null
    property var dlgDrag: null
    readonly property int dlgMinW: 820
    readonly property int dlgMinH: 480

    function openSettings() {
        readDecoration();
        if (layoutsDialog.visible) {
            try { layoutsDialog.raise(); layoutsDialog.requestActivate(); } catch (e) {}
            return;
        }
        refreshScreen(outputAt(Workspace.cursorPos));
        dlgMaximized = false;
        dlgW = Math.min(areaGeo.width, Math.max(dlgMinW, Math.min(1200, Math.round(areaGeo.width * 0.92))));
        dlgH = Math.min(areaGeo.height, Math.max(dlgMinH, Math.min(880, Math.round(areaGeo.height * 0.92))));
        layoutsDialog.x = Math.round(areaGeo.x + (areaGeo.width - dlgW) / 2);
        layoutsDialog.y = Math.round(areaGeo.y + (areaGeo.height - dlgH) / 2);
        layoutsDialog.visible = true;
        shortcutService.readAll(K.ACTIONS, shortcutText);
        try { layoutsDialog.raise(); layoutsDialog.requestActivate(); } catch (e) {}
    }

    function closeSettings() {
        layoutsDialog.visible = false;
        dlgDrag = null;
    }

    function beginWindowDrag() {
        const c = Workspace.cursorPos;
        dlgDrag = { cx: c.x, cy: c.y, x: layoutsDialog.x, y: layoutsDialog.y, w: dlgW, h: dlgH };
    }
    function endWindowDrag() { dlgDrag = null; }

    function moveWindow() {
        if (!dlgDrag) return;
        const c = Workspace.cursorPos;
        if (dlgMaximized) {
            // dragging a maximized window restores it under the cursor
            const rel = (dlgDrag.cx - layoutsDialog.x) / Math.max(1, dlgW);
            dlgMaximized = false;
            if (dlgSaved) { dlgW = dlgSaved.w; dlgH = dlgSaved.h; }
            dlgDrag = { cx: c.x, cy: c.y, x: Math.round(c.x - dlgW * rel), y: layoutsDialog.y, w: dlgW, h: dlgH };
        }
        layoutsDialog.x = Math.round(dlgDrag.x + c.x - dlgDrag.cx);
        layoutsDialog.y = Math.round(Math.max(virtGeo.y, dlgDrag.y + c.y - dlgDrag.cy));
    }

    function resizeWindow(mode) {
        if (!dlgDrag) return;
        const c = Workspace.cursorPos;
        if (mode & 1) dlgW = Math.max(dlgMinW, Math.round(dlgDrag.w + c.x - dlgDrag.cx));
        if (mode & 2) dlgH = Math.max(dlgMinH, Math.round(dlgDrag.h + c.y - dlgDrag.cy));
    }

    function toggleMaximize() {
        if (!dlgMaximized) {
            dlgSaved = { x: layoutsDialog.x, y: layoutsDialog.y, w: dlgW, h: dlgH };
            refreshScreen(outputAt(Qt.point(layoutsDialog.x + 20, layoutsDialog.y + 20)));
            dlgW = areaGeo.width;
            dlgH = areaGeo.height;
            layoutsDialog.x = areaGeo.x;
            layoutsDialog.y = areaGeo.y;
            dlgMaximized = true;
        } else {
            dlgMaximized = false;
            if (dlgSaved) {
                dlgW = dlgSaved.w; dlgH = dlgSaved.h;
                layoutsDialog.x = dlgSaved.x; layoutsDialog.y = dlgSaved.y;
            }
        }
    }

    // ------------------------------------------------------ window decoration
    // Read when the editor opens and checked again every second while it is open.
    property string decoLibrary: "org.kde.breeze"
    property string decoTheme: ""
    property string buttonsLeft: "MS"
    property string buttonsRight: "HIAX"
    // only an Aurorae decoration has SVG buttons we can draw ourselves
    readonly property string auroraeName: decoLibrary.indexOf("org.kde.kwin.aurorae") === 0
                                          && decoTheme.indexOf("__aurorae__svg__") === 0
                                          ? decoTheme.slice("__aurorae__svg__".length) : ""

    // KWin reads kwinrc as a cascade, just like every KConfig file:
    //   ~/.config/kwinrc            (what the user changed)
    //   ~/.config/kdedefaults/kwinrc (written by the active Global Theme)
    //   /etc/xdg/kwinrc             (distribution defaults)
    // The first file that has a key wins. A Global Theme puts its window
    // decoration into kdedefaults, so reading only kwinrc misses it.
    readonly property string configHome: String(StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)).replace(/^file:\/\//, "")
    Settings { id: decoUser;     location: "file://" + root.configHome + "/kwinrc";             category: "org.kde.kdecoration2" }
    Settings { id: decoDefaults; location: "file://" + root.configHome + "/kdedefaults/kwinrc"; category: "org.kde.kdecoration2" }
    Settings { id: decoSystem;   location: "file:///etc/xdg/kwinrc";                             category: "org.kde.kdecoration2" }

    readonly property string missing: "\u0001missing"
    function readLayered(key, fallback) {
        const layers = [decoUser, decoDefaults, decoSystem];
        for (let i = 0; i < layers.length; i++) {
            let v = missing;
            try { v = layers[i].value(key, missing); } catch (e) { v = missing; }
            if (v === undefined || v === null) continue;
            if (Array.isArray(v)) v = v.join(",");
            if (String(v) !== missing) return String(v);
        }
        return fallback;
    }

    function readDecoration(quiet) {
        [decoUser, decoDefaults, decoSystem].forEach(function (r) { try { r.sync(); } catch (e) {} });
        const lib = readLayered("library", "org.kde.breeze");
        const th = readLayered("theme", "");
        const bl = readLayered("ButtonsOnLeft", "MS");
        const br = readLayered("ButtonsOnRight", "HIAX");
        const before = [lib === decoLibrary, th === decoTheme, bl === buttonsLeft, br === buttonsRight].every(Boolean)
                       ? [titleBarHeight, decoButtonH, decoMaxW, decoCloseW, titleAlign, titleFont.toString()].join() : "";
        decoLibrary = lib; decoTheme = th; buttonsLeft = bl; buttonsRight = br;
        readMetrics();
        readKdeOptions();   // button size or font can change without the theme changing
        if (quiet && before === [titleBarHeight, decoButtonH, decoMaxW, decoCloseW, titleAlign, titleFont.toString()].join()) return;
        console.info("[kdesnaplayout] decoration:", lib, th || "(no theme)", "left:", bl, "right:", br,
                     "title bar:", titleBarHeight, "buttons:", decoMaxW + "/" + decoCloseW + "x" + decoButtonH);
    }

    // ---------------------------------------------- KDE's own drag helpers
    // KWin can maximize/tile windows at screen edges and snap them by itself.
    // The editor points that out, because both then react to the same drag.
    property bool kdeMaximizeTop: true
    property bool kdeQuickTile: true
    property int kdeWindowSnap: 10
    property int kdeBorderSnap: 10
    Settings { id: kwUser;     location: "file://" + root.configHome + "/kwinrc" }
    Settings { id: kwDefaults; location: "file://" + root.configHome + "/kdedefaults/kwinrc" }
    Settings { id: kwSystem;   location: "file:///etc/xdg/kwinrc" }
    // ---------------------------------------- KDE's own edge tiling and snapping
    // KWin's Options can be changed at runtime without touching kwinrc. While
    // this script runs, KDE's quick tiling (with its outline) and its snap
    // zones are paused; switched off, unloaded or removed, KDE's own values
    // are back - KWin reads them from kwinrc again at the next start anyway.
    property var kdeSaved: null
    property bool kdeApplying: false

    function kdeWanted() {
        const edges = cfg.kdeEdgesOff && (cfg.snapEnabled || cfg.edgeEnabled);
        const snap = cfg.kdeSnapOff && cfg.magnetEnabled;
        return {
            max: edges ? false : kdeSaved.max,
            tile: edges ? false : kdeSaved.tile,
            win: snap ? 0 : kdeSaved.win,
            border: snap ? 0 : kdeSaved.border,
            center: snap ? 0 : kdeSaved.center
        };
    }

    function applyKdeOverrides() {
        if (typeof Options === "undefined" || !Options) return;
        try {
            if (!kdeSaved) kdeSaved = {
                max: Options.electricBorderMaximize, tile: Options.electricBorderTiling,
                win: Options.windowSnapZone, border: Options.borderSnapZone, center: Options.centerSnapZone
            };
            const v = kdeWanted();
            kdeApplying = true;
            if (Options.electricBorderMaximize !== v.max) Options.electricBorderMaximize = v.max;
            if (Options.electricBorderTiling !== v.tile) Options.electricBorderTiling = v.tile;
            if (Options.windowSnapZone !== v.win) Options.windowSnapZone = v.win;
            if (Options.borderSnapZone !== v.border) Options.borderSnapZone = v.border;
            if (Options.centerSnapZone !== v.center) Options.centerSnapZone = v.center;
        } catch (e) {
            console.log("[kdesnaplayout] could not change KDE's options:", e);
        }
        kdeApplying = false;
    }

    function restoreKdeOptions() {
        if (!kdeSaved || typeof Options === "undefined" || !Options) return;
        try {
            kdeApplying = true;
            Options.electricBorderMaximize = kdeSaved.max;
            Options.electricBorderTiling = kdeSaved.tile;
            Options.windowSnapZone = kdeSaved.win;
            Options.borderSnapZone = kdeSaved.border;
            Options.centerSnapZone = kdeSaved.center;
        } catch (e) {}
        kdeApplying = false;
    }

    // KWin reloaded its settings (e.g. changed in System Settings): those are
    // the user's real values now, keep them and pause them again
    Timer {
        id: kdeReapply
        interval: 200
        onTriggered: {
            if (root.kdeSaved && typeof Options !== "undefined" && Options) {
                const v = root.kdeWanted();
                if (Options.electricBorderMaximize !== v.max) root.kdeSaved.max = Options.electricBorderMaximize;
                if (Options.electricBorderTiling !== v.tile) root.kdeSaved.tile = Options.electricBorderTiling;
                if (Options.windowSnapZone !== v.win) root.kdeSaved.win = Options.windowSnapZone;
                if (Options.borderSnapZone !== v.border) root.kdeSaved.border = Options.borderSnapZone;
                if (Options.centerSnapZone !== v.center) root.kdeSaved.center = Options.centerSnapZone;
            }
            root.applyKdeOverrides();
        }
    }
    Connections {
        target: typeof Options !== "undefined" ? Options : null
        ignoreUnknownSignals: true
        function onElectricBorderMaximizeChanged() { if (!root.kdeApplying) kdeReapply.restart(); }
        function onElectricBorderTilingChanged() { if (!root.kdeApplying) kdeReapply.restart(); }
        function onWindowSnapZoneChanged() { if (!root.kdeApplying) kdeReapply.restart(); }
        function onBorderSnapZoneChanged() { if (!root.kdeApplying) kdeReapply.restart(); }
        function onCenterSnapZoneChanged() { if (!root.kdeApplying) kdeReapply.restart(); }
    }
    Connections {
        target: cfg
        function onKdeEdgesOffChanged() { root.applyKdeOverrides(); }
        function onKdeSnapOffChanged() { root.applyKdeOverrides(); }
        function onSnapEnabledChanged() { root.applyKdeOverrides(); }
        function onEdgeEnabledChanged() { root.applyKdeOverrides(); }
        function onMagnetEnabledChanged() { root.applyKdeOverrides(); }
    }

    function readKdeOptions() {
        const l = [kwUser, kwDefaults, kwSystem];
        l.forEach(function (r) { try { r.sync(); } catch (e) {} });
        const yes = function (v) { return String(v).toLowerCase() !== "false"; };
        kdeMaximizeTop = yes(readFrom(l, "Windows/ElectricBorderMaximize", "true"));
        kdeQuickTile = yes(readFrom(l, "Windows/ElectricBorderTiling", "true"));
        kdeWindowSnap = parseInt(readFrom(l, "Windows/WindowSnapZone", "10")) || 0;
        kdeBorderSnap = parseInt(readFrom(l, "Windows/BorderSnapZone", "10")) || 0;
    }

    // ------------------------------------------------ title bar measurements
    // The editor draws its own title bar, so it copies the sizes the real
    // decoration uses: height, button size and spacing, font and alignment.
    property int titleBarHeight: 32
    property int decoButtonH: 22
    property int decoMaxW: 22
    property int decoCloseW: 22
    property int decoButtonTop: 5
    property int decoSpacing: 4
    property int decoEdgeLeft: 8
    property int decoEdgeRight: 8
    property int titleGapLeft: 6
    property int titleGapRight: 6
    property string titleAlign: "center"      // left, center, right
    property color titleColor: "transparent"  // transparent = system text color
    property font titleFont: Qt.application.font

    readonly property string dataHome: String(StandardPaths.writableLocation(StandardPaths.GenericDataLocation)).replace(/^file:\/\//, "")
    function auroraeRc(dir) { return "file://" + dir + "/aurorae/themes/" + auroraeName + "/" + auroraeName + "rc"; }

    // generic layered reader: [Settings...], "Group/Key". Keys of an INI
    // [General] group have no prefix, QSettings treats that group as top level.
    function readFrom(layers, key, fallback) {
        for (let i = 0; i < layers.length; i++) {
            let v = missing;
            try { v = layers[i].value(key, missing); } catch (e) { v = missing; }
            if (v === undefined || v === null) continue;
            if (Array.isArray(v)) v = v.join(",");
            if (String(v) !== missing) return String(v);
        }
        return fallback;
    }

    // the theme's own rc file, wherever it is installed
    Settings { id: aurHome;  location: root.auroraeRc(root.dataHome) }
    Settings { id: aurLocal; location: root.auroraeRc("/usr/local/share") }
    Settings { id: aurSys;   location: root.auroraeRc("/usr/share") }
    // "Button size" from the decoration settings page (Aurorae)
    Settings { id: aurCfgUser;     location: "file://" + root.configHome + "/auroraerc" }
    Settings { id: aurCfgDefaults; location: "file://" + root.configHome + "/kdedefaults/auroraerc" }
    // Breeze keeps its options in breezerc
    Settings { id: breezeUser;     location: "file://" + root.configHome + "/breezerc" }
    Settings { id: breezeDefaults; location: "file://" + root.configHome + "/kdedefaults/breezerc" }
    // title font
    Settings { id: globalsUser;     location: "file://" + root.configHome + "/kdeglobals" }
    Settings { id: globalsDefaults; location: "file://" + root.configHome + "/kdedefaults/kdeglobals" }
    Settings { id: globalsSystem;   location: "file:///etc/xdg/kdeglobals" }

    FontMetrics { id: titleMetrics; font: root.titleFont }

    // "Noto Sans,10,-1,5,700,0,..." (Qt 6) or "...,5,75,..." (Qt 5)
    function parseFont(s) {
        const f = Qt.font({ family: Qt.application.font.family, pointSize: Qt.application.font.pointSize });
        const p = String(s || "").split(",");
        if (p.length < 2 || !p[0]) return f;
        f.family = p[0];
        const size = parseFloat(p[1]);
        if (size > 0) f.pointSize = size;
        else if (parseInt(p[2]) > 0) f.pixelSize = parseInt(p[2]);
        let w = parseInt(p[4]);
        if (w > 0) {
            if (w <= 99) w = w >= 75 ? 700 : (w >= 63 ? 600 : (w >= 57 ? 500 : 400));   // Qt 5 scale
            f.weight = w;
        }
        if (p[5] === "1") f.italic = true;
        return f;
    }

    function readMetrics() {
        const all = [aurHome, aurLocal, aurSys, aurCfgUser, aurCfgDefaults, breezeUser, breezeDefaults,
                     globalsUser, globalsDefaults, globalsSystem];
        all.forEach(function (r) { try { r.sync(); } catch (e) {} });

        const g = [globalsUser, globalsDefaults, globalsSystem];
        titleFont = parseFont(readFrom(g, "WM/activeFont", readFrom(g, "font", "")));
        const unit = Math.max(8, Math.round(titleMetrics.tightBoundingRect("M").height));   // KDecoration's gridUnit
        const small = Math.max(2, Math.floor(unit / 4));                                 // and smallSpacing

        if (auroraeName) {
            const t = [aurHome, aurLocal, aurSys];
            const num = function (k, d) { const v = parseFloat(readFrom(t, "Layout/" + k, "")); return isNaN(v) ? d : v; };
            // ButtonSize is stored with an offset of 2 to KDecoration's BorderSize enum
            const sizeIdx = parseInt(readFrom([aurCfgUser, aurCfgDefaults], auroraeName + "/ButtonSize", "1"));
            const factor = [0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0][isNaN(sizeIdx) ? 1 : Math.max(0, Math.min(6, sizeIdx))];

            const bw = num("ButtonWidth", 20), bh = num("ButtonHeight", 20);
            const top = num("TitleEdgeTop", 5), bottom = num("TitleEdgeBottom", 5);
            const marginTop = num("ButtonMarginTop", 0);
            decoButtonH = Math.round(bh * factor);
            decoMaxW = Math.round(num("ButtonWidthMaximizeRestore", bw) * factor);
            decoCloseW = Math.round(num("ButtonWidthClose", bw) * factor);
            decoSpacing = Math.round(num("ButtonSpacing", 5) * factor);
            decoEdgeLeft = num("TitleEdgeLeft", 5);
            decoEdgeRight = num("TitleEdgeRight", 5);
            titleGapLeft = num("TitleBorderLeft", 5);
            titleGapRight = num("TitleBorderRight", 5);
            titleBarHeight = Math.round(top + Math.max(num("TitleHeight", 20), decoButtonH + marginTop) + bottom);
            decoButtonTop = Math.round(top + marginTop);

            const al = readFrom(t, "TitleAlignment", "Left").toLowerCase();
            titleAlign = al === "center" ? "center" : (al === "right" ? "right" : "left");
            const c = readFrom(t, "ActiveTextColor", "").split(",").map(Number);
            titleColor = c.length >= 3 && !c.some(isNaN)
                         ? Qt.rgba(c[0] / 255, c[1] / 255, c[2] / 255, c.length > 3 ? c[3] / 255 : 1) : "transparent";
        } else {
            // Breeze style metrics: buttons are a multiple of the font's grid unit
            const b = [breezeUser, breezeDefaults];
            const isBreeze = decoLibrary === "org.kde.breeze";
            const bs = isBreeze ? readFrom(b, "Windeco/ButtonSize", "ButtonDefault") : "ButtonDefault";
            const mult = { ButtonTiny: 1, ButtonSmall: 1.5, ButtonDefault: 2, ButtonLarge: 2.5, ButtonVeryLarge: 3.5 }[bs] || 2;
            decoButtonH = decoMaxW = decoCloseW = Math.round(unit * mult);
            // Breeze: 2 x smallSpacing above, below and between the buttons
            decoSpacing = 2 * small;
            decoEdgeLeft = decoEdgeRight = 2 * small;
            titleGapLeft = titleGapRight = 2 * small;
            titleBarHeight = Math.max(decoButtonH, Math.ceil(titleMetrics.height)) + 4 * small;
            decoButtonTop = Math.round((titleBarHeight - decoButtonH) / 2);
            const al = isBreeze ? readFrom(b, "Windeco/TitleAlignment", "AlignCenterFullWidth") : "AlignCenterFullWidth";
            titleAlign = al === "AlignLeft" ? "left" : (al === "AlignRight" ? "right" : "center");
            titleColor = "transparent";
        }
    }

    // ------------------------------------------------- quick menu (gear icon)
    // System Settings writes the quick menu into kwinrc but neither restarts
    // the script nor refreshes KWin.readConfig(). So kwinrc is polled directly.
    // Flipping "OpenSettings" (the big button) opens the editor.
    Settings {
        id: kwinrcReader
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/kwinrc"
        category: "Script-kdesnaplayout"
        // no properties on purpose: nothing ever gets written to kwinrc
    }

    function readOpenFlag() {
        try { kwinrcReader.sync(); } catch (e) {}
        let v = false;
        try { v = kwinrcReader.value("OpenSettings", false); } catch (e) { v = false; }
        return v === true || String(v).toLowerCase() === "true";
    }

    function checkOpenRequest() {
        const flag = readOpenFlag();
        if (flag === cfg.lastOpenFlag) return false;
        cfg.lastOpenFlag = flag;
        try { cfg.sync(); } catch (e) {}
        return true;
    }

    // The quick menu also has the color scheme switch. Only a change there
    // is applied, so the editor's own choice isn't overwritten every second.
    function checkGearTheme() {
        let v = -1;
        try { v = Number(kwinrcReader.value("themeMode", 0)); } catch (e) { v = -1; }
        if (isNaN(v) || v < 0 || v > 2) return;
        if (cfg.lastGearTheme === -1) { cfg.lastGearTheme = v; return; }
        if (v !== cfg.lastGearTheme) {
            cfg.lastGearTheme = v;
            cfg.themeMode = v;
            try { cfg.sync(); } catch (e) {}
        }
    }

    // ------------------------------------------------------------------ timers
    Timer {
        id: showTimer
        interval: Math.max(0, cfg.showDelay)
        onTriggered: if (root.dragWin || root.demoMode) root.barState = 2
    }
    Timer {
        id: hideTimer
        interval: Math.max(0, cfg.hideDelay)
        onTriggered: {
            root.setHover(-1, -1);
            root.barState = 0;
            root.updateDrag();       // may bring the handle back if still near the top
        }
    }
    Timer {
        id: edgeTimer
        interval: Math.max(0, cfg.edgeDelay)
        onTriggered: if (root.dragWin && root.edgePending) {
            root.edgeActive = root.edgePending; root.updatePreview(); root.startFillTimer();
        }
    }
    // second stage: still at the edge after edgeFillDelay
    Timer {
        id: fillTimer
        interval: Math.max(100, cfg.edgeFillDelay)
        onTriggered: if (root.dragWin && root.edgeActive && root.edgeActive === root.edgePending) {
            root.edgeStage = 2; root.updatePreview();
        }
    }
    function startFillTimer() { if (cfg.edgeFill) fillTimer.restart(); }
    Timer {
        id: closeTimer
        interval: Math.max(cfg.slideOutDuration, 0) + 80
        onTriggered: if (!root.dragWin && !root.demoMode) {
            overlay.visible = false;
            root.barExpanded = false;
        }
    }
    Timer {
        id: reapplyTimer
        interval: 50
        repeat: true
        onTriggered: {
            const w = root.pendingWin;
            if (!w) { stop(); return; }
            try {
                if (!root.sameRect(w.frameGeometry, root.pendingRect)) {
                    if (w.maximizable) w.setMaximize(false, false);
                    w.frameGeometry = root.pendingRect;
                }
            } catch (e) { root.pendingWin = null; stop(); return; }
            if (++root.reapplyCount >= 5) { root.pendingWin = null; stop(); }
        }
    }
    // demo: handle -> open bar -> walk over a few layouts -> slide away
    Timer {
        id: demoStep
        property int step: 0
        interval: 60
        repeat: true
        onTriggered: {
            step++;
            if (step === 1) {
                root.barState = cfg.twoStage ? 1 : 2;
                interval = cfg.twoStage ? 500 : Math.max(cfg.slideInDuration, 200);
            } else if (step === 2) {
                root.barState = 2;
                interval = Math.max(cfg.slideInDuration, 200) + 250;
            } else if (step >= 3 && step < 3 + Math.min(4, root.barLayouts.length)) {
                root.setHover(step - 3, 0);
                interval = 380;
            } else {
                root.setHover(-1, -1);
                root.barState = 0;
                root.demoMode = false;
                stop();
                closeTimer.restart();
            }
        }
    }

    // --------------------------------------------------------- workspace hooks
    Connections {
        target: Workspace
        function onWindowAdded(w) { root.hookWindow(w); }
        function onWindowRemoved(w) {
            const id = String(w.internalId);
            delete root.hooked[id];
            delete root.hookFns[id];
            delete root.snapped[id];
            if (root.pendingWin === w) root.pendingWin = null;
            if (root.dragWin === w) root.endDrag();
            if (root.resizeWin === w) { root.stickyEnd(false); root.resizeWin = null; root.resizeStart = null; }
            root.stickyLinks = root.stickyLinks.filter(function (k) { return k.w !== w; });
            root.stickyFaded = root.stickyFaded.filter(function (f) { return f.w !== w; });
        }
        function onCursorPosChanged() { if (root.dragWin) root.updateDrag(); }
        function onScreensChanged() { root.refreshVirtual(); }
    }

    // ------------------------------------------------------- keyboard shortcuts
    // Every action is a KWin global shortcut. The sequence here is only the
    // default; KDE keeps the user's choice (System Settings → Shortcuts, or the
    // Keyboard page of the editor, which talks to kglobalaccel directly).
    function shortcutText(a) { return I.tr("SeaQ Snap Layout: %1", I.tr(a.text)); }

    Instantiator {
        model: K.ACTIONS
        delegate: ShortcutHandler {
            required property var modelData
            name: modelData.id
            text: root.shortcutText(modelData)
            sequence: K.defaultText(modelData)
            onActivated: root.runAction(modelData.id)
        }
    }

    property alias shortcuts: shortcutService
    ShortcutService { id: shortcutService }

    function toggleSetting(key) {
        cfg[key] = !cfg[key];
        try { cfg.sync(); } catch (e) {}
    }

    function isMaximized(w, area) {
        return sameRect(w.frameGeometry, area);
    }

    function runAction(id) {
        if (!cfg.keysEnabled) return;
        if (id === "KDESnapLayoutToggle") return toggleSetting("snapEnabled");
        if (id === "KDESnapLayoutToggleEdges") return toggleSetting("edgeEnabled");
        if (id === "KDESnapLayoutToggleMagnet") return toggleSetting("magnetEnabled");
        if (id === "KDESnapLayoutDemo") return demoBar();

        const w = Workspace.activeWindow;
        if (!isEligible(w)) return;
        // a geometry still being re-applied from an earlier snap must not
        // undo what this key does
        if (pendingWin === w) { reapplyTimer.stop(); pendingWin = null; }
        const area = areaOf(w);
        const g = w.frameGeometry;
        const key = String(w.internalId);
        const rec = snapped[key];
        const inPlace = rec && sameRect(g, rec.rect);
        // the size to come back to: the one before the first snap
        const pre = inPlace ? { w: rec.w, h: rec.h } : (isMaximized(w, area) ? null : { w: g.width, h: g.height });

        if (K.ZONES[id]) {
            snapWindowRect(w, L.targetRect(area, K.ZONES[id], cfg.windowGap, cfg.edgeMargin), pre);
        } else if (id === "KDESnapLayoutMaximize") {
            try { w.setMaximize(!isMaximized(w, area), !isMaximized(w, area)); } catch (e) {}
        } else if (id === "KDESnapLayoutCenter") {
            let cw = g.width, ch = g.height;
            if (cw > area.width * 0.9 || ch > area.height * 0.9) { cw = Math.round(area.width * 2 / 3); ch = Math.round(area.height * 2 / 3); }
            try { if (isMaximized(w, area)) w.setMaximize(false, false); } catch (e) {}
            w.frameGeometry = Qt.rect(Math.round(area.x + (area.width - cw) / 2), Math.round(area.y + (area.height - ch) / 2), cw, ch);
            delete snapped[key];
        } else if (id === "KDESnapLayoutRestore") {
            if (inPlace) {
                const cx = g.x + g.width / 2, cy = g.y + g.height / 2;
                let x = Math.round(cx - rec.w / 2), y = Math.round(cy - rec.h / 2);
                x = Math.max(area.x, Math.min(x, area.x + area.width - rec.w));
                y = Math.max(area.y, Math.min(y, area.y + area.height - rec.h));
                w.frameGeometry = Qt.rect(x, y, rec.w, rec.h);
                delete snapped[key];
            } else if (isMaximized(w, area)) {
                try { w.setMaximize(false, false); } catch (e) {}
            }
        }
    }

    Component.onCompleted: {
        loadLayouts();
        refreshVirtual();
        refreshScreen(Workspace.activeScreen);
        readDecoration();
        const list = Workspace.stackingOrder;
        for (let i = 0; i < list.length; i++) hookWindow(list[i]);
        if (checkOpenRequest()) openTimer.start();
        checkGearTheme();
        applyKdeOverrides();
        kwinrcWatch.start();
    }

    Timer {
        id: kwinrcWatch
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.checkOpenRequest()) root.openSettings();
            root.checkGearTheme();
            // pick up a changed window decoration while the editor is open
            if (layoutsDialog.visible) root.readDecoration(true);
        }
    }

    Timer {                       // give KWin a moment after startup
        id: openTimer
        interval: 400
        onTriggered: root.openSettings()
    }

    // ----------------------------------------------------------------- overlay
    // Click-through layer above everything, covering all screens.
    PlasmaCore.Dialog {
        id: overlay
        title: "SeaQ Snap Layout"
        location: PlasmaCore.Types.Desktop
        type: PlasmaCore.Dialog.OnScreenDisplay
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.Popup
        hideOnWindowDeactivate: true
        outputOnly: true
        visible: false

        Item {
            id: overlayRoot
            width: root.virtGeo.width
            height: root.virtGeo.height

            Item {
                id: screenItem
                x: root.scrGeo.x - root.virtGeo.x
                y: root.scrGeo.y - root.virtGeo.y
                width: root.scrGeo.width
                height: root.scrGeo.height
                clip: true

                // where the window will land
                Rectangle {
                    id: preview
                    x: root.previewRect.x
                    y: root.previewRect.y
                    width: root.previewRect.width
                    height: root.previewRect.height
                    radius: 8
                    // accent colored, or neutral when the user turned the accent off
                    readonly property color tint: cfg.previewAccent ? theme.accent : (theme.dark ? "#ffffff" : "#202020")
                    color: Qt.rgba(tint.r, tint.g, tint.b, cfg.previewAccent ? 0.22 : 0.14)
                    border.width: 2
                    border.color: Qt.rgba(tint.r, tint.g, tint.b, cfg.previewAccent ? 0.85 : 0.45)
                    opacity: root.previewVisible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Behavior on x      { enabled: preview.opacity > 0.05; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on y      { enabled: preview.opacity > 0.05; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on width  { enabled: preview.opacity > 0.05; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on height { enabled: preview.opacity > 0.05; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }

                SnapBar {
                    id: snapBar
                    objectName: "snapBar"
                    layouts: root.barLayouts
                    theme: root.pal
                    uiScale: cfg.barScale / 100
                    thumbW: cfg.thumbWidth
                    aspect: root.screenAspect
                    perRow: cfg.perRow
                    cornerR: cfg.cornerRadius
                    bgOpacity: cfg.barOpacity / 100
                    hoverLayout: root.hoverLayout
                    hoverZone: root.hoverZone
                    showName: cfg.showLayoutName
                    expanded: root.barExpanded
                    animDuration: cfg.slideInDuration
                    easingType: root.easingType
                    x: Math.round((screenItem.width - width) / 2)
                    y: -200
                    opacity: 0
                }

                NumberAnimation { id: slideAnim; target: snapBar; property: "y" }
                NumberAnimation { id: fadeAnim; target: snapBar; property: "opacity" }
            }
        }
    }

    // ----------------------------------------------------------- editor window
    PlasmaCore.Dialog {
        id: layoutsDialog
        title: I.tr("SeaQ Snap Layout – Settings editor")
        location: PlasmaCore.Types.Floating
        type: PlasmaCore.Dialog.Normal
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        hideOnWindowDeactivate: false
        visible: false

        Item {
            width: root.dlgW
            height: root.dlgH

            // system colors for every control in the editor (see SystemColors.qml);
            // if Kirigami is missing the page simply stays where it is
            id: editorHost
            Component {
                id: pageComponent
                SettingsPage {
                    anchors.fill: parent
                    app: root
                    framed: true
                    onCloseRequested: root.closeSettings()
                }
            }
            // the page is created inside the color box, so every control
            // picks up the colors from the start
            Loader {
                id: colorBox
                anchors.fill: parent
                source: "SystemColors.qml"
                onLoaded: { item.app = root; pageComponent.createObject(item, { app: root }); }
                onStatusChanged: if (status === Loader.Error) {
                    console.warn("[kdesnaplayout] Kirigami not found, controls use the Qt palette only");
                    pageComponent.createObject(editorHost, { app: root });
                }
            }
        }
    }
}
