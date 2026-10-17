.pragma library

// Layouts are stored as a small binary split tree:
//   zone:  { t: "z" }
//   split: { t: "s", d: "v" | "h", r: 0..1, a: <node>, b: <node> }
// "v" puts a and b next to each other, "h" stacks them.
// A zone is addressed by its path from the root, e.g. "ab" = root.a.b.

function leaf() { return { t: "z" }; }
function split(d, r, a, b) { return { t: "s", d: d, r: r, a: a, b: b }; }
function clone(o) { return JSON.parse(JSON.stringify(o)); }
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

// Built-in layout names start with "@" and get translated when shown,
// so the defaults follow the system language. Names typed by the user
// are stored as-is.
function presets() {
    return [
        { name: "@Halves",        tree: split("v", 1 / 2, leaf(), leaf()) },
        { name: "@Two thirds",    tree: split("v", 2 / 3, leaf(), leaf()) },
        { name: "@Three columns", tree: split("v", 1 / 3, leaf(), split("v", 1 / 2, leaf(), leaf())) },
        { name: "@Main + stack",  tree: split("v", 1 / 2, leaf(), split("h", 1 / 2, leaf(), leaf())) },
        { name: "@Four quarters", tree: split("v", 1 / 2, split("h", 1 / 2, leaf(), leaf()), split("h", 1 / 2, leaf(), leaf())) },
        { name: "@Center focus",  tree: split("v", 1 / 4, leaf(), split("v", 2 / 3, leaf(), leaf())) }
    ];
}

function templates() {
    return presets().concat([
        { name: "@Single zone",    tree: leaf() },
        { name: "@Top / bottom",   tree: split("h", 1 / 2, leaf(), leaf()) },
        { name: "@Stack + main",   tree: split("v", 1 / 2, split("h", 1 / 2, leaf(), leaf()), leaf()) },
        { name: "@Six tiles",      tree: split("v", 1 / 3, split("h", 1 / 2, leaf(), leaf()),
                                         split("v", 1 / 2, split("h", 1 / 2, leaf(), leaf()), split("h", 1 / 2, leaf(), leaf()))) },
        { name: "@Sidebar + grid", tree: split("v", 1 / 4, leaf(), split("h", 1 / 2,
                                         split("v", 1 / 2, leaf(), leaf()), split("v", 1 / 2, leaf(), leaf()))) }
    ]);
}

function defaultLayouts() {
    return presets().map(function (p) {
        return { name: p.name, shown: true, tree: JSON.stringify(p.tree) };
    });
}

function valid(n) {
    if (!n || typeof n !== "object") return false;
    if (n.t === "z") return true;
    return n.t === "s" && (n.d === "v" || n.d === "h") && typeof n.r === "number"
        && valid(n.a) && valid(n.b);
}

function parseTree(s) {
    try {
        var t = (typeof s === "string") ? JSON.parse(s) : s;
        return valid(t) ? t : leaf();
    } catch (e) {
        return leaf();
    }
}

// Walks the tree once and returns every zone (relative 0..1 rect) plus every
// divider together with the rect of the node it splits.
function compute(tree) {
    var zones = [], dividers = [];
    function walk(n, path, x, y, w, h) {
        if (!n || n.t !== "s") {
            zones.push({ path: path, x: x, y: y, w: w, h: h });
            return;
        }
        var r = clamp(n.r, 0.05, 0.95);
        if (n.d === "v") {
            var w1 = w * r;
            dividers.push({ path: path, d: "v", nx: x, ny: y, nw: w, nh: h, pos: x + w1, r: r });
            walk(n.a, path + "a", x, y, w1, h);
            walk(n.b, path + "b", x + w1, y, w - w1, h);
        } else {
            var h1 = h * r;
            dividers.push({ path: path, d: "h", nx: x, ny: y, nw: w, nh: h, pos: y + h1, r: r });
            walk(n.a, path + "a", x, y, w, h1);
            walk(n.b, path + "b", x, y + h1, w, h - h1);
        }
    }
    walk(tree, "", 0, 0, 1, 1);
    return { zones: zones, dividers: dividers };
}

function zones(tree) { return compute(tree).zones; }

function nodeAt(tree, path) {
    var n = tree;
    for (var i = 0; i < path.length; i++) {
        if (!n || n.t !== "s") return null;
        n = n[path[i]];
    }
    return n;
}

function isZonePath(tree, path) {
    var n = nodeAt(tree, path);
    return !!n && n.t === "z";
}

function firstZonePath(tree) {
    var z = zones(tree);
    return z.length ? z[0].path : "";
}

function replaceAt(tree, path, node) {
    if (path === "") return clone(node);
    var t = clone(tree);
    var parent = nodeAt(t, path.slice(0, -1));
    parent[path.slice(-1)] = clone(node);
    return t;
}

function splitZone(tree, path, d) {
    return replaceAt(tree, path, split(d, 0.5, leaf(), leaf()));
}

// Removing a zone lets its sibling take over the parent's space.
function removeZone(tree, path) {
    if (path === "") return clone(tree);
    var parentPath = path.slice(0, -1);
    var sibKey = path.slice(-1) === "a" ? "b" : "a";
    var sibling = nodeAt(tree, parentPath)[sibKey];
    return replaceAt(tree, parentPath, sibling);
}

function setRatio(tree, path, r) {
    var t = clone(tree);
    var n = nodeAt(t, path);
    if (n && n.t === "s") n.r = r;
    return t;
}

// Dividers stick to the usual fractions when they get close to one.
var SNAPS = [1 / 6, 1 / 5, 1 / 4, 1 / 3, 2 / 5, 1 / 2, 3 / 5, 2 / 3, 3 / 4, 4 / 5, 5 / 6];
function snapRatio(r, enabled) {
    r = clamp(r, 0.08, 0.92);
    if (!enabled) return Math.round(r * 1000) / 1000;
    for (var i = 0; i < SNAPS.length; i++)
        if (Math.abs(r - SNAPS[i]) < 0.018) return SNAPS[i];
    return Math.round(r * 200) / 200;
}

// Final window geometry for a zone. Only inner edges get half the gap each,
// so the outer margin and the gap between windows stay independent.
function targetRect(area, z, gap, margin) {
    var W = area.width - 2 * margin, H = area.height - 2 * margin;
    var x = area.x + margin + z.x * W;
    var y = area.y + margin + z.y * H;
    var w = z.w * W, h = z.h * H;
    var hg = gap / 2, eps = 0.001;
    if (z.x > eps)           { x += hg; w -= hg; }
    if (z.x + z.w < 1 - eps) { w -= hg; }
    if (z.y > eps)           { y += hg; h -= hg; }
    if (z.y + z.h < 1 - eps) { h -= hg; }
    return { x: Math.round(x), y: Math.round(y), width: Math.round(w), height: Math.round(h) };
}
