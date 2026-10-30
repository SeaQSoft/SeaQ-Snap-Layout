.pragma library
// Geometry for the two drag helpers that work without the snap bar:
//   * screen edges: push a window against an edge or corner to tile it
//   * window magnet: edges of a moved or resized window stick to nearby edges
// Rects are plain {x, y, width, height} objects in screen coordinates.

function rect(x, y, w, h) { return { x: x, y: y, width: w, height: h }; }
function right(r) { return r.x + r.width; }
function bottom(r) { return r.y + r.height; }
function area(r) { return Math.max(0, r.width) * Math.max(0, r.height); }

function overlapArea(a, b) {
    const w = Math.min(right(a), right(b)) - Math.max(a.x, b.x);
    const h = Math.min(bottom(a), bottom(b)) - Math.max(a.y, b.y);
    return w > 0 && h > 0 ? w * h : 0;
}

// ------------------------------------------------------------ screen edges

// Zone fractions of every edge target, same format as layouts.js zones.
const TARGETS = {
    max:    { x: 0,   y: 0,   w: 1,   h: 1 },
    top:    { x: 0,   y: 0,   w: 1,   h: 0.5 },
    bottom: { x: 0,   y: 0.5, w: 1,   h: 0.5 },
    left:   { x: 0,   y: 0,   w: 0.5, h: 1 },
    right:  { x: 0.5, y: 0,   w: 0.5, h: 1 },
    tl:     { x: 0,   y: 0,   w: 0.5, h: 0.5 },
    tr:     { x: 0.5, y: 0,   w: 0.5, h: 0.5 },
    bl:     { x: 0,   y: 0.5, w: 0.5, h: 0.5 },
    br:     { x: 0.5, y: 0.5, w: 0.5, h: 0.5 }
};

function zoneFor(name) { return TARGETS[name] || null; }

// Which edge or corner is the cursor pushing against?
//   p        cursor position
//   scr      geometry of the screen under the cursor
//   o        { distance, cornerPercent, top, sides, bottom, corners }
//   blocked  { left, right, top, bottom }: true where another screen continues,
//            the cursor just passes over to it there, so that edge never triggers
// Returns "top", "bottom", "left", "right", "tl", "tr", "bl", "br" or "".
function edgeAt(p, scr, o, blocked) {
    blocked = blocked || {};
    const d = Math.max(1, o.distance);
    const nearL = !blocked.left && p.x - scr.x < d;
    const nearR = !blocked.right && right(scr) - 1 - p.x < d;
    const nearT = !blocked.top && p.y - scr.y < d;
    const nearB = !blocked.bottom && bottom(scr) - 1 - p.y < d;
    if (!nearL && !nearR && !nearT && !nearB) return "";

    if (o.corners) {
        const cw = scr.width * o.cornerPercent / 100;
        const ch = scr.height * o.cornerPercent / 100;
        const inL = p.x - scr.x < cw, inR = right(scr) - p.x <= cw;
        const inT = p.y - scr.y < ch, inB = bottom(scr) - p.y <= ch;
        if ((nearT && inL) || (nearL && inT)) return "tl";
        if ((nearT && inR) || (nearR && inT)) return "tr";
        if ((nearB && inL) || (nearL && inB)) return "bl";
        if ((nearB && inR) || (nearR && inB)) return "br";
    }
    if (nearT && o.top) return "top";
    if (nearL && o.sides) return "left";
    if (nearR && o.sides) return "right";
    if (nearB && o.bottom) return "bottom";
    return "";
}

// Which area edges does a target have to keep touching?
function anchorsOf(edge) {
    switch (edge) {
    case "top":    return { t: true };
    case "bottom": return { b: true };
    case "left":   return { l: true };
    case "right":  return { r: true };
    case "tl":     return { t: true, l: true };
    case "tr":     return { t: true, r: true };
    case "bl":     return { b: true, l: true };
    case "br":     return { b: true, r: true };
    default:       return {};
    }
}

