.pragma library
.import "translations.js" as T

// Picks the UI language from the system (Plasma's language setting ends up in
// Qt's uiLanguages) and falls back to English. English source strings are the
// lookup keys, so a missing translation simply shows the English text.

var RTL = ["ar", "he", "fa", "ur"];

function pick() {
    var wanted = [];
    try { wanted = wanted.concat(Qt.locale().uiLanguages || []); } catch (e) {}
    try { wanted.push(Qt.locale().name); } catch (e) {}

    for (var i = 0; i < wanted.length; i++) {
        var l = String(wanted[i]).replace(/-/g, "_");
        if (!l) continue;
        var base = l.split("_")[0].toLowerCase();

        if (base === "zh") {
            // Script tags win over regions: zh_Hant_HK -> Traditional
            if (/Hant|_TW|_HK|_MO/.test(l)) return "zh_TW";
            return "zh_CN";
        }
        if (base === "pt") return /_BR/.test(l) ? "pt_BR" : "pt";
        if (base === "sr") return /Latn|latin/.test(l) ? "sr@latin" : "sr";
        if (base === "nn" || base === "no") base = "nb";
        if (base === "fil") base = "tl";
        if (base === "en") return "en";
        if (T.data[l]) return l;
        if (T.data[base]) return base;
    }
    return "en";
}

var lang = pick();
var table = T.data[lang] || {};

function tr(s) {
    var out = table[s];
    if (out === undefined || out === "") out = s;
    for (var i = 1; i < arguments.length; i++)
        out = out.split("%" + i).join(String(arguments[i]));
    return out;
}

// Layout names starting with "@" are built-in and translated on display.
function layoutName(n) {
    n = String(n || "");
    return n.charAt(0) === "@" ? tr(n.slice(1)) : n;
}

function isRtl() {
    return RTL.indexOf(lang.split("_")[0]) >= 0;
}
