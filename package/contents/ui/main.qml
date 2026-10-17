import QtQuick
import QtCore
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore
import "../code/layouts.js" as L
import "../code/i18n.js" as I

// KDE Snap Layout
// Drag a window towards the top edge, the snap bar slides down, drop the
// window on a zone and it gets resized into place.
Item {
    id: root

    readonly property string version: "1.6.5"
    readonly property string author: "Swenix-dev"

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
        easingStyle: 0, fadeEnabled: true, editorSnapping: true
    })
    readonly property var groupGeneral: ["snapEnabled", "showPreview", "restoreSize", "windowGap", "edgeMargin"]
    readonly property var groupAppearance: ["themeMode", "useSystemAccent", "customAccent", "barOpacity",
        "barScale", "thumbWidth", "cornerRadius", "perRow", "showLayoutName"]
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
            stepped: function () { if (root && root.dragWin === w) root.updateDrag(); },
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

    Component.onDestruction: unhookAll()

    function onMoveStarted(w) {
        if (!cfg.snapEnabled || !w.move || !isEligible(w)) return;
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
        setHover(-1, -1);
        barState = 0;
        refreshScreen(outputAt(Workspace.cursorPos));
        overlayShow();
        updateDrag();
    }

    function onMoveFinished(w) {
        if (w !== dragWin) return;
        const li = hoverLayout, zi = hoverZone;
        const area = Qt.rect(areaGeo.x, areaGeo.y, areaGeo.width, areaGeo.height);
        const z = (barState === 2 && zi >= 0 && li >= 0 && li < barLayouts.length) ? barLayouts[li].zones[zi] : null;
        endDrag();
        if (z) snapWindow(w, z, area);
    }

    function endDrag() {
        dragWin = null;
        showTimer.stop();
        hideTimer.stop();
        barState = 0;
        setHover(-1, -1);
        closeTimer.restart();
    }

    function snapWindow(w, z, area) {
        const r = L.targetRect(area, z, cfg.windowGap, cfg.edgeMargin);
        const rect = Qt.rect(r.x, r.y, r.width, r.height);
        try { if (w.maximizable) w.setMaximize(false, false); } catch (e) {}
        w.frameGeometry = rect;
        const pre = dragStartSize || { w: rect.width, h: rect.height };
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

        const relY = p.y - areaGeo.y;
        const relX = p.x - scrGeo.x;
        const half = scrGeo.width * cfg.activationWidth / 200;
        const inX = Math.abs(relX - scrGeo.width / 2) <= half;

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
        if (zi >= 0 && li >= 0 && li < barLayouts.length && cfg.showPreview) {
            const r = L.targetRect(areaGeo, barLayouts[li].zones[zi], cfg.windowGap, cfg.edgeMargin);
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
    property int dlgW: 1000
    property int dlgH: 720
    property bool dlgMaximized: false
    property var dlgSaved: null
    property var dlgDrag: null
    readonly property int dlgMinW: 760
    readonly property int dlgMinH: 480

    function openSettings() {
        readDecoration();
        if (layoutsDialog.visible) {
            try { layoutsDialog.raise(); layoutsDialog.requestActivate(); } catch (e) {}
            return;
        }
        refreshScreen(outputAt(Workspace.cursorPos));
        dlgMaximized = false;
        dlgW = Math.min(areaGeo.width, Math.max(dlgMinW, Math.min(1040, Math.round(areaGeo.width * 0.9))));
        dlgH = Math.min(areaGeo.height, Math.max(dlgMinH, Math.min(760, Math.round(areaGeo.height * 0.9))));
        layoutsDialog.x = Math.round(areaGeo.x + (areaGeo.width - dlgW) / 2);
        layoutsDialog.y = Math.round(areaGeo.y + (areaGeo.height - dlgH) / 2);
        layoutsDialog.visible = true;
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
        readMetrics();   // button size or font can change without the theme changing
        if (quiet && before === [titleBarHeight, decoButtonH, decoMaxW, decoCloseW, titleAlign, titleFont.toString()].join()) return;
        console.info("[kdesnaplayout] decoration:", lib, th || "(no theme)", "left:", bl, "right:", br,
                     "title bar:", titleBarHeight, "buttons:", decoMaxW + "/" + decoCloseW + "x" + decoButtonH);
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
        }
        function onCursorPosChanged() { if (root.dragWin) root.updateDrag(); }
        function onScreensChanged() { root.refreshVirtual(); }
    }

    ShortcutHandler {
        name: "KDESnapLayoutToggle"
        text: I.tr("KDE Snap Layout: turn on/off")
        sequence: ""
        onActivated: { cfg.snapEnabled = !cfg.snapEnabled; try { cfg.sync(); } catch (e) {} }
    }
    ShortcutHandler {
        name: "KDESnapLayoutDemo"
        text: I.tr("KDE Snap Layout: test the snap bar")
        sequence: ""
        onActivated: root.demoBar()
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
        title: "KDE Snap Layout"
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
                    color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)
                    border.width: 2
                    border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.85)
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
        title: I.tr("KDE Snap Layout – Settings editor")
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
