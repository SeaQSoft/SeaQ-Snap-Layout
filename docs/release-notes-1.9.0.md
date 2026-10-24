**KDE Snap Layout is now SeaQ Snap Layout (for KDE).** Same script, new name – the script id stays `kdesnaplayout`, so updating keeps your settings, layouts and keys.

## ✨ What's new in 1.9.0

- **Hold to fill** – a short push at a screen edge gives the half or quarter. Hold a moment longer and the window grows up to the next window. Works on all edges and corners, and the hold time is adjustable.
- **No more double previews** – KDE's own edge tiling and its outline pause while SeaQ Snap Layout runs, and KDE's snap zones pause while the magnet is on. Nothing is written to `kwinrc`: switch it off, disable or remove the script, and KDE behaves as before.
- **Separate preview switches** for the snap bar and the screen edges. Off means no preview at all.
- **Accent colors everywhere** – buttons, switches and sliders follow your system accent color.
- **Support buttons** in About & Help: *Donate with PayPal* and *Buy me a coffee*.

## Also included (1.7.1 – 1.8.0)

- **Sticky edges** – resize a window and the windows touching it follow. Shared edges move together, gaps are kept, nothing overlaps. Shake the mouse to let them go.
- **Window magnet with resistance** – windows stop at each other's edges instead of sliding over them, and only let go after a firm push.
- Larger settings editor, wider sidebar, new illustrations.
- Keyboard page: reset single keys or all keys to their defaults.
- New texts in all 62 languages.

## 📘 Manual

- 🇬🇧 [User manual (PDF)](https://github.com/SeaQSoft/SeaQ-Snap-Layout/blob/main/docs/manual/SeaQ-Snap-Layout-Manual.pdf)
- 🇩🇪 [Deutsche Anleitung (PDF)](https://github.com/SeaQSoft/SeaQ-Snap-Layout/blob/main/docs/manual/SeaQ-Snap-Layout-Anleitung.pdf)

## 📦 Install / update

Download `kdesnaplayout-1.9.0.kwinscript` below, then:

```bash
# first install
kpackagetool6 --type KWin/Script --install kdesnaplayout-1.9.0.kwinscript
# update from an older version
kpackagetool6 --type KWin/Script --upgrade kdesnaplayout-1.9.0.kwinscript
```

Log out and back in once after updating – KWin keeps the old script in memory until then.

Requires KDE Plasma 6 (X11 or Wayland).

---

<details>
<summary>🇩🇪 Deutsch</summary>

**Aus KDE Snap Layout wird SeaQ Snap Layout (for KDE).** Beim Update bleiben deine Einstellungen, Layouts und Tastenkürzel erhalten.

- **Halten zum Auffüllen** – kurz an die Kante: halber Bildschirm oder Viertel. Etwas länger halten: das Fenster wächst bis zum nächsten Fenster. Auf allen Seiten und Ecken.
- **Keine doppelte Vorschau mehr** – KDEs eigenes Kanten-Kacheln pausiert, solange SeaQ Snap Layout läuft. In `kwinrc` wird nichts geändert, beim Ausschalten oder Entfernen ist alles wie vorher.
- **Getrennte Vorschau-Schalter** für Snap-Leiste und Bildschirmkanten.
- **Akzentfarben** für Knöpfe, Schalter und Schieberegler.
- **Klebende Kanten** und **Fenster-Magnet mit Widerstand**.
- **Unterstützen**-Knöpfe in Info & Hilfe: PayPal und Buy me a coffee.
- Neue Texte in allen 62 Sprachen, dazu eine deutsche Anleitung als PDF.

Nach dem Update einmal ab- und wieder anmelden.
</details>

☕ If you like it: [PayPal](https://paypal.me/SeaQSoft) · [Buy me a coffee](https://buymeacoffee.com/seaq)