// "Smart fill": a target shrinks around windows that are already tiled, so a
// new window never covers them. Dragging to the top while a window sits at the
// bottom gives the top half instead of a maximized window; a left half with a
// window in the bottom-left corner becomes the top-left quarter, and so on.
//   target    rect the edge would normally give
//   edge      edge name (see edgeAt)
//   blockers  rects of tiled windows on this screen
//   bounds    free screen area
//   minFrac   smallest result allowed, as a fraction of the area size
function fitFree(target, edge, blockers, bounds, minFrac) {
    const a = anchorsOf(edge);
    const minW = bounds.width * (minFrac || 0.2), minH = bounds.height * (minFrac || 0.2);
    const tol = 2;
    let t = rect(target.x, target.y, target.width, target.height);
    const t0 = t;

    const touches = function (c) {
        return (!a.t || c.y <= t0.y + tol) && (!a.b || bottom(c) >= bottom(t0) - tol)
            && (!a.l || c.x <= t0.x + tol) && (!a.r || right(c) >= right(t0) - tol);
    };
    // top/bottom targets prefer to keep their full width, left/right their full height
    const horizontal = (a.t || a.b) && !(a.l || a.r);
    const vertical = (a.l || a.r) && !(a.t || a.b);
    const keepsSpan = function (c) {
        if (horizontal) return Math.abs(c.width - t0.width) <= tol;
        if (vertical) return Math.abs(c.height - t0.height) <= tol;
        return false;
    };

    for (let round = 0; round < blockers.length + 1; round++) {
        let hit = null, best = 0;
        for (let i = 0; i < blockers.length; i++) {
            const ov = overlapArea(t, blockers[i]);
            // a few pixels of overlap (shadows, gaps) are not a conflict
            if (ov > best && ov > 0.02 * area(t)) { best = ov; hit = blockers[i]; }
        }
        if (!hit) return t;

        const cands = [
            rect(t.x, t.y, t.width, hit.y - t.y),                          // above it
            rect(t.x, bottom(hit), t.width, bottom(t) - bottom(hit)),      // below it
            rect(t.x, t.y, hit.x - t.x, t.height),                         // left of it
            rect(right(hit), t.y, right(t) - right(hit), t.height)         // right of it
        ].filter(function (c) { return c.width >= minW && c.height >= minH && touches(c); });
        if (cands.length === 0) return target;          // no room: behave as if alone

        cands.sort(function (p, q) {
            const ks = (keepsSpan(q) ? 1 : 0) - (keepsSpan(p) ? 1 : 0);
            return ks !== 0 ? ks : area(q) - area(p);
        });
        t = cands[0];
    }
    return t;
}

// ------------------------------------------------------------ window magnet

