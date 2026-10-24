.pragma library
// Keyboard actions, their default keys and the usual alternatives.
// Keys are handled as Qt key codes (key | modifiers), the same integers
// KDE's global shortcut service (kglobalaccel) uses on D-Bus.

var SHIFT = 0x02000000, CTRL = 0x04000000, ALT = 0x08000000, META = 0x10000000, KEYPAD = 0x20000000;
var MOD_MASK = SHIFT | CTRL | ALT | META | KEYPAD;

// name shown to the user -> Qt key code
var KEYS = [
    ["Left", 0x01000012], ["Right", 0x01000014], ["Up", 0x01000013], ["Down", 0x01000015],
    ["Return", 0x01000004], ["Space", 0x20], ["Tab", 0x01000001], ["Backspace", 0x01000003],
    ["Home", 0x01000010], ["End", 0x01000011], ["PgUp", 0x01000016], ["PgDown", 0x01000017],
    ["Ins", 0x01000006], ["Del", 0x01000007],
    ["-", 0x2d], ["=", 0x3d], [",", 0x2c], [".", 0x2e], ["/", 0x2f], [";", 0x3b], ["'", 0x27],
    ["[", 0x5b], ["]", 0x5d], ["\\", 0x5c], ["`", 0x60]
];
(function () {
    var i;
    for (i = 0; i < 26; i++) KEYS.push([String.fromCharCode(65 + i), 65 + i]);
    for (i = 0; i < 10; i++) KEYS.push([String(i), 48 + i]);
    for (i = 1; i <= 12; i++) KEYS.push(["F" + i, 0x01000030 + i - 1]);
    for (i = 0; i < 10; i++) KEYS.push(["Num+" + i, KEYPAD | (48 + i)]);
})();

var BY_CODE = {};
var BY_NAME = {};
KEYS.forEach(function (k) { BY_CODE[k[1]] = k[0]; BY_NAME[k[0].toLowerCase()] = k[1]; });

// key code without modifiers, except the keypad flag that belongs to the key
function baseKey(code) { return code & ~(SHIFT | CTRL | ALT | META); }

// 0x0C000012 -> "Ctrl+Alt+Left" (same order KDE shows: Meta, Ctrl, Alt, Shift)
function toText(code) {
    if (!code) return "";
    var parts = [];
    if (code & META) parts.push("Meta");
    if (code & CTRL) parts.push("Ctrl");
    if (code & ALT) parts.push("Alt");
    if (code & SHIFT) parts.push("Shift");
    var k = baseKey(code);
    var name = BY_CODE[k];
    if (!name) {
        var plain = k & ~KEYPAD;
        name = plain >= 0x20 && plain < 0x7f ? String.fromCharCode(plain) : "0x" + plain.toString(16);
        if (k & KEYPAD) name = "Num+" + name;
    }
    parts.push(name);
    return parts.join("+");
}

// "Ctrl+Alt+Left" -> code (0 if unknown)
function fromText(text) {
    if (!text) return 0;
    var parts = String(text).split("+");
    var mods = 0, rest = [];
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i].toLowerCase();
        if (p === "meta") mods |= META;
        else if (p === "ctrl") mods |= CTRL;
        else if (p === "alt") mods |= ALT;
        else if (p === "shift") mods |= SHIFT;
        else rest.push(parts[i]);
    }
    var key = BY_NAME[rest.join("+").toLowerCase()];
    if (rest.length === 0 && text.slice(-1) === "+") key = 0x2b;
    return key ? (mods | key) : 0;
}

function modifiers(code) { return code & (SHIFT | CTRL | ALT | META); }

// --------------------------------------------------------------- actions
// id: ShortcutHandler name, key: the key the default scheme combines with
// modifiers, num: key in the keypad scheme
var ACTIONS = [
    { id: "KDESnapLayoutLeft",        group: "halves",   text: "Snap to the left half",           key: "Left",   num: "Num+4" },
    { id: "KDESnapLayoutRight",       group: "halves",   text: "Snap to the right half",          key: "Right",  num: "Num+6" },
    { id: "KDESnapLayoutTop",         group: "halves",   text: "Snap to the top half",            key: "Up",     num: "Num+8" },
    { id: "KDESnapLayoutBottom",      group: "halves",   text: "Snap to the bottom half",         key: "Down",   num: "Num+2" },
    { id: "KDESnapLayoutTopLeft",     group: "quarters", text: "Snap to the top-left quarter",    key: "U",      num: "Num+7" },
    { id: "KDESnapLayoutTopRight",    group: "quarters", text: "Snap to the top-right quarter",   key: "I",      num: "Num+9" },
    { id: "KDESnapLayoutBottomLeft",  group: "quarters", text: "Snap to the bottom-left quarter", key: "J",      num: "Num+1" },
    { id: "KDESnapLayoutBottomRight", group: "quarters", text: "Snap to the bottom-right quarter",key: "K",      num: "Num+3" },
    { id: "KDESnapLayoutThirdLeft",   group: "thirds",   text: "Snap to the left third",          key: "D",      num: "" },
    { id: "KDESnapLayoutThirdCenter", group: "thirds",   text: "Snap to the center third",        key: "F",      num: "" },
    { id: "KDESnapLayoutThirdRight",  group: "thirds",   text: "Snap to the right third",         key: "G",      num: "" },
    { id: "KDESnapLayoutTwoThirdsLeft",  group: "thirds", text: "Snap to the left two thirds",    key: "E",      num: "" },
    { id: "KDESnapLayoutTwoThirdsRight", group: "thirds", text: "Snap to the right two thirds",   key: "Y",      num: "" },
    { id: "KDESnapLayoutMaximize",    group: "window",   text: "Maximize or restore",             key: "Return", num: "Num+5" },
    { id: "KDESnapLayoutCenter",      group: "window",   text: "Center the window",               key: "C",      num: "Num+0" },
    { id: "KDESnapLayoutRestore",     group: "window",   text: "Restore the size before snapping", key: "-",    num: "" },
    { id: "KDESnapLayoutToggle",      group: "features", text: "Snap bar on/off",                 key: "",       num: "" },
    { id: "KDESnapLayoutToggleEdges", group: "features", text: "Screen edges on/off",             key: "",       num: "" },
    { id: "KDESnapLayoutToggleMagnet",group: "features", text: "Window magnet on/off",            key: "",       num: "" },
    { id: "KDESnapLayoutDemo",        group: "features", text: "Test the snap bar",               key: "",       num: "" }
];

