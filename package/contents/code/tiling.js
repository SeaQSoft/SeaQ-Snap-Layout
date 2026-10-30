.pragma library
// Automatic tiling: every window on a screen gets a place, new windows join,
// closed ones leave a gap that the others fill. The layouts follow the classic
// tiling window managers (and Krohnkite for KWin).
// Rects are plain {x, y, width, height} objects in screen coordinates.

var LAYOUTS = [
    { id: "tile",     text: "Main and stack" },
    { id: "centered", text: "Main in the middle" },
    { id: "columns",  text: "Columns" },
    { id: "rows",     text: "Rows" },
    { id: "grid",     text: "Grid" },
    { id: "spiral",   text: "Spiral" },
    { id: "dwindle",  text: "Dwindle" },
    { id: "monocle",  text: "One at a time" }
];
// own layouts from the layout builder are used as "zones:<name>"
function isZones(id) { return String(id).indexOf("zones:") === 0; }

function layoutIndex(id) {
    for (var i = 0; i < LAYOUTS.length; i++) if (LAYOUTS[i].id === id) return i;
    return 0;
}

function rect(x, y, w, h) { return { x: x, y: y, width: w, height: h }; }
function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

// n equal slices of r with `g` px between them (vertical = stacked)
function split(r, n, vertical, g) {
    var out = [];
    var len = vertical ? r.height : r.width;
    var each = (len - (n - 1) * g) / n;
    for (var i = 0; i < n; i++) {
        var p1 = Math.round(i * (each + g)), p2 = Math.round(i * (each + g) + each);
        if (vertical) out.push(rect(r.x, r.y + p1, r.width, p2 - p1));
        else out.push(rect(r.x + p1, r.y, p2 - p1, r.height));
    }
    return out;
}
// r cut in two: the first part gets `f` of the space left after the gap
function cut(r, f, vertical, g, fromEnd) {
    var len = vertical ? r.height : r.width;
    var a = Math.round((len - g) * f), b = len - g - a;
    if (fromEnd) {
        var t = a; a = b; b = t;
    }
    var first = vertical ? rect(r.x, r.y, r.width, a) : rect(r.x, r.y, a, r.height);
    var second = vertical ? rect(r.x, r.y + a + g, r.width, b) : rect(r.x + a + g, r.y, b, r.height);
    return fromEnd ? [second, first] : [first, second];
}

// window rects for n windows inside a, g px apart
function cells(kind, n, a, ratio, masters, g) {
    if (n <= 0) return [];
    ratio = clamp(ratio || 0.55, 0.15, 0.85);
    masters = Math.max(1, Math.round(masters || 1));
    var i, out;
    if (kind === "monocle") {
        out = [];
        for (i = 0; i < n; i++) out.push(rect(a.x, a.y, a.width, a.height));
        return out;
    }
    if (kind === "columns") return split(a, n, false, g);
    if (kind === "rows") return split(a, n, true, g);
    if (kind === "grid") {
        var cols = Math.ceil(Math.sqrt(n)), rowsN = Math.ceil(n / cols);
        var rowRects = split(a, rowsN, true, g);
        out = [];
        for (var r = 0; r < rowsN; r++) out = out.concat(split(rowRects[r], Math.min(cols, n - r * cols), false, g));
        return out;
    }
    if (kind === "dwindle") {
        // every new window halves the space the last one had, always
        // towards the bottom right (side by side, then stacked, ...)
        out = [];
        var restD = rect(a.x, a.y, a.width, a.height);
        for (i = 0; i < n; i++) {
            if (i === n - 1) { out.push(restD); break; }
            var pd = cut(restD, i === 0 ? ratio : 0.5, i % 2 === 1, g, false);
            out.push(pd[0]); restD = pd[1];
        }
        return out;
    }
    if (kind === "spiral") {
        // first split side by side, then stacked, and so on; the rest turns clockwise
        out = [];
        var rest = rect(a.x, a.y, a.width, a.height);
        for (i = 0; i < n; i++) {
            if (i === n - 1) { out.push(rest); break; }
            var turn = i % 4;
            var parts = cut(rest, i === 0 ? ratio : 0.5, turn % 2 === 1, g, turn >= 2);
            out.push(parts[0]); rest = parts[1];
        }
        return out;
    }
    if (kind === "centered") {
        if (n === 1) return [rect(a.x, a.y, a.width, a.height)];
        if (n === 2) return cut(a, ratio, false, g, false);
        var mw = Math.round((a.width - 2 * g) * ratio);
        var side = Math.round((a.width - 2 * g - mw) / 2);
        var left = rect(a.x, a.y, side, a.height);
        var mid = rect(a.x + side + g, a.y, mw, a.height);
        var rightR = rect(mid.x + mw + g, a.y, a.x + a.width - (mid.x + mw + g), a.height);
        var stack = n - 1;
        var nl = Math.floor(stack / 2), nr = stack - nl;   // the right column gets the extra one
        var ls = split(left, nl, true, g), rs = split(rightR, nr, true, g);
        out = [mid];
        var li = 0, ri = 0;
        for (i = 0; i < stack; i++) {
            if ((i % 2 === 0 || li >= ls.length) && ri < rs.length) out.push(rs[ri++]);
            else out.push(ls[li++]);
        }
        return out;
    }
    // "tile": main windows on the left, the others stacked on the right
    var m = Math.min(masters, n);
    if (n <= m) return split(a, n, true, g);
    var halves = cut(a, ratio, false, g, false);
    return split(halves[0], m, true, g).concat(split(halves[1], n - m, true, g));
}