// Moves the dragged rect so its edges stick to nearby edges.
//   r        current window rect
//   others   rects of the other windows
//   bounds   free screen area (used when o.screen is on)
//   o        { distance, windows, screen, gap }
//   edges    which edges may move: { l, r, t, b }. A move passes all four,
//            a resize only the edges that are being dragged.
// Returns the new rect (unchanged if nothing is close enough).
function magnet(r, others, bounds, o, edges) {
    const d = Math.max(0, o.distance);
    const resist = Math.max(0, o.resist || 0);
    if (d <= 0 && resist <= 0) return r;
    const gap = Math.max(0, o.gap || 0);
    const moving = edges.l && edges.r && edges.t && edges.b;

    // Candidates per edge: { p: position, s: side }. s = +1 means the edge is
    // held back while it tries to go below p (it would slide into a window
    // or off the screen), -1 the same for going above p, 0 = just align.
    const xs = { l: [], r: [] }, ys = { t: [], b: [] };
    if (o.screen && bounds) {
        xs.l.push({ p: bounds.x, s: 1 }); xs.r.push({ p: right(bounds), s: -1 });
        ys.t.push({ p: bounds.y, s: 1 }); ys.b.push({ p: bottom(bounds), s: -1 });
    }
    if (o.windows) {
        for (let i = 0; i < others.length; i++) {
            const w = others[i];
            const vOver = Math.min(bottom(r), bottom(w)) - Math.max(r.y, w.y);
            const hOver = Math.min(right(r), right(w)) - Math.max(r.x, w.x);
            // only windows beside / above each other count; they block only
            // while the two really share a stretch of edge
            if (vOver > -d) {
                const s = vOver > 0 ? 1 : 0;
                xs.l.push({ p: right(w) + gap, s: s }, { p: w.x, s: 0 });
                xs.r.push({ p: w.x - gap, s: -s }, { p: right(w), s: 0 });
            }
            if (hOver > -d) {
                const s = hOver > 0 ? 1 : 0;
                ys.t.push({ p: bottom(w) + gap, s: s }, { p: w.y, s: 0 });
                ys.b.push({ p: w.y - gap, s: -s }, { p: bottom(w), s: 0 });
            }
        }
    }

    // smallest correction for one edge: a snap within d, or holding it back
    // up to `resist` pixels past a blocking edge
    const nearest = function (value, list) {
        let best = null;
        for (let i = 0; i < list.length; i++) {
            const c = list[i];
            const diff = c.p - value;
            const held = c.s !== 0 && diff * c.s > 0 && Math.abs(diff) <= resist;
            if ((Math.abs(diff) <= d || held) && (best === null || Math.abs(diff) < Math.abs(best))) best = diff;
        }
        return best;
    };
    const pick = function (a, b) {
        if (a === null) return b;
        if (b === null) return a;
        return Math.abs(a) <= Math.abs(b) ? a : b;
    };

    let x1 = r.x, x2 = right(r), y1 = r.y, y2 = bottom(r);
    if (moving) {
        const dx = pick(nearest(x1, xs.l), nearest(x2, xs.r));
        if (dx !== null) { x1 += dx; x2 += dx; }
        const dy = pick(nearest(y1, ys.t), nearest(y2, ys.b));
        if (dy !== null) { y1 += dy; y2 += dy; }
    } else {
        const minSize = 40;
        if (edges.l) { const v = nearest(x1, xs.l); if (v !== null && x2 - (x1 + v) >= minSize) x1 += v; }
        if (edges.r) { const v = nearest(x2, xs.r); if (v !== null && (x2 + v) - x1 >= minSize) x2 += v; }
        if (edges.t) { const v = nearest(y1, ys.t); if (v !== null && y2 - (y1 + v) >= minSize) y1 += v; }
        if (edges.b) { const v = nearest(y2, ys.b); if (v !== null && (y2 + v) - y1 >= minSize) y2 += v; }
    }
    return rect(Math.round(x1), Math.round(y1), Math.round(x2 - x1), Math.round(y2 - y1));
}

// Which edges did a resize move, compared with the start rect?
function resizedEdges(start, now) {
    const e = 0.5;
    return {
        l: Math.abs(now.x - start.x) > e,
        r: Math.abs(right(now) - right(start)) > e,
        t: Math.abs(now.y - start.y) > e,
        b: Math.abs(bottom(now) - bottom(start)) > e
    };
}

// --------------------------------------------------------- sticky edges
// Windows that touch share an edge. While one of them is resized, the shared
// edges of the others follow, so nothing overlaps and no gap opens up.
// Idea taken from "Sticky Window Snapping" by Toni Dietze (GPL-2.0-or-later),
// rewritten: edges only count as shared when the windows really face each
// other, the gap between them is kept as it was, and size limits are respected.

function edgeOf(r, e) {
    return e === "l" ? r.x : e === "r" ? right(r) : e === "t" ? r.y : bottom(r);
}

