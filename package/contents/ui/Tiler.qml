import QtQuick
import org.kde.kwin
import "../code/tiling.js" as T
import "../code/layouts.js" as L
import "../code/i18n.js" as I

// Automatic tiling. Keeps an order of windows per screen and gives every
// window its place from the chosen layout. Windows can float (taken out),
// be swapped or promoted to the main place. Moves are animated.
Item {
    id: tiler
    property var app
    readonly property var cfg: app ? app.settings : null
    readonly property bool active: !!app && app.tilingMode

    property var order: []           // internal ids, first = main window
    property var floating: ({})      // id -> true: the user took it out
    property var placed: ({})        // id -> rect we gave it last time
    property var gone: ({})          // id -> true: closed, never adopt again
    property string lastActive: ""   // last tiled window that had the focus
    property bool applying: false

    function key(w) { return String(w.internalId); }

    function floatApps() {
        return String(cfg.tileFloatApps || "").toLowerCase().split(/[,\s]+/).filter(function (s) { return s !== ""; });
    }

    // windows that take part: normal, resizable, on this desktop, not
    // minimized/fullscreen/closing, not excluded and not floated by the user
    function tileable(w) {
        if (!w || !app) return false;
        try {
            if (w.deleted || gone[key(w)]) return false;
            if (!w.normalWindow || w.transient || w.minimized || w.fullScreen) return false;
            if (w.resizeable === false) return false;
            if (w.skipTaskbar) return false;
            const apps = floatApps();
            if (apps.length) {
                const rc = String(w.resourceClass || "").toLowerCase(), rn = String(w.resourceName || "").toLowerCase();
                for (let i = 0; i < apps.length; i++) if (rc === apps[i] || rn === apps[i]) return false;
            }
        } catch (e) { return false; }
        if (floating[key(w)]) return false;
        if (app.isExcluded(w)) return false;
        return app.onCurrentDesktop(w);
    }

    function isTiled(w) { return active && tileable(w) && order.indexOf(key(w)) >= 0; }

    // where a new window joins: 0 at the end, 1 main place, 2 after the active one
    function insertMode() { return cfg.tileInsert > 0 ? cfg.tileInsert : (cfg.tileNewFirst ? 1 : 0); }

    function track(w) {
        if (!w) return;
        const id = key(w);
        if (order.indexOf(id) >= 0) return;
        const o = order.slice();
        const mode = insertMode();
        const at = o.indexOf(lastActive);
        if (mode === 1) o.unshift(id);
        else if (mode === 2 && at >= 0) o.splice(at + 1, 0, id);
        else o.push(id);
        order = o;
    }
    function untrack(w) {
        const id = key(w);
        order = order.filter(function (x) { return x !== id; });
        const f = Object.assign({}, floating); delete f[id]; floating = f;
        delete placed[id];
        delete anims[id];
        gone[id] = true;
        if (lastActive === id) lastActive = "";
    }

    function revive(w) { try { delete gone[key(w)]; } catch (e) {} }
    function schedule() { if (active) retileTimer.restart(); }
    Timer { id: retileTimer; interval: 30; onTriggered: tiler.retile() }

    // every live window by id (closed windows linger in the stacking order
    // during their close animation – they must not keep their place)
    function byId() {
        const map = {};
        let list = [];
        try { list = Workspace.windowList(); } catch (e) { list = Workspace.stackingOrder || []; }
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            try { if (w && !w.deleted) map[key(w)] = w; } catch (e) {}
        }
        return map;
    }
    function outputKey(w) { try { return w.output ? String(w.output.name) : ""; } catch (e) { return ""; } }

    // windows of one screen in order: [w]
    function windowsOn(outKey, map) {
        map = map || byId();
        const out = [];
        for (let i = 0; i < order.length; i++) {
            const w = map[order[i]];
            if (w && tileable(w) && outputKey(w) === outKey) out.push(w);
        }
        return out;
    }

    // ------------------------------------------------------------ layouts
    // built-in layouts plus the own layouts of the layout builder
    function allLayouts() {
        const out = T.LAYOUTS.map(function (l) { return { id: l.id, text: l.text, own: false }; });
        const m = app.layoutModel;
        for (let i = 0; m && i < m.count; i++) {
            const o = m.get(i);
            if (L.zones(L.parseTree(o.tree)).length >= 2) out.push({ id: "zones:" + o.name, text: o.name, own: true });
        }
        return out;
    }
    function zonesOf(id) {
        if (!T.isZones(id)) return null;
        const name = String(id).substring(6);
        const m = app.layoutModel;
        for (let i = 0; m && i < m.count; i++) {
            const o = m.get(i);
            if (o.name !== name) continue;
            // the biggest zone is the main place, like in the built-in
            // layouts; equal ones go left to right, top to bottom
            return L.zones(L.parseTree(o.tree)).slice().sort(function (a, b) {
                const d = b.w * b.h - a.w * a.h;
                if (Math.abs(d) > 0.0001) return d;
                return Math.abs(a.x - b.x) > 0.0001 ? a.x - b.x : a.y - b.y;
            });
        }
        return null;
    }
    function rules() {
        if (!cfg.tileRulesOn) return [];
        try { return JSON.parse(cfg.tileRules || "[]"); } catch (e) { return []; }
    }
    // the layout for n windows (layout by window count, if switched on)
    function layoutFor(n) {
        const id = T.layoutFor(n, cfg.tileLayout, rules());
        if (T.isZones(id) && !zonesOf(id)) return "tile";     // own layout was deleted
        return id;
    }

    function options(kind) {
        return { margin: cfg.edgeMargin, gap: cfg.windowGap, ratio: cfg.tileRatio / 100, masters: cfg.tileMasters,
                 flip: cfg.tileFlip, single: cfg.tileSingleWidth / 100, singleNoGap: cfg.tileSingleNoGap,
                 zones: zonesOf(kind) };
    }
    function rectsFor(kind, n, area) { return T.arrange(kind, n, area, options(kind)); }

    function areaFor(w) { return app.areaOf(w); }

    // pick up windows that appeared while tiling was off
    function adoptAll() {
        const map = byId();
        for (const id in map) if (tileable(map[id])) track(map[id]);
    }

    function retile() {
        if (!active) return;
        // never pull at a window the user is dragging or resizing
        if (app.dragWin || app.resizeWin) { retileTimer.restart(); return; }
        adoptAll();
        const done = {};
        const map = byId();
        // drop ids of windows that are gone
        order = order.filter(function (id) { return !!map[id]; });
        applying = true;
        const laid = {};
        for (let i = 0; i < order.length; i++) {
            const w = map[order[i]];
            if (!w || !tileable(w)) continue;
            const ok = outputKey(w);
            if (done[ok]) continue;
            done[ok] = true;
            const list = windowsOn(ok, map);
            const rects = rectsFor(layoutFor(list.length), list.length, areaFor(w));
            for (let j = 0; j < list.length; j++) { place(list[j], rects[j]); laid[key(list[j])] = true; }
            // "one at a time": the active window stays in front
            if (layoutFor(list.length) === "monocle") {
                const aw = Workspace.activeWindow;
                try { if (aw && list.indexOf(aw) >= 0) Workspace.raiseWindow(aw); } catch (e) {}
            }
        }
        laidOut = laid;
        applying = false;
    }

    function place(w, r) {
        if (!r) return;
        const rc = Qt.rect(Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height));
        try { if (w.tile) w.tile = null; } catch (e) {}
        try { if (app.isMaximized(w, app.areaOf(w))) w.setMaximize(false, false); } catch (e) {}
        const id = key(w);
        // only windows that were in the last layout glide; one that just came
        // back (restored from the taskbar, new, other desktop) is set at once –
        // KWin's restore animation is still running and must not be disturbed
        const known = !!laidOut[id];
        placed[id] = { x: rc.x, y: rc.y, width: rc.width, height: rc.height };
        delete app.snapped[id];
        const now = anims[id] ? anims[id].to : w.frameGeometry;
        if (app.sameRect(now, rc)) return;
        // a new window appears right in its place; the others glide
        if (known && cfg.tileAnimate && cfg.tileAnimMs > 0 && app.dragWin !== w && app.resizeWin !== w) animate(w, rc);
        else { delete anims[id]; w.frameGeometry = rc; }
    }

    // ---------------------------------------------------------- animation
    // Apps redraw slowly when their size changes every frame – that made the
    // windows wobble. So the size changes once, right away, and only the
    // position glides (ease out). The edge that moves least stays put at the
    // start, so the window does not first jump somewhere else.
    property var anims: ({})
    property var laidOut: ({})       // ids placed by the last retile
    function animate(w, to) {
        const g = w.frameGeometry;
        let sx = g.x, sy = g.y;
        if (Math.round(g.width) !== to.width || Math.round(g.height) !== to.height) {
            sx = to.x >= g.x ? g.x : g.x + g.width - to.width;
            sy = to.y >= g.y ? g.y : g.y + g.height - to.height;
            // never start further away than the target is
            sx = Math.round(Math.min(Math.max(sx, Math.min(g.x, to.x)), Math.max(g.x, to.x)));
            sy = Math.round(Math.min(Math.max(sy, Math.min(g.y, to.y)), Math.max(g.y, to.y)));
            w.frameGeometry = Qt.rect(sx, sy, to.width, to.height);
        }
        if (sx === to.x && sy === to.y) { delete anims[key(w)]; return; }
        anims[key(w)] = { w: w, from: { x: sx, y: sy }, to: to, t0: Date.now() - 16 };
        if (!animTimer.running) { animStep(); animTimer.start(); }
    }
    function animStep() {
        const now = Date.now(), dur = Math.max(1, cfg.tileAnimMs);
        let left = 0;
        for (const id in anims) {
            const a = anims[id];
            const p = Math.min(1, (now - a.t0) / dur);
            const e = 1 - Math.pow(1 - p, 3);
            try {
                if (a.w.deleted) { delete anims[id]; continue; }
                if (p >= 1) { a.w.frameGeometry = a.to; delete anims[id]; continue; }
                a.w.frameGeometry = Qt.rect(Math.round(a.from.x + (a.to.x - a.from.x) * e),
                                            Math.round(a.from.y + (a.to.y - a.from.y) * e),
                                            a.to.width, a.to.height);
                left++;
            } catch (err) { delete anims[id]; }
        }
        if (!left) animTimer.stop();
    }
    Timer { id: animTimer; interval: 16; repeat: true; onTriggered: tiler.animStep() }
    // jump every running glide to its end (no window is left half way)
    function finishAnims() {
        for (const id in anims) { try { if (!anims[id].w.deleted) anims[id].w.frameGeometry = anims[id].to; } catch (e) {} }
        anims = ({});
        animTimer.stop();
    }
    function animating(w) { return !!anims[key(w)]; }

    // ------------------------------------------------------------ actions
    function swap(a, b) {
        const ia = order.indexOf(key(a)), ib = order.indexOf(key(b));
        if (ia < 0 || ib < 0) return false;
        const o = order.slice();
        o[ia] = key(b); o[ib] = key(a);
        order = o;
        retile();
        return true;
    }

    // a takes b's place in the order, b floats where a was
    function replace(a, b) {
        const ib = order.indexOf(key(b));
        if (ib < 0) return;
        const o = order.slice();
        o[ib] = key(a);
        order = o.filter(function (x, i) { return x !== key(a) || i === ib; });
        const f = Object.assign({}, floating); delete f[key(a)]; f[key(b)] = true; floating = f;
        retile();
    }

    function promote(w) {
        if (!isTiled(w)) return;
        const id = key(w);
        const list = windowsOn(outputKey(w));
        if (!list.length) return;
        const first = key(list[0]);
        if (first === id) {
            // already main: swap with the next one, like the classic tilers
            if (list.length > 1) swap(w, list[1]);
            return;
        }
        swap(w, list[0]);
    }

    // one step forward (d = 1) or back (d = -1) in the order of its screen
    function moveInOrder(w, d) {
        if (!isTiled(w)) return;
        const list = windowsOn(outputKey(w));
        const i = list.indexOf(w);
        if (i < 0 || list.length < 2) return;
        swap(w, list[(i + d + list.length) % list.length]);
    }

    function setFloating(w, on) {
        const f = Object.assign({}, floating);
        if (on) f[key(w)] = true; else { delete f[key(w)]; track(w); }
        floating = f;
        delete anims[key(w)];
        schedule();
    }

    function toggleFloat(w) {
        if (!w) return;
        const on = !floating[key(w)];
        setFloating(w, on);
        if (on) {
            // float in the middle at a comfortable size
            const a = app.areaOf(w);
            const cw = Math.round(a.width * 0.6), ch = Math.round(a.height * 0.65);
            w.frameGeometry = Qt.rect(Math.round(a.x + (a.width - cw) / 2), Math.round(a.y + (a.height - ch) / 2), cw, ch);
        }
    }

    function cycleLayout() {
        const all = allLayouts();
        let i = -1;
        for (let k = 0; k < all.length; k++) if (all[k].id === cfg.tileLayout) i = k;
        cfg.tileLayout = all[(i + 1) % all.length].id;
        app.saveSettings();
        retile();
        app.showOsd(app.trLayoutName(cfg.tileLayout));
    }

    function changeRatio(d) {
        cfg.tileRatio = Math.max(15, Math.min(85, cfg.tileRatio + d));
        app.saveSettings();
        retile();
    }

    function changeMasters(d) {
        cfg.tileMasters = Math.max(1, Math.min(4, cfg.tileMasters + d));
        app.saveSettings();
        retile();
        app.showOsd(I.tr("Main windows: %1", cfg.tileMasters));
    }

    // after a hand resize: keep the new main size, put the others back
    function resized(w, r) {
        if (!isTiled(w)) return;
        const list = windowsOn(outputKey(w));
        const idx = list.indexOf(w);
        const kind = layoutFor(list.length);
        const a = areaFor(w), o = options(kind);
        let main = null;
        if (kind === "tile" || kind === "spiral" || kind === "dwindle") {
            const m = kind === "tile" ? Math.min(cfg.tileMasters, list.length) : 1;
            if (idx >= 0 && idx < m) main = r;
            else if (idx >= m) {
                // a stack window: its inner edge is the border of the main area
                main = cfg.tileFlip ? { x: r.x + r.width + o.gap, y: r.y, width: a.x + a.width - o.margin - (r.x + r.width + o.gap), height: r.height }
                                    : { x: a.x + o.margin, y: r.y, width: r.x - o.gap - (a.x + o.margin), height: r.height };
            }
        } else if (kind === "centered" && idx === 0) main = r;
        if (main && list.length > 1) {
            const ratio = T.ratioFrom(kind, main, a, o);
            if (ratio !== null) { cfg.tileRatio = Math.round(ratio * 100); app.saveSettings(); }
        }
        schedule();
    }

    onActiveChanged: if (active) { adoptAll(); retile(); } else { finishAnims(); placed = ({}); laidOut = ({}); }
    Component.onCompleted: if (active) schedule()

    Connections {
        target: tiler.cfg
        function onTileLayoutChanged() { tiler.schedule(); }
        function onTileRatioChanged() { tiler.schedule(); }
        function onTileMastersChanged() { tiler.schedule(); }
        function onTileFlipChanged() { tiler.schedule(); }
        function onTileSingleWidthChanged() { tiler.schedule(); }
        function onTileSingleNoGapChanged() { tiler.schedule(); }
        function onTileRulesOnChanged() { tiler.schedule(); }
        function onTileRulesChanged() { tiler.schedule(); }
        function onTileFloatAppsChanged() { tiler.schedule(); }
        function onWindowGapChanged() { tiler.schedule(); }
        function onEdgeMarginChanged() { tiler.schedule(); }
        function onLayoutsJsonChanged() { tiler.schedule(); }
    }
    Connections {
        target: Workspace
        function onCurrentDesktopChanged() { tiler.schedule(); }
        function onScreensChanged() { tiler.schedule(); }
        function onWindowActivated(w) {
            try { if (w && tiler.order.indexOf(tiler.key(w)) >= 0) tiler.lastActive = tiler.key(w); } catch (e) {}
        }
    }
}
