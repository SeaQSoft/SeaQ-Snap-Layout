import QtQuick
import QtCore
import org.kde.ksvg as KSvg

// Draws one button from the active Aurorae decoration theme, e.g. close.svg.
// Themes live in ~/.local/share, /usr/local/share or /usr/share (aurorae/themes).
Item {
    id: g

    property string themeName: ""
    property string file: "close"
    property bool hovered: false
    property bool pressed: false

    readonly property string state3: pressed ? "pressed" : (hovered ? "hover" : "active")
    readonly property string elem: pick(state3)
    readonly property bool ok: svg.imagePath !== "" && elem !== ""

    // sized by DecoButton; Aurorae stretches the element over the button too

    readonly property string home: String(StandardPaths.writableLocation(StandardPaths.GenericDataLocation)).replace(/^file:\/\//, "")

    property string path: ""
    onThemeNameChanged: resolve()
    onFileChanged: resolve()
    Component.onCompleted: resolve()
    function resolve() {
        path = findFile(themeName, file);
        console.info("[kdesnaplayout] aurorae", themeName, file, "->", path || "not found", "element:", pick(state3) || "none");
    }

    KSvg.Svg {
        id: svg
        imagePath: g.path
    }

    // Aurorae element names come with or without the "-center" suffix,
    // depending on whether the theme draws a frame around its buttons.
    function pick(st) {
        if (!svg.imagePath) return "";
        const tries = [st + "-center", st, "active-center", "active"];
        for (let i = 0; i < tries.length; i++)
            if (svg.hasElement(tries[i])) return tries[i];
        return "";
    }

    KSvg.Svg { id: probe }

    function findFile(theme, f) {
        if (!theme) return "";
        const dirs = [home + "/aurorae/themes/" + theme, "/usr/local/share/aurorae/themes/" + theme, "/usr/share/aurorae/themes/" + theme];
        const names = f === "restore" ? ["restore", "maximize"] : [f];
        for (let n = 0; n < names.length; n++) {
            for (let d = 0; d < dirs.length; d++) {
                for (const ext of [".svg", ".svgz"]) {
                    const candidate = dirs[d] + "/" + names[n] + ext;
                    probe.imagePath = candidate;
                    if (probe.isValid()) return candidate;
                }
            }
        }
        return "";
    }

    KSvg.SvgItem {
        anchors.fill: parent
        svg: svg
        elementId: g.elem
    }
}