// Links of `b` to the edges of the resized window `a`.
// o: { tol: how far apart two edges may be and still count as shared,
//      aligned: also keep edges of stacked windows in line,
//      area: free screen area (edges lying on its border are not shared) }
// returns null or { l, r, t, b } with { e: edge of b, off: edge(a) - edge(b) }
function stickyLink(a, b, o) {
    const tol = Math.max(0, o.tol);
    const minShared = 8;                        // a few pixels of common border
    const vOver = Math.min(bottom(a), bottom(b)) - Math.max(a.y, b.y) >= minShared;
    const hOver = Math.min(right(a), right(b)) - Math.max(a.x, b.x) >= minShared;
    const ar = o.area;
    const onBorder = {
        l: ar ? Math.abs(a.x - ar.x) <= 2 : false,
        r: ar ? Math.abs(right(a) - right(ar)) <= 2 : false,
        t: ar ? Math.abs(a.y - ar.y) <= 2 : false,
        b: ar ? Math.abs(bottom(a) - bottom(ar)) <= 2 : false
    };
    const link = { l: null, r: null, t: null, b: null };
    const near = function (x, y, t) { return Math.abs(x - y) <= t; };
    const mk = function (ea, eb) { return { e: eb, off: edgeOf(a, ea) - edgeOf(b, eb) }; };

    // facing edges: b left of / right of / above / below a
    if (vOver && !onBorder.l && near(a.x, right(b), tol)) link.l = mk("l", "r");
    if (vOver && !onBorder.r && near(right(a), b.x, tol)) link.r = mk("r", "l");
    if (hOver && !onBorder.t && near(a.y, bottom(b), tol)) link.t = mk("t", "b");
    if (hOver && !onBorder.b && near(bottom(a), b.y, tol)) link.b = mk("b", "t");

    if (o.aligned) {
        // windows in one column (stacked) keep their left/right edges in line,
        // windows in one row keep their top/bottom edges in line
        const stacked = hOver && (near(bottom(a), b.y, tol) || near(a.y, bottom(b), tol));
        const inRow = vOver && (near(right(a), b.x, tol) || near(a.x, right(b), tol));
        if (stacked && !link.l && !onBorder.l && near(a.x, b.x, 2)) link.l = mk("l", "l");
        if (stacked && !link.r && !onBorder.r && near(right(a), right(b), 2)) link.r = mk("r", "r");
        if (inRow && !link.t && !onBorder.t && near(a.y, b.y, 2)) link.t = mk("t", "t");
        if (inRow && !link.b && !onBorder.b && near(bottom(a), bottom(b), 2)) link.b = mk("b", "b");
    }
    return (link.l || link.r || link.t || link.b) ? link : null;
}

// New rect of a linked window `orig` after the resized window became `a`.
// moved: which edges of `a` the user has moved so far
// limits: { minW, minH, maxW, maxH, area }
function stickyRect(orig, link, a, moved, limits) {
    let x1 = orig.x, x2 = right(orig), y1 = orig.y, y2 = bottom(orig);
    const set = function (e, v) {
        if (e === "l") x1 = v; else if (e === "r") x2 = v; else if (e === "t") y1 = v; else y2 = v;
    };
    const keys = ["l", "r", "t", "b"];
    for (let i = 0; i < keys.length; i++) {
        const k = keys[i], ln = link[k];
        if (ln && moved[k]) set(ln.e, edgeOf(a, k) - ln.off);
    }
    // keep inside the free area, unless the window was already outside
    const ar = limits.area;
    if (ar) {
        x1 = Math.max(x1, Math.min(ar.x, orig.x));
        y1 = Math.max(y1, Math.min(ar.y, orig.y));
        x2 = Math.min(x2, Math.max(right(ar), right(orig)));
        y2 = Math.min(y2, Math.max(bottom(ar), bottom(orig)));
    }
    // size limits: the edge that was not pushed stays where it is
    const pinRight = x2 === right(orig) && x1 !== orig.x;
    const pinBottom = y2 === bottom(orig) && y1 !== orig.y;
    const w = Math.min(limits.maxW, Math.max(limits.minW, x2 - x1));
    const h = Math.min(limits.maxH, Math.max(limits.minH, y2 - y1));
    if (pinRight) x1 = x2 - w; else x2 = x1 + w;
    if (pinBottom) y1 = y2 - h; else y2 = y1 + h;
    return rect(Math.round(x1), Math.round(y1), Math.round(x2 - x1), Math.round(y2 - y1));
}

// Shaking the mouse while resizing lets the other windows go.
// s: { val, turnVal, dir, count } (start with val = turnVal = size)
function shakeStep(s, value, threshold) {
    if (s.turnVal < value) { if (s.val < value) s.val = value; }
    else if (s.turnVal > value) { if (s.val > value) s.val = value; }
    const dist = s.val - value;
    const dir = dist > 0 ? 1 : (dist < 0 ? -1 : 0);
    if (dir !== 0 && dir !== s.dir && Math.abs(dist) >= threshold) {
        s.turnVal = s.val; s.val = value; s.count += 1; s.dir = dir;
    }
    return s.count;
}

