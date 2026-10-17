// Shared pieces for the README images, the video and the manual.
// The snap bar replica follows package/contents/ui/SnapBar.qml 1:1.

const leaf = () => null;
const split = (d, r, a, b) => ({ d, r, a, b });
const LAYOUTS = [
  { name: "Halves",        tree: split("v", 1 / 2, leaf(), leaf()) },
  { name: "Two thirds",    tree: split("v", 2 / 3, leaf(), leaf()) },
  { name: "Three columns", tree: split("v", 1 / 3, leaf(), split("v", 1 / 2, leaf(), leaf())) },
  { name: "Main + stack",  tree: split("v", 1 / 2, leaf(), split("h", 1 / 2, leaf(), leaf())) },
  { name: "Four quarters", tree: split("v", 1 / 2, split("h", 1 / 2, leaf(), leaf()), split("h", 1 / 2, leaf(), leaf())) },
  { name: "Center focus",  tree: split("v", 1 / 4, leaf(), split("v", 2 / 3, leaf(), leaf())) },
];
const TEMPLATES = [
  { name: "Single zone",    tree: leaf() },
  { name: "Top / bottom",   tree: split("h", 1 / 2, leaf(), leaf()) },
  { name: "Stack + main",   tree: split("v", 1 / 2, split("h", 1 / 2, leaf(), leaf()), leaf()) },
  { name: "Six tiles",      tree: split("v", 1 / 3, split("h", 1 / 2, leaf(), leaf()), split("v", 1 / 2, split("h", 1 / 2, leaf(), leaf()), split("h", 1 / 2, leaf(), leaf()))) },
  { name: "Sidebar + grid", tree: split("v", 1 / 4, leaf(), split("h", 1 / 2, split("v", 1 / 2, leaf(), leaf()), split("v", 1 / 2, leaf(), leaf()))) },
];

function zonesOf(tree, x = 0, y = 0, w = 1, h = 1, out = []) {
  if (!tree) { out.push({ x, y, w, h }); return out; }
  if (tree.d === "v") { zonesOf(tree.a, x, y, w * tree.r, h, out); zonesOf(tree.b, x + w * tree.r, y, w * (1 - tree.r), h, out); }
  else { zonesOf(tree.a, x, y, w, h * tree.r, out); zonesOf(tree.b, x, y + h * tree.r, w, h * (1 - tree.r), out); }
  return out;
}

const THEMES = {
  dark:  { bg: "rgba(43,43,43,.96)", border: "rgba(255,255,255,.10)", zone: "#575757", zoneBorder: "rgba(255,255,255,.12)", text: "#fff" },
  light: { bg: "rgba(249,249,249,.96)", border: "rgba(0,0,0,.10)", zone: "#d0d0d0", zoneBorder: "rgba(0,0,0,.10)", text: "#1a1a1a" },
};

