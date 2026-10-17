#!/usr/bin/env bash
# KDE Snap Layout – KWin script for Plasma 6
#   bash install.sh                     install or update
#   bash install.sh --no-top-maximize   also turn off KDE's "maximize when dragged to the top"
#   bash install.sh --uninstall         remove
# Without a terminal: System Settings → KWin Scripts → "Install from File…"
# and pick kdesnaplayout.kwinscript.
set -euo pipefail

ID="kdesnaplayout"
OLD_ID="win11snaplayouts"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package"
QDBUS="$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus || true)"

reload_kwin() { [[ -n "$QDBUS" ]] && "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true; }

# leftovers from the old "Win11 Snap-Layouts" versions
kwriteconfig6 --file kwinrc --group Plugins --key "${OLD_ID}Enabled" false
kpackagetool6 --type KWin/Script --remove "$OLD_ID" >/dev/null 2>&1 || true
systemctl --user stop win11-snaplayouts-settings.service >/dev/null 2>&1 || true
rm -f "$HOME/.config/systemd/user/win11-snaplayouts-settings.service" \
      "$HOME/.local/bin/win11-snaplayouts-settings" \
      "$HOME/.local/share/applications/win11-snaplayouts-settings.desktop"
kpackagetool6 --type Plasma/Applet --remove org.seaq.win11snaplayouts.settings >/dev/null 2>&1 || true

if [[ "${1:-}" == "--uninstall" ]]; then
    kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" false
    reload_kwin
    kpackagetool6 --type KWin/Script --remove "$ID" >/dev/null 2>&1 || true
    rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/kdesnaplayout.svg"   # left over from 1.6.1
    echo "Removed."
    exit 0
fi

# keep settings and layouts from the old name
if [[ -f "$HOME/.config/win11-snaplayouts.ini" && ! -f "$HOME/.config/kde-snaplayout.ini" ]]; then
    cp "$HOME/.config/win11-snaplayouts.ini" "$HOME/.config/kde-snaplayout.ini"
fi

# clean reinstall: an upgrade sometimes leaves stale files behind
kpackagetool6 --type KWin/Script --remove "$ID" >/dev/null 2>&1 || true
rm -rf "$HOME/.local/share/kwin/scripts/$ID"
kpackagetool6 --type KWin/Script --install "$DIR"

# KWin caches compiled QML; drop it so the new files are really used
rm -rf "$HOME/.cache/kwin/qmlcache" "$HOME/.cache/kwin_wayland/qmlcache" "$HOME/.cache/kwin_x11/qmlcache" 2>/dev/null || true

if [[ "${1:-}" == "--no-top-maximize" ]]; then
    kwriteconfig6 --file kwinrc --group Windows --key ElectricBorderMaximize false
fi

kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" false
reload_kwin
sleep 1
kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" true
reload_kwin

VER="$(grep -o '"Version": *"[^"]*"' "$DIR/metadata.json" | grep -o '[0-9.]*')"
echo "✓ KDE Snap Layout $VER installed."
echo "  KWin keeps already loaded script files in memory – log out and back in once."
echo "  Settings: System Settings → KWin Scripts → gear icon next to KDE Snap Layout."
