#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 SeaQ
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Builds the installable package → dist/ksnapunity-<version>.kwinscript
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(python3 -c "import json;print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")
OUT="dist/ksnapunity-${VERSION}.kwinscript"

# regenerate translations.js and the .mo files from i18n/*.txt
python3 i18n/build.py >/dev/null

mkdir -p dist
rm -f "$OUT"
find package -name "__pycache__" -type d -prune -exec rm -rf {} +
(cd package && zip -qr "../$OUT" metadata.json contents -x '*.qmlc')

echo "✔ $OUT"
echo
echo "Install:"
echo "  kpackagetool6 --type KWin/Script --install $OUT    # first time"
echo "  kpackagetool6 --type KWin/Script --upgrade $OUT    # update"
echo "Then log out and back in once."
