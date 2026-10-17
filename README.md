<div align="center">

<img src="docs/images/banner.png" alt="KDE Snap Layout – drag a window to the top edge, drop it onto a zone" width="100%">

# KDE Snap Layout

**Snap layouts for KDE Plasma 6. Drag a window to the top edge of the screen, a bar with layouts slides down – drop the window onto a zone and it fills exactly that area.**

A pure KWin script: no extra program, no background service, nothing to compile.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-1d99f3?logo=kde&logoColor=white)
![KWin script](https://img.shields.io/badge/KWin-script-3daee9)
![Wayland & X11](https://img.shields.io/badge/Wayland%20%26%20X11-supported-41cd52)
![Languages](https://img.shields.io/badge/languages-62-7b5cff)
![Version](https://img.shields.io/badge/version-1.6.5-informational)

[Video](#-watch-the-intro) · [Features](#-features) · [Installation](#-installation) · [Manual](#-user-manual) · [Settings](#%EF%B8%8F-settings-at-a-glance) · [FAQ](#-troubleshooting--faq)

<br>

<img src="docs/images/demo.gif" alt="Dragging a window to the top edge, choosing a zone and dropping it" width="760">

</div>

---

## 🎬 Watch the intro

<div align="center">



https://github.com/user-attachments/assets/befe5993-af49-4e00-9e5b-f22f84b214b6



<sub>34 seconds · snapping two windows, the settings editor and the color options</sub>

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

*System Settings* → *Window Management* → *KWin Scripts* → **Get New…** → search **KDE Snap Layout** → **Install**. Then tick it and click **Apply**.

**Option B – file from GitHub**

1. Download **`kdesnaplayout-<version>.kwinscript`** from the [**Releases**](../../releases/latest) page.
2. *System Settings* → *Window Management* → *KWin Scripts* → **Install from File…** → choose the file.
3. Tick **KDE Snap Layout** and click **Apply**.

**Option C – terminal**

```bash
kpackagetool6 --type KWin/Script --install kdesnaplayout-1.6.5.kwinscript   # first install
kpackagetool6 --type KWin/Script --upgrade kdesnaplayout-1.6.5.kwinscript   # update
kwriteconfig6 --file kwinrc --group Plugins --key kdesnaplayoutEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
```

**Option D – from source**

```bash
git clone https://github.com/Swenix-dev/KDE-Snap-Layout.git
cd KDE-Snap-Layout
./build.sh                       # → dist/kdesnaplayout-<version>.kwinscript
./install.sh                     # optional: clean install for development
```

> [!IMPORTANT]
> KWin keeps a loaded script in memory. **After an update, log out and back in once.** The version is shown on the *About & Help* page of the settings editor.

> [!TIP]
> Plasma maximizes windows that are dragged to the top edge. For the smoothest snapping, turn that off under *System Settings* → *Window Management* → *Screen Edges*.

<details>
<summary><b>Uninstall</b></summary>

```bash
kpackagetool6 --type KWin/Script --remove kdesnaplayout
rm ~/.config/kde-snaplayout.ini      # optional: delete your settings and layouts
```
</details>

---

## ⚙️ Opening the settings

<img src="docs/images/quick-menu.png" alt="KWin Scripts page with the gear icon and the KDE Snap Layout quick menu" width="100%">

1. *System Settings* → *Window Management* → *KWin Scripts* → **gear icon** next to *KDE Snap Layout*.
2. Click **Open Snap Layout settings editor**, then **OK** – the editor opens.
3. The quick menu can also switch the snap bar colors between *System*, *Light* and *Dark*.

---

## 📘 User manual

A complete, illustrated manual covers every page and every setting – with annotated screenshots, diagrams of all distances and motion curves, and a troubleshooting section.

<div align="center">

### [📥 Download the manual (PDF, 19 pages)](docs/manual/KDE-Snap-Layout-Manual.pdf)

<sub>The HTML source is in [`docs/manual/manual.html`](docs/manual/manual.html).</sub>

</div>

---

## 🎛️ Settings at a glance

<details open>
<summary><b>General</b></summary>

| Setting | Default | Range |
|---|---|---|
| Show the snap bar when dragging a window to the top edge | On | |
| Preview where the window will land | On | |
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
<summary><b>Keyboard shortcuts</b></summary>

Two actions are registered with KWin, without a default key: **KDE Snap Layout: turn on/off** and **KDE Snap Layout: test the snap bar**. Assign keys under *System Settings* → *Keyboard* → *Shortcuts* → *KWin*.
</details>

---

## 🗂️ Project structure

```
KDE-Snap-Layout/
├── package/                    the KWin script (what gets installed)
│   ├── metadata.json
│   └── contents/
│       ├── ui/                 main.qml (logic), SnapBar, SettingsPage, LayoutEditor, …
│       ├── code/               layouts.js, i18n.js, translations.js (generated)
│       ├── config/main.xml     quick-menu options (kwinrc)
│       ├── locale/             .mo files for the quick menu (generated)
│       └── icons/
├── i18n/                       one text file per language + build.py
├── docs/                       images, video, manual (PDF + HTML)
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
<summary><b>The window gets maximized instead of snapped.</b></summary>

That is Plasma’s own top-edge maximize – turn it off under *Screen Edges*.
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

## 📜 License

KDE Snap Layout is free software, licensed under the [GNU General Public License v3.0 or later](LICENSE).

<div align="center">
<br>
Made with ❤️ for KDE by <a href="https://github.com/Swenix-dev"><b>Swenix-dev</b></a>
<br><br>
<sub>If KDE Snap Layout makes your day a little tidier, a ⭐ on GitHub helps others find it.</sub>
</div>