// Shaking, but only counted when it is quick and clear: a turn is a change
// of direction after at least `threshold` px; `windowMs` keeps only recent
// turns. A fast pull in one direction never counts, however far it goes.
// s: from newShake(start position)
function shakeTimed(s, value, threshold, now, windowMs) {
    if (s.dir === 0) {
        if (Math.abs(value - s.ext) >= threshold) { s.dir = value > s.ext ? 1 : -1; s.ext = value; }
    } else if (s.dir > 0) {
        if (value > s.ext) s.ext = value;
        else if (s.ext - value >= threshold) { s.times.push(now); s.dir = -1; s.ext = value; }
    } else {
        if (value < s.ext) s.ext = value;
        else if (value - s.ext >= threshold) { s.times.push(now); s.dir = 1; s.ext = value; }
    }
    while (s.times.length && now - s.times[0] > windowMs) s.times.shift();
    return s.times.length;
}
function newShake(v) { return { ext: v, dir: 0, times: [] }; }

// Every window that shares an edge line with the resized window `a`, also
// through other windows: two small windows stacked next to a big one move
// together, a 2x2 grid moves along its middle lines, and so on.
// others: [{ id, r }], o: { tol, aligned, area }
// returns { id: { l, r, t, b } } with the same link format as stickyLink
function stickyGroup(a, others, o) {
    const tol = Math.max(0, o.tol);
    const ar = o.area;
    const out = {};
    const add = function (id, k, e, off) {
        if (!out[id]) out[id] = { l: null, r: null, t: null, b: null };
        if (!out[id][k]) out[id][k] = { e: e, off: off };
    };
    const lines = [["l", true], ["r", true], ["t", false], ["b", false]];
    for (let n = 0; n < lines.length; n++) {
        const k = lines[n][0], vertical = lines[n][1];
        const pos = edgeOf(a, k);
        if (ar) {
            const border = k === "l" ? ar.x : k === "r" ? right(ar) : k === "t" ? ar.y : bottom(ar);
            if (Math.abs(pos - border) <= 2) continue;     // the screen edge is no shared line
        }
        // span of a member along the line
        const span = function (r) { return vertical ? [r.y, bottom(r)] : [r.x, right(r)]; };
        const members = [span(a)];
        const facingSide = (k === "l" || k === "t") ? "before" : "after";
        let added = true;
        const done = {};
        while (added) {
            added = false;
            for (let i = 0; i < others.length; i++) {
                const ob = others[i];
                if (done[ob.id]) continue;
                const b = ob.r;
                // which edge of b lies on the line, and is it facing or in line with a
                let eb = null;
                const lo = vertical ? b.x : b.y, hi = vertical ? right(b) : bottom(b);
                const before = Math.abs(hi - pos) <= tol && hi <= pos + 2;   // b ends at the line
                const after = Math.abs(lo - pos) <= tol && lo >= pos - 2;    // b starts at the line
                if (before && !after) eb = vertical ? "r" : "b";
                else if (after && !before) eb = vertical ? "l" : "t";
                else continue;
                const side = (eb === "r" || eb === "b") ? "before" : "after";
                const facing = side === facingSide;
                if (!facing && !o.aligned) continue;
                if (!facing && Math.abs((vertical ? (eb === "r" ? hi : lo) : (eb === "b" ? hi : lo)) - pos) > 2) continue;
                // connected to the group along the line?
                const sb = span(b);
                let joined = false;
                for (let m = 0; m < members.length; m++) {
                    const sm = members[m];
                    const overlap = Math.min(sm[1], sb[1]) - Math.max(sm[0], sb[0]);
                    if (facing ? overlap >= 8 : overlap >= -tol) { joined = true; break; }
                }
                if (!joined) continue;
                done[ob.id] = true;
                members.push(sb);
                added = true;
                add(ob.id, k, eb, pos - edgeOf(b, eb));
            }
        }
    }
    return out;
}

// --------------------------------------------------- holding edges
// While a window is moved (or an edge resized), an edge that runs into another
// window stops there and stays there - also when the mouse is moved fast and
// jumps far past it in one step. It lets go when
//   * the window is pulled back,
//   * the mouse is shaken (quick back and forth),
//   * or the edge is pushed further than `resist` px for `holdMs`.
// Blocking edges: the free screen border (o.screen) and the facing edges of
// windows that share a stretch with the moved window.