// Snap bar as a DOM element. state: {s, theme, accent, hoverL, hoverZ, showName, layouts, aspect, perRow, radius}
function snapBar(st) {
  const s = st.s || 1, th = THEMES[st.theme || "dark"], acc = st.accent || "#3daee9";
  const layouts = st.layouts || LAYOUTS;
  const pad = Math.round(12 * s), gap = Math.round(12 * s);
  const tw = Math.round((st.thumbW || 72) * s), thh = Math.round(tw * (st.aspect || 1080 / 1920));
  const cols = st.perRow > 0 ? Math.min(st.perRow, layouts.length) : layouts.length;
  const rows = Math.ceil(layouts.length / cols);
  const nameH = st.showName ? Math.round(24 * s) : 0;
  const W = pad * 2 + cols * tw + (cols - 1) * gap, H = pad * 2 + rows * thh + (rows - 1) * gap + nameH;
  const el = document.createElement("div");
  el.className = "snapbar";
  Object.assign(el.style, {
    position: "absolute", width: W + "px", height: H + "px", borderRadius: Math.min(H / 2, (st.radius ?? 8) * s) + "px",
    background: th.bg, border: "1px solid " + th.border, boxSizing: "border-box",
    boxShadow: `0 ${2 * s}px ${3 * s}px rgba(0,0,0,.18), 0 ${6 * s}px ${14 * s}px rgba(0,0,0,.22)`,
  });
  const g = Math.max(1, Math.round(1.5 * s));
  const hits = [];
  layouts.forEach((l, li) => {
    const c = li % cols, r = Math.floor(li / cols);
    const tx = pad + c * (tw + gap) - 1, ty = pad + r * (thh + gap) - 1;
    zonesOf(l.tree).forEach((z, zi) => {
      const x1 = Math.round(z.x * tw + (z.x > 0.001 ? g : 0)), y1 = Math.round(z.y * thh + (z.y > 0.001 ? g : 0));
      const x2 = Math.round((z.x + z.w) * tw - (z.x + z.w < 0.999 ? g : 0)), y2 = Math.round((z.y + z.h) * thh - (z.y + z.h < 0.999 ? g : 0));
      const d = document.createElement("div");
      const hot = li === st.hoverL && zi === st.hoverZ;
      Object.assign(d.style, {
        position: "absolute", left: tx + x1 + "px", top: ty + y1 + "px", width: Math.max(2, x2 - x1) + "px", height: Math.max(2, y2 - y1) + "px",
        borderRadius: Math.max(2, Math.round(3 * s)) + "px", boxSizing: "border-box",
        background: hot ? acc : th.zone, border: "1px solid " + (hot ? "rgba(255,255,255,.35)" : th.zoneBorder),
      });
      el.appendChild(d);
      hits.push({ li, zi, x: tx + x1, y: ty + y1, w: x2 - x1, h: y2 - y1, z });
    });
  });
  if (st.showName) {
    const t = document.createElement("div");
    const L = layouts[st.hoverL];
    t.textContent = L ? L.name + (st.hoverZ >= 0 ? "  ·  Zone " + (st.hoverZ + 1) : "") : "Drop the window onto a zone";
    Object.assign(t.style, { position: "absolute", left: 0, right: 0, bottom: Math.round(pad * 0.6) - 1 + "px", textAlign: "center",
      color: th.text, opacity: .85, font: `${Math.round(12 * s)}px Inter, sans-serif`, whiteSpace: "pre" });
    el.appendChild(t);
  }
  el._w = W; el._h = H; el._hits = hits;
  return el;
}

// Small static layout thumbnail (for galleries)
function layoutThumb(l, w, h, opt = {}) {
  const el = document.createElement("div");
  Object.assign(el.style, { position: "relative", width: w + "px", height: h + "px" });
  const g = opt.gap ?? 3;
  zonesOf(l.tree).forEach((z, i) => {
    const d = document.createElement("div");
    Object.assign(d.style, {
      position: "absolute", left: z.x * w + (z.x > 0 ? g : 0) + "px", top: z.y * h + (z.y > 0 ? g : 0) + "px",
      width: z.w * w - (z.x > 0 ? g : 0) - (z.x + z.w < 1 ? g : 0) + "px", height: z.h * h - (z.y > 0 ? g : 0) - (z.y + z.h < 1 ? g : 0) + "px",
      borderRadius: (opt.r ?? 5) + "px", background: (opt.hot === i) ? (opt.accent || "#3daee9") : (opt.zone || "rgba(255,255,255,.16)"),
      border: "1px solid " + (opt.border || "rgba(255,255,255,.12)"), boxSizing: "border-box",
    });
    el.appendChild(d);
  });
  return el;
}

// Plasma-like wallpaper
const WALL = `
  radial-gradient(1200px 800px at 18% 85%, rgba(61,174,233,.55), transparent 60%),
  radial-gradient(1000px 700px at 85% 15%, rgba(147,92,232,.45), transparent 60%),
  radial-gradient(900px 600px at 70% 90%, rgba(29,153,243,.35), transparent 60%),
  linear-gradient(135deg, #0d1b3a 0%, #142a5c 45%, #1b1440 100%)`;