// Own layout: zones are relative {x, y, w, h} (0..1). Window i gets zone i;
// more windows than zones share the last zone, stacked along its long side.
function zoneCells(zones, n, a, g) {
    var out = [], i;
    var zs = zones.map(function (z) {
        var x = a.x + z.x * a.width, y = a.y + z.y * a.height, w = z.w * a.width, h = z.h * a.height;
        var hg = g / 2, eps = 0.001;
        if (z.x > eps)           { x += hg; w -= hg; }
        if (z.x + z.w < 1 - eps) { w -= hg; }
        if (z.y > eps)           { y += hg; h -= hg; }
        if (z.y + z.h < 1 - eps) { h -= hg; }
        return rect(Math.round(x), Math.round(y), Math.round(w), Math.round(h));
    });
    for (i = 0; i < Math.min(n, zs.length - 1); i++) out.push(zs[i]);
    if (n >= zs.length) {
        var last = zs[zs.length - 1];
        out = out.concat(split(last, n - zs.length + 1, last.height > last.width, g));
    }
    return out;
}

function mirror(rs, a) {
    return rs.map(function (r) { return rect(a.x + a.width - (r.x - a.x) - r.width, r.y, r.width, r.height); });
}

// area: free screen area
// o: { margin, gap, ratio, masters, flip, single (0..1 width for one window),
//      singleNoGap, zones (for own layouts) }
function arrange(kind, n, area, o) {
    o = o || {};
    var m = Math.max(0, o.margin || 0);
    var g = kind === "monocle" ? 0 : Math.max(0, o.gap || 0);
    if (n === 1 && o.singleNoGap) m = 0;
    var a = rect(area.x + m, area.y + m, area.width - 2 * m, area.height - 2 * m);
    if (n === 1 && o.single && o.single < 0.999) {
        var w = Math.round(a.width * Math.max(0.3, o.single));
        return [rect(Math.round(a.x + (a.width - w) / 2), a.y, w, a.height)];
    }
    var rs;
    if (isZones(kind)) {
        // fewer windows than zones would leave holes: "Main and stack" then
        if (o.zones && o.zones.length && n >= o.zones.length) rs = zoneCells(o.zones, n, a, g);
        else rs = cells("tile", n, a, o.ratio, o.masters, g);
    } else {
        rs = cells(kind, n, a, o.ratio, o.masters, g);
    }
    return o.flip ? mirror(rs, a) : rs;
}

// Layout by window count: rules [{n, l}] – the rule with the biggest n that
// is not above count wins; none fits -> the normal layout
function layoutFor(count, normal, rules) {
    var best = null;
    for (var i = 0; i < (rules || []).length; i++) {
        var r = rules[i];
        if (r && r.l && r.n <= count && (!best || r.n > best.n)) best = r;
    }
    return best ? best.l : normal;
}

// After the user resized a tiled window by hand: the new main size.
// main: the rect of the (first) main window, area as in arrange()
function ratioFrom(kind, main, area, o) {
    o = o || {};
    var m = Math.max(0, o.margin || 0);
    var w = area.width - 2 * m;
    if (w <= 0) return null;
    var g = kind === "monocle" ? 0 : Math.max(0, o.gap || 0);
    if (kind === "tile" || kind === "spiral" || kind === "dwindle") {
        if (o.flip) return clamp((area.x + area.width - m - main.x) / (w - g), 0.15, 0.85);
        return clamp((main.x + main.width - (area.x + m)) / (w - g), 0.15, 0.85);
    }
    if (kind === "centered") return clamp(main.width / (w - 2 * g), 0.15, 0.85);
    return null;
}

function nextLayout(id) {
    return LAYOUTS[(layoutIndex(id) + 1) % LAYOUTS.length].id;
}