function newHold(r) {
    return { x: null, y: null, passed: {}, free: false,
             sx: newShake(r.x + r.width / 2), sy: newShake(r.y + r.height / 2) };
}

// blockers for one edge: [{ key, p, s }] (s=+1: edge must stay >= p, -1: <= p)
function blockersFor(edge, r, others, bounds, o) {
    const out = [];
    const gap = Math.max(0, o.gap || 0);
    if (o.screen && bounds) {
        if (edge === "l") out.push({ key: "sl", p: bounds.x, s: 1 });
        if (edge === "r") out.push({ key: "sr", p: right(bounds), s: -1 });
        if (edge === "t") out.push({ key: "st", p: bounds.y, s: 1 });
        if (edge === "b") out.push({ key: "sb", p: bottom(bounds), s: -1 });
    }
    if (o.windows) {
        for (let i = 0; i < others.length; i++) {
            const w = others[i];
            const vOver = Math.min(bottom(r), bottom(w)) - Math.max(r.y, w.y);
            const hOver = Math.min(right(r), right(w)) - Math.max(r.x, w.x);
            if ((edge === "l" || edge === "r") && vOver > 0) {
                if (edge === "l") out.push({ key: "w" + i + "l", p: right(w) + gap, s: 1 });
                else out.push({ key: "w" + i + "r", p: w.x - gap, s: -1 });
            }
            if ((edge === "t" || edge === "b") && hOver > 0) {
                if (edge === "t") out.push({ key: "w" + i + "t", p: bottom(w) + gap, s: 1 });
                else out.push({ key: "w" + i + "b", p: w.y - gap, s: -1 });
            }
        }
    }
    return out;
}

// raw: where KWin would put the window now, prev: what we showed last time,
// edges: which edges move ({l,r,t,b}, all four for a move), now: ms
// o: { distance, windows, screen, gap, resist, holdMs }
function holdStep(raw, prev, others, bounds, o, st, now, edges) {
    const resist = Math.max(0, o.resist || 0);
    const holdMs = o.holdMs === undefined ? 600 : o.holdMs;
    const moving = edges.l && edges.r && edges.t && edges.b;
    // a clear shake lets go of everything for the rest of this drag
    if (!st.free && resist > 0) {
        const cx = raw.x + raw.width / 2, cy = raw.y + raw.height / 2;
        const sx = moving ? cx : (edges.l ? raw.x : right(raw));
        const sy = moving ? cy : (edges.t ? raw.y : bottom(raw));
        if (shakeTimed(st.sx, sx, 90, now, 1400) >= 3 || shakeTimed(st.sy, sy, 90, now, 1400) >= 3) {
            st.free = true; st.x = null; st.y = null;
        }
    }
    // alignment within the snap distance, no resistance (that is done here)
    const opts = { distance: o.distance, windows: o.windows, screen: o.screen, gap: o.gap, resist: 0 };
    let r = magnet(raw, others, bounds, opts, edges);
    if (resist <= 0 || st.free) { st.x = null; st.y = null; return r; }

    const axes = [["x", "l", "r"], ["y", "t", "b"]];
    for (let n = 0; n < axes.length; n++) {
        const ax = axes[n][0];
        const lo = axes[n][1], hi = axes[n][2];
        const val = function (rc, e) { return edgeOf(rc, e); };
        let h = st[ax];
        // still held?
        if (h) {
            const depth = (h.p - val(raw, h.edge)) * h.s;          // > 0: pushing into it
            const list = blockersFor(h.edge, raw, others, bounds, o);
            let still = false;
            for (let i = 0; i < list.length; i++) if (list[i].key === h.key) { still = true; break; }
            if (depth <= 0 || !still) h = null;                      // pulled back or slid past
            else if (depth >= resist) {
                if (h.pushSince === null) h.pushSince = now;
                if (now - h.pushSince >= holdMs) { st.passed[h.key] = true; h = null; }
            } else h.pushSince = null;
            st[ax] = h;
        }
        // newly crossed a blocker since the last step?
        if (!h) {
            const cands = [];
            if (edges[lo]) cands.push(lo);
            if (edges[hi]) cands.push(hi);
            let best = null;
            for (let c = 0; c < cands.length; c++) {
                const e = cands[c];
                const list = blockersFor(e, raw, others, bounds, o);
                for (let i = 0; i < list.length; i++) {
                    const b = list[i];
                    const before = (val(prev, e) - b.p) * b.s;    // >= 0: was on the free side
                    const nowD = (val(raw, e) - b.p) * b.s;       // < 0: went past
                    if (before >= -1 && nowD < 0) {
                        if (st.passed[b.key]) continue;
                        if (best === null || before < best.before) best = { key: b.key, p: b.p, s: b.s, edge: e, before: before };
                    } else if (nowD >= 0 && st.passed[b.key]) {
                        delete st.passed[b.key];                     // back on the free side
                    }
                }
            }
            if (best) {
                h = { key: best.key, p: best.p, s: best.s, edge: best.edge, pushSince: null };
                const depth = (h.p - val(raw, h.edge)) * h.s;
                if (depth >= resist) h.pushSince = now;
                st[ax] = h;
            }
        }
        if (h) {
            // put the held edge on the blocking line
            if (moving) {
                const d = h.p - val(raw, h.edge);
                if (ax === "x") r = rect(raw.x + d, r.y, raw.width, r.height);
                else r = rect(r.x, raw.y + d, r.width, raw.height);
            } else {
                let x1 = r.x, x2 = right(r), y1 = r.y, y2 = bottom(r);
                if (h.edge === "l") x1 = h.p; else if (h.edge === "r") x2 = h.p;
                else if (h.edge === "t") y1 = h.p; else y2 = h.p;
                r = rect(x1, y1, x2 - x1, y2 - y1);
            }
        }
    }
    return rect(Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height));
}

