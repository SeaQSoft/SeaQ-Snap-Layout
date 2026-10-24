<div align="center">

<img src="docs/images/banner.png" alt="SeaQ Snap Layout – drag a window to the top edge, drop it onto a zone" width="100%">

# SeaQ Snap Layout

🇬🇧 English · 🇩🇪 [Deutsch](README.de.md)

**Snap layouts for KDE Plasma 6. Drag a window to the top edge of the screen, a bar with layouts slides down – drop the window onto a zone and it fills exactly that area.**

**Four ways to snap:** snap bar, screen edges with smart fill, a window magnet with sticky edges and 20 keyboard shortcuts – each one can be switched on and off on its own.

A pure KWin script: no extra program, no background service, nothing to compile.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-1d99f3?logo=kde&logoColor=white)
![KWin script](https://img.shields.io/badge/KWin-script-3daee9)
![Wayland & X11](https://img.shields.io/badge/Wayland%20%26%20X11-supported-41cd52)
![Languages](https://img.shields.io/badge/languages-62-7b5cff)
![Version](https://img.shields.io/badge/version-1.9.0-informational)

[Video](#-watch-the-intro) · [Features](#-features) · [More ways to snap](#-more-ways-to-snap) · [Shortcuts](#%EF%B8%8F-keyboard-shortcuts) · [Installation](#-installation) · [Manual](#-user-manual) · [Settings](#%EF%B8%8F-settings-at-a-glance) · [FAQ](#-troubleshooting--faq)

<br>

<img src="docs/images/demo.gif" alt="Dragging a window to the top edge, choosing a zone and dropping it" width="760">

</div>

---

## 🎬 Watch the intro

<div align="center">



https://github.com/user-attachments/assets/99b38fd4-24da-4bbf-a210-28a9fbe124fe



<sub>34 seconds · snapping two windows, the four ways to snap and the color options</sub>

</div>

---

## ⚡ How it works

<img src="docs/images/how-it-works.png" alt="1 Drag to the top · 2 Pick a zone · 3 Drop – done" width="100%">

1. **Drag** any window by its title bar towards the top edge. A small handle appears first.
2. **Pick a zone.** The snap bar slides down; the zone under the cursor lights up and a preview shows where the window will land.
3. **Drop.** The window fills exactly that zone. Drag it away again and it gets its old size back.

---

## ✨ Features

| | |
|---|---|
| 🪟 **Snap by dragging** | Works with the mouse movement you already know – no shortcuts to learn. |
| ⇲ **Screen edges** | Push a window against an edge or corner: maximize, halves, bottom half, quarters. Smart fill keeps snapped windows uncovered. |
| 🧲 **Window magnet** | Windows stick to each other and to the screen edges while you move them – no sliding over each other. |
| 🔗 **Sticky edges** | Resize a window and the windows touching it follow: the shared edge moves along, nothing overlaps, no gap opens. Shake the mouse to let go. |
| ⌨️ **Keyboard shortcuts** | 20 actions – halves, quarters, thirds, two thirds, maximize, center, restore. Six ready-made key schemes or your own keys. |
| 🔘 **Everything optional** | Snap bar, screen edges, magnet and shortcuts each have their own switch. Previews in the accent color or neutral. |
| 🧩 **Six layouts, eleven templates** | Halves, two thirds, three columns, main + stack, four quarters, center focus – and templates like six tiles or sidebar + grid. |
| ✏️ **Layout designer** | Split zones side by side or top and bottom, drag the dividers with snapping to ¼, ⅓ and ½. Up to 16 zones per layout. |
| ↕️ **Drag & drop ordering** | Reorder the layouts in the bar by dragging their cards. Hide, duplicate or delete them. |
| 🎨 **Your colors** | System, light or dark snap bar, your Plasma accent, twelve swatches or any color from the color wheel. |
| 📐 **Size & shape** | Bar size, thumbnail width, corner radius, opacity, several rows, optional layout and zone names. |
| ⏱️ **Tuned motion** | Trigger distance, handle distance, delays, slide distance, separate slide-in/out durations and six motion curves. Defaults are based on Windows 11. |
| 👁️ **Landing preview** | A translucent rectangle shows where the window will end up – including gaps and panels. |
| ↩️ **Restores sizes** | Dragging a snapped window out gives it its previous size back. |
| 🚫 **Exclusions & gaps** | Exclude apps by window class; add gaps between windows and to the screen edge. |
| 🖥️ **Multi-monitor** | The bar opens on the screen under the cursor, zones respect panels. |
| 🌍 **62 languages** | Editor and quick menu follow your system language, right-to-left included. |
| 🧷 **Feels native** | The settings editor uses your color scheme, accent, window decoration (including Aurorae themes) and font – and updates live. |

---

## 🧭 More ways to snap

<table>
<tr>
<td align="center" width="50%"><img src="docs/images/page-edges.png" alt="Screen edges settings page"><br><sub>Screen edges</sub></td>
<td align="center" width="50%"><img src="docs/images/page-magnet.png" alt="Window magnet settings page"><br><sub>Window magnet</sub></td>
</tr>
</table>

### ⇲ Screen edges

Push a window against an edge or a corner of the screen and it fills that part – with or without the snap bar.

| Where | Result |
|---|---|
| Top edge | Maximize (or Fullscreen · Top half · Off) |
| Middle of the left / right edge | Left / right half |
| Bottom edge | Bottom half |
| Corners (outer 20 % of each edge) | Quarter in that corner |

**Hold to fill:** a short push gives the half or quarter. Keep the window at the edge a moment longer (0.7 s by default) and it grows up to the next window – e.g. right next to a window that takes the left third. The preview shows it, and the windows then touch, so *sticky edges* keep them together while resizing.

**Smart fill:** if a window is already snapped at the bottom – even just a quarter – the top edge fills only the space above it instead of maximizing. Halves and quarters never cover snapped windows either. A short **push delay** (60 ms) makes sure that just passing an edge does nothing.

With snap bar *and* top edge on, the bar opens as usual: drop on a zone to use the layout, drop at the edge outside the bar for the top-edge action.

### 🧲 Window magnet

While you move or resize a window, its edges stick to nearby windows and to the screen edges. A window **does not slide over another one**: it stops at the edge and only lets go once you push it further in than the **resistance** (48 px by default, 0 = off). Adjustable **snap distance** (2 – 64 px), separate switches for windows, screen edges and resizing, and an option to keep the *Gap between windows* instead of touching.

### 🔗 Sticky edges

Windows that touch share their edge. Resize one of them and the others follow live – side by side, stacked or in a grid of four:

- **Shared edges move together** – the gap between the windows stays exactly as it was (also with *Gap between windows*).
- **Stacked windows stay in line** – windows above each other keep their left and right edges together, windows side by side their top and bottom edges.
- **Only real neighbours** – windows have to face each other along a stretch of edge; edges lying on the screen border are never linked.
- **Limits respected** – a window never gets smaller than its minimum size or pushed off the free screen area.
- **Shake to let go** – shake the mouse while resizing and the other windows jump back.
- **Clear feedback** – windows that do not follow are faded while you resize (can be switched off).

The idea comes from the KWin script [Sticky Window Snapping](https://store.kde.org/p/1112552) by Toni Dietze; SeaQ Snap Layout has its own, rewritten implementation.

**KDE's own helpers are paused automatically:** KDE's quick tiling at the screen edges (with its outline) and its window snap zones would react to the same drag. SeaQ Snap Layout pauses them while it runs – without changing your KDE settings. Switch the option off, disable or remove the script, and KDE's own behavior is back (it is never written to `kwinrc`).

> [!TIP]
> Both pause switches are on by default. If you switch them off, Plasma's own edge tiling and snap zones react to the same drag again – the editor then shows an orange hint.

---

## ⌨️ Keyboard shortcuts

<img src="docs/images/page-keys.png" alt="Keyboard shortcuts settings page" width="100%">

The shortcuts are normal KDE global shortcuts (*System Settings* → *Shortcuts* → *KWin*, search “Snap Layout”). On the **Keyboard shortcuts** page you can

- pick a **key scheme** and apply it to all actions at once,
- change a single action: one click on a **usual combination**, or build **your own** from Meta / Ctrl / Alt / Shift + key,
- **reset** a single action or **all keys** back to the chosen scheme,
- see keys that are **already in use** and take them over – or keep them.

| Action | Default (Ctrl+Alt) | Meta scheme | Number-block scheme |
|---|---|---|---|
| Snap to the left half | `Ctrl`+`Alt`+`Left` | `Meta`+`Left` | `Ctrl`+`Alt`+`Num+4` |
| Snap to the right half | `Ctrl`+`Alt`+`Right` | `Meta`+`Right` | `Ctrl`+`Alt`+`Num+6` |
| Snap to the top half | `Ctrl`+`Alt`+`Up` | `Meta`+`Up` | `Ctrl`+`Alt`+`Num+8` |
| Snap to the bottom half | `Ctrl`+`Alt`+`Down` | `Meta`+`Down` | `Ctrl`+`Alt`+`Num+2` |
| Snap to the top-left quarter | `Ctrl`+`Alt`+`U` | `Meta`+`U` | `Ctrl`+`Alt`+`Num+7` |
| Snap to the top-right quarter | `Ctrl`+`Alt`+`I` | `Meta`+`I` | `Ctrl`+`Alt`+`Num+9` |
| Snap to the bottom-left quarter | `Ctrl`+`Alt`+`J` | `Meta`+`J` | `Ctrl`+`Alt`+`Num+1` |
| Snap to the bottom-right quarter | `Ctrl`+`Alt`+`K` | `Meta`+`K` | `Ctrl`+`Alt`+`Num+3` |
| Snap to the left third | `Ctrl`+`Alt`+`D` | `Meta`+`D` | – |
| Snap to the center third | `Ctrl`+`Alt`+`F` | `Meta`+`F` | – |
| Snap to the right third | `Ctrl`+`Alt`+`G` | `Meta`+`G` | – |
| Snap to the left two thirds | `Ctrl`+`Alt`+`E` | `Meta`+`E` | – |
| Snap to the right two thirds | `Ctrl`+`Alt`+`Y` | `Meta`+`Y` | – |
| Maximize or restore | `Ctrl`+`Alt`+`Return` | `Meta`+`Return` | `Ctrl`+`Alt`+`Num+5` |
| Center the window | `Ctrl`+`Alt`+`C` | `Meta`+`C` | `Ctrl`+`Alt`+`Num+0` |
| Restore the size before snapping | `Ctrl`+`Alt`+`-` | `Meta`+`-` | – |
| Snap bar on/off | – | – | – |
| Screen edges on/off | – | – | – |
| Window magnet on/off | – | – | – |
| Test the snap bar | – | – | – |

The **Meta+Ctrl+Alt**, **Meta+Shift** and **Ctrl+Shift+Alt** schemes use the same keys with those modifiers. The *Meta* scheme replaces Plasma's own quick-tiling keys (Meta+arrows). The four on/off actions have no key by default.

---

## 🖼️ Preview

<div align="center">
<img src="docs/images/hero.png" alt="Snap bar open at the top edge with the landing preview on the left half" width="100%">
<sub>The snap bar with “Halves – zone 1” highlighted and the landing preview on the left.</sub>
<br><br>
<table>
<tr>
<td align="center" width="50%"><img src="docs/images/editor.png" alt="Settings editor in light and dark color schemes"><br><sub>Settings editor – follows your color scheme</sub></td>
<td align="center" width="50%"><img src="docs/images/designer.png" alt="Layout designer with four zones"><br><sub>Layout designer – split, resize, save</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/images/styles.png" alt="Light, dark, custom accent and two-row snap bars"><br><sub>Light, dark, any accent, names, several rows</sub></td>
<td align="center"><img src="docs/images/layouts.png" alt="All built-in layouts and templates"><br><sub>Built-in layouts and templates</sub></td>
</tr>
</table>
</div>

---

## 📦 Requirements

| | |
|---|---|
| Desktop | **KDE Plasma 6** (KWin 6) – Wayland or X11 |
| Distribution | Any – Fedora, Arch, openSUSE, KDE neon, Kubuntu, Debian … |
| Dependencies | None – everything ships with Plasma |

---

## 🚀 Installation

**Option A – KDE Store (easiest)**

*System Settings* → *Window Management* → *KWin Scripts* → **Get New…** → search **SeaQ Snap Layout** → **Install**. Then tick it and click **Apply**.

**Option B – file from GitHub**

1. Download **`kdesnaplayout-<version>.kwinscript`** from the [**Releases**](../../releases/latest) page.
2. *System Settings* → *Window Management* → *KWin Scripts* → **Install from File…** → choose the file.
3. Tick **SeaQ Snap Layout** and click **Apply**.

**Option C – terminal**

```bash
kpackagetool6 --type KWin/Script --install kdesnaplayout-1.9.0.kwinscript   # first install
kpackagetool6 --type KWin/Script --upgrade kdesnaplayout-1.9.0.kwinscript   # update
kwriteconfig6 --file kwinrc --group Plugins --key kdesnaplayoutEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
```

**Option D – from source**

```bash
git clone https://github.com/SeaQSoft/SeaQ-Snap-Layout.git
cd SeaQ-Snap-Layout
./build.sh                       # → dist/kdesnaplayout-<version>.kwinscript
./install.sh                     # optional: clean install for development
```

> [!IMPORTANT]
> KWin keeps a loaded script in memory. **After an update, log out and back in once.** The version is shown on the *About & Help* page of the settings editor.

> [!TIP]
> Plasma's own edge tiling and snap zones are paused automatically while SeaQ Snap Layout runs – there is nothing to change in System Settings.

<details>
<summary><b>Uninstall</b></summary>

```bash
kpackagetool6 --type KWin/Script --remove kdesnaplayout
rm ~/.config/kde-snaplayout.ini      # optional: delete your settings and layouts
```
</details>

---

## ⚙️ Opening the settings

<img src="docs/images/quick-menu.png" alt="KWin Scripts page with the gear icon and the SeaQ Snap Layout quick menu" width="100%">

1. *System Settings* → *Window Management* → *KWin Scripts* → **gear icon** next to *SeaQ Snap Layout*.
2. Click **Open Snap Layout settings editor**, then **OK** – the editor opens.
3. The quick menu can also switch the snap bar colors between *System*, *Light* and *Dark*.

---

## 📘 User manual

A complete, illustrated manual covers every page and every setting – with annotated screenshots, diagrams of all distances and motion curves, and a troubleshooting section.

<div align="center">

### [📥 Download the manual (PDF, 23 pages)](docs/manual/SeaQ-Snap-Layout-Manual.pdf)

🇩🇪 [Deutsche Anleitung (PDF)](docs/manual/SeaQ-Snap-Layout-Anleitung.pdf)

<sub>The HTML sources are in [`docs/manual/`](docs/manual/).</sub>

</div>

---

## 🎛️ Settings at a glance

<details open>
<summary><b>General</b></summary>

| Setting | Default | Range |
|---|---|---|
| Snap bar · Screen edges · Window magnet · Keyboard shortcuts | On | each on its own |
| Snap bar preview · Screen edges preview | On | each on its own – off means no preview at all |
| Show previews in the accent color | On | off = neutral frame |
| Restore the original size when dragging a window out | On | |
| Gap between windows | 0 px | 0 – 48 px |
| Gap to the screen edge | 0 px | 0 – 48 px |
| Excluded applications (window classes, one per line) | – | |
</details>

<details>
<summary><b>Appearance</b></summary>

| Setting | Default | Range |
|---|---|---|
| Color scheme | System | System / Light / Dark |
| Use the system accent color | On | or 12 swatches / color wheel |
| Snap bar size | 100 % | 60 – 200 % |
| Thumbnail width | 72 px | 48 – 160 px |
| Corner radius | 8 px | 0 – 24 px |
| Background opacity | 96 % | 40 – 100 % |
| Layouts per row | 0 (one row) | 0 – 12 |
| Show layout and zone names | Off | |
</details>

<details>
<summary><b>Behavior & Animation</b></summary>

| Setting | Default | Range |
|---|---|---|
| Trigger distance from the top edge | 24 px | 2 – 200 px |
| Show a small handle first | On | |
| Distance at which the handle appears | 140 px | 20 – 400 px |
| Active width along the top edge | 100 % | 10 – 100 % |
| Delay before showing | 40 ms | 0 – 600 ms |
| Distance before the bar hides again | 56 px | 0 – 300 px |
| Delay before hiding | 150 ms | 0 – 1000 ms |
| How far the bar slides down | 12 px | 0 – 150 px |
| Slide-in duration | 220 ms | 0 – 1000 ms |
| Slide-out duration | 150 ms | 0 – 1000 ms |
| Motion curve | Smooth | Smooth · Quick · Bouncy · Dynamic · Soft · Linear |
| Fade in and out | On | |
</details>

<details>
<summary><b>Screen edges</b></summary>

| Setting | Default | Range |
|---|---|---|
| Use screen edges | On | |
| Top edge | Maximize | Maximize · Fullscreen · Top half · Off |
| Left and right edge: half of the screen | On | |
| Bottom edge: bottom half | On | |
| Corners: quarter of the screen | On | |
| Smart fill – fit around snapped windows | On | |
| Distance to the edge | 4 px | 1 – 40 px |
| Push delay | 60 ms | 0 – 600 ms |
| Corner size | 20 % | 5 – 40 % |
| Hold at the edge to fill the free space | On | |
| Hold time | 700 ms | 200 – 2000 ms |
| Pause KDE's edge tiling and its preview | On | restored when switched off or removed |
</details>

<details>
<summary><b>Window magnet</b></summary>

| Setting | Default | Range |
|---|---|---|
| Use the window magnet | On | |
| Snap distance | 16 px | 2 – 64 px |
| Resistance against overlapping | 48 px | 0 – 200 px (0 = windows may overlap) |
| Stick to other windows | On | |
| Stick to the screen edges | On | |
| Also while resizing | On | |
| Keep the gap between windows | Off | |
| **Sticky edges:** resize touching windows together | On | |
| Keep stacked windows in line | On | |
| Shake to let go | On | |
| Fade the other windows | On | |
| Pause KDE's snap zones while the magnet is on | On | restored when switched off or removed |
</details>

<details>
<summary><b>Keyboard shortcuts</b></summary>

| Setting | Default | Options |
|---|---|---|
| Use keyboard shortcuts | On | off = keys stay assigned but do nothing |
| Key scheme | Ctrl+Alt + key | Ctrl+Alt · Meta+Ctrl+Alt · Meta · Meta+Shift · Ctrl+Shift+Alt · Ctrl+Alt + number block · none |

All keys: see [Keyboard shortcuts](#%EF%B8%8F-keyboard-shortcuts).
</details>

---

## 🗂️ Project structure

```
SeaQ-Snap-Layout/
├── package/                    the KWin script (what gets installed)
│   ├── metadata.json
│   └── contents/
│       ├── ui/                 main.qml (logic), SnapBar, SettingsPage, LayoutEditor, …
│       ├── code/               layouts.js, edges.js, keys.js, i18n.js, translations.js (generated)
│       ├── config/main.xml     quick-menu options (kwinrc)
│       ├── locale/             .mo files for the quick menu (generated)
│       └── icons/
├── i18n/                       one text file per language + build.py
├── docs/                       images, video, manuals (English + German, PDF + HTML)
├── README.de.md                German README
├── build.sh                    builds dist/kdesnaplayout-<version>.kwinscript
└── install.sh                  clean install for development
```

---

## 🌍 Translations

The interface follows the system language. 62 languages are included: all European languages, Chinese (simplified and traditional), Japanese, Korean, Hindi, Bengali, Tamil, Telugu, Marathi, Gujarati, Punjabi, Urdu, Arabic, Hebrew, Persian, Indonesian, Malay, Vietnamese, Thai, Filipino, Georgian, Armenian and more.

Each language is a plain text file in [`i18n/`](i18n) with one line per text, in the order of `i18n/master.txt`. To improve a translation, edit the file and run:

```bash
python3 i18n/check.py      # line counts and placeholders
python3 i18n/build.py      # regenerates translations.js and the .mo files
```

Pull requests with corrections or new languages are very welcome.

---

## ❓ Troubleshooting & FAQ

<details>
<summary><b>The snap bar does not appear.</b></summary>

Check that the script is ticked in *KWin Scripts* and that *Active* is on in the editor. The app must not be on the exclusion list, and the window must be a normal, resizable window dragged by its title bar.
</details>

<details>
<summary><b>Two things happen when I drag a window to an edge.</b></summary>

Plasma's own edge tiling or snap zones are active. Switch on *Pause KDE's edge tiling and its preview* (Screen edges page) and *Pause KDE's snap zones while the magnet is on* (Window magnet page) – both are on by default.
</details>

<details>
<summary><b>A keyboard shortcut does nothing.</b></summary>

Check the *Shortcuts* switch and that the key is shown on the *Keyboard shortcuts* page. If the key is used by something else, the page shows it – take it over or pick another scheme.
</details>

<details>
<summary><b>I updated, but the old version is still running.</b></summary>

Log out and back in once. KWin keeps loaded scripts in memory.
</details>

<details>
<summary><b>The quick menu button does nothing.</b></summary>

After **Open Snap Layout settings editor** you have to click **OK** (or **Apply**). The editor appears about one second later.
</details>

<details>
<summary><b>How do I report a bug?</b></summary>

Open an [issue](../../issues) and include the log:

```bash
journalctl --user -b | grep kdesnaplayout | tail -n 30
```
</details>

---

## ☕ Support

If you like SeaQ Snap Layout, you can support its development – thank you! ♥

<p align="center">
<a href="https://paypal.me/SeaQSoft"><img src="https://img.shields.io/badge/Donate-PayPal-0070ba?logo=paypal&logoColor=white&style=for-the-badge" alt="Donate with PayPal"></a>
<a href="https://buymeacoffee.com/seaq"><img src="https://img.shields.io/badge/Buy%20me%20a-coffee-ffdd00?logo=buymeacoffee&logoColor=black&style=for-the-badge" alt="Buy me a coffee"></a>
</p>

---

## 📜 License

SeaQ Snap Layout is free software, licensed under the [GNU General Public License v3.0 or later](LICENSE).

<div align="center">
<br>
Made with ❤️ for KDE by <a href="https://github.com/SeaQSoft"><b>SeaQ</b></a>
<br><br>
<sub>If SeaQ Snap Layout makes your day a little tidier, a ⭐ on GitHub helps others find it.</sub>
</div>