var GROUPS = [
    { id: "halves",   text: "Halves" },
    { id: "quarters", text: "Quarters" },
    { id: "thirds",   text: "Thirds" },
    { id: "window",   text: "Window" },
    { id: "features", text: "Features" }
];

// Ready-made key sets. "Ctrl+Alt" is the classic scheme of window tiling tools;
// the keypad scheme follows the layout of the number block (7 8 9 / 4 5 6 / 1 2 3).
var SCHEMES = [
    { id: "ctrlalt",     text: "Ctrl+Alt + key (default)", mods: CTRL | ALT },
    { id: "metactrlalt", text: "Meta+Ctrl+Alt + key",       mods: META | CTRL | ALT },
    { id: "meta",        text: "Meta + key (KDE style)",    mods: META },
    { id: "metashift",   text: "Meta+Shift + key",          mods: META | SHIFT },
    { id: "ctrlshiftalt",text: "Ctrl+Shift+Alt + key",      mods: CTRL | SHIFT | ALT },
    { id: "keypad",      text: "Ctrl+Alt + number block",   mods: CTRL | ALT, keypad: true },
    { id: "none",        text: "No shortcuts",              mods: 0 }
];

function actionById(id) {
    for (var i = 0; i < ACTIONS.length; i++) if (ACTIONS[i].id === id) return ACTIONS[i];
    return null;
}

// key of an action in a scheme, 0 = none
function schemeKey(action, scheme) {
    if (!scheme || scheme.id === "none") return 0;
    var name = scheme.keypad ? action.num : action.key;
    if (!name) return 0;
    var k = BY_NAME[name.toLowerCase()];
    return k ? (scheme.mods | k) : 0;
}

function defaultKey(action) { return schemeKey(action, SCHEMES[0]); }
function defaultText(action) { return toText(defaultKey(action)); }

// The usual alternatives for one action: its key with every scheme's modifiers.
function suggestions(action) {
    var out = [], seen = {};
    for (var i = 0; i < SCHEMES.length; i++) {
        var k = schemeKey(action, SCHEMES[i]);
        if (k && !seen[k]) { seen[k] = true; out.push(k); }
    }
    // KDE's own shortcut for the same job, in case someone wants to take it over
    var kde = { Left: META | 0x01000012, Right: META | 0x01000014, Up: META | 0x01000013,
                Down: META | 0x01000015, Return: META | 0x01000016 };
    if (kde[action.key] && !seen[kde[action.key]]) out.push(kde[action.key]);
    return out;
}

// zone fractions for the snapping actions
var ZONES = {
    KDESnapLayoutLeft:        { x: 0,     y: 0,   w: 0.5,   h: 1 },
    KDESnapLayoutRight:       { x: 0.5,   y: 0,   w: 0.5,   h: 1 },
    KDESnapLayoutTop:         { x: 0,     y: 0,   w: 1,     h: 0.5 },
    KDESnapLayoutBottom:      { x: 0,     y: 0.5, w: 1,     h: 0.5 },
    KDESnapLayoutTopLeft:     { x: 0,     y: 0,   w: 0.5,   h: 0.5 },
    KDESnapLayoutTopRight:    { x: 0.5,   y: 0,   w: 0.5,   h: 0.5 },
    KDESnapLayoutBottomLeft:  { x: 0,     y: 0.5, w: 0.5,   h: 0.5 },
    KDESnapLayoutBottomRight: { x: 0.5,   y: 0.5, w: 0.5,   h: 0.5 },
    KDESnapLayoutThirdLeft:   { x: 0,     y: 0,   w: 1 / 3, h: 1 },
    KDESnapLayoutThirdCenter: { x: 1 / 3, y: 0,   w: 1 / 3, h: 1 },
    KDESnapLayoutThirdRight:  { x: 2 / 3, y: 0,   w: 1 / 3, h: 1 },
    KDESnapLayoutTwoThirdsLeft:  { x: 0,     y: 0, w: 2 / 3, h: 1 },
    KDESnapLayoutTwoThirdsRight: { x: 1 / 3, y: 0, w: 2 / 3, h: 1 }
};