// ---------------------------------------------------- hold to fill
// Held a little longer at an edge, a half or a quarter grows towards the
// middle of the screen until it meets the next window (or the screen edge).
// Only windows completely outside the first target count: one that the
// target already covers is left to smart fill.
// edge: left/right/top/bottom/tl/tr/bl/br, r: the first target,
// others: rects of the other windows, bounds: free area (minus margins)
function fillFree(edge, r, others, bounds, gap) {
    let x1 = r.x, x2 = right(r), y1 = r.y, y2 = bottom(r);
    const g = Math.max(0, gap || 0);
    const growRight = edge === "left" || edge === "tl" || edge === "bl";
    const growLeft = edge === "right" || edge === "tr" || edge === "br";
    const growDown = edge === "top" || edge === "tl" || edge === "tr";
    const growUp = edge === "bottom" || edge === "bl" || edge === "br";
    const vOver = function (o) { return Math.min(y2, bottom(o)) - Math.max(y1, o.y) > 0; };
    const hOver = function (o) { return Math.min(x2, right(o)) - Math.max(x1, o.x) > 0; };

    if (growRight) {
        let lim = right(bounds);
        for (let i = 0; i < others.length; i++) {
            const o = others[i];
            if (vOver(o) && o.x >= x2 - 1) lim = Math.min(lim, o.x - g);
        }
        x2 = Math.max(x2, lim);
    }
    if (growLeft) {
        let lim = bounds.x;
        for (let i = 0; i < others.length; i++) {
            const o = others[i];
            if (vOver(o) && right(o) <= x1 + 1) lim = Math.max(lim, right(o) + g);
        }
        x1 = Math.min(x1, lim);
    }
    if (growDown) {
        let lim = bottom(bounds);
        for (let i = 0; i < others.length; i++) {
            const o = others[i];
            if (hOver(o) && o.y >= y2 - 1) lim = Math.min(lim, o.y - g);
        }
        y2 = Math.max(y2, lim);
    }
    if (growUp) {
        let lim = bounds.y;
        for (let i = 0; i < others.length; i++) {
            const o = others[i];
            if (hOver(o) && bottom(o) <= y1 + 1) lim = Math.max(lim, bottom(o) + g);
        }
        y1 = Math.min(y1, lim);
    }
    return rect(Math.round(x1), Math.round(y1), Math.round(x2 - x1), Math.round(y2 - y1));
}
