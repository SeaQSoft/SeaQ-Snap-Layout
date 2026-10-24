# Changelog

## 1.9.0
- **Hold to fill:** a short push at an edge gives the half or quarter; held a moment longer, the window grows up to the next window (all edges and corners, adjustable hold time). The windows then touch, so sticky edges keep them together
- **KDE's own edge tiling and its outline are paused** while SeaQ Snap Layout runs, so only one preview appears; KDE's snap zones pause while the magnet is on. Nothing is written to `kwinrc` – switched off, disabled or removed, KDE's behavior is back
- Previews: separate switches for the snap bar and the screen edges, clearly labeled; off means no preview at all
- Buttons, switches and sliders in the system accent color, the same with every Plasma style
- About & Help: *Donate with PayPal* and *Buy me a coffee* buttons
- New texts in all 62 languages

## 1.8.0
- Renamed to **SeaQ Snap Layout (for KDE)** – the script id stays `kdesnaplayout`, so updates keep your settings and keys
- **Sticky edges:** resize a window and the windows touching it follow – shared edges move together, the gap is kept, nothing overlaps
- Stacked windows keep their edges in line; shake the mouse while resizing to let the others go; windows that do not follow are faded
- Only windows that really face each other are linked, edges on the screen border never; minimum sizes and the free screen area are respected
- Window magnet uses the geometry KWin reports with each step (more reliable on Wayland); while resizing, the dragged window stays with KWin and the magnet applies on release
- New texts in all 62 languages

## 1.7.1
- Window magnet: windows no longer slide over each other – a window stops at the edge of another one and only lets go after a firm push (new setting *Resistance against overlapping*, default 48 px). Also works at the screen edges
- Quick menu: once clicked, the *Open Snap Layout settings editor* button is filled with the system accent color (text in the matching selection color – white on dark, black on light accents)
- Settings editor opens larger; the sidebar is wider, section headers wrap, the page list scrolls on its own and the feature switches no longer overlap
- New monitor illustrations for screen edges and window magnet
- Keyboard page: the key editor wraps inside its panel; new *Reset to default* per action (also as a small arrow next to changed keys) and *Reset all* for every key
- Author: SeaQ
- New texts in all 62 languages

## 1.7.0
- **Screen edges:** push a window against an edge or corner – top maximizes (or fullscreen / top half / off), left and right give halves, bottom gives the bottom half, corners give quarters
- **Smart fill:** if a window is already snapped at the bottom, the top edge fills only the space above it; halves and quarters never cover snapped windows
- Push delay, edge distance and corner size are adjustable
- **Window magnet:** windows stick to each other and to the screen edges while moving and resizing; adjustable snap distance, optional gap between windows
- **Keyboard shortcuts:** 20 actions (halves, quarters, thirds, two thirds, maximize, center, restore, feature switches) with six ready-made key schemes – default Ctrl+Alt + key
- Change single keys in the editor: usual combinations with one click or your own combination; keys already in use are shown and can be taken over
- Snap bar, screen edges, magnet and shortcuts can each be switched on and off on their own – also from the sidebar
- Previews in the accent color or as a neutral frame
- Hints when Plasma's own edge actions or snap zones would react to the same drag
- New sidebar sections “Snap bar” and “More ways to snap”, new pages Screen edges, Window magnet, Keyboard shortcuts
- All new texts in 62 languages
- Manual: new chapters for the three new features and a full key reference

## 1.6.5
- The settings editor takes **all** its colors from the system color scheme – text included. Controls no longer pick up the Plasma style colors, which could be light-on-light with a light color scheme
- Percent label in the layout designer uses the system's text-on-accent color

## 1.6.4
- The editor's title bar copies the measurements of your window decoration: height, button size and spacing, title font and alignment
- Aurorae themes: reads the theme's own layout values and the "Button size" setting; Breeze-like decorations: sizes follow the title font
- The window icon only appears when your decoration has a menu button, just like on real windows
- Decoration, button size and font changes are picked up live while the editor is open

## 1.6.3
- The window decoration is read the same way KWin reads it (`kwinrc` → `kdedefaults/kwinrc` → `/etc/xdg/kwinrc`), so decorations set by a Global Theme are recognised on every system
- Aurorae buttons are searched in the home folder, `/usr/local/share` and `/usr/share`
- Fixed "Cannot read property 'dragWin' of null" messages after the script is reloaded

## 1.6.0 – 1.6.2
- Renamed to **KDE Snap Layout**
- Settings editor with sidebar: General, Appearance, Behavior & Animation, Layouts, About & Help
- Minimal quick menu behind the gear icon: open the editor, snap bar colors
- Interface in 62 languages, following the system language (right-to-left included)
- Custom accent color with a color wheel
- Editor buttons drawn like the system decoration, Aurorae themes supported

## Earlier versions
- Developed as "Win11 Snap-Layouts": snap bar at the top edge, two-stage handle, landing preview, drag & drop layout order, layout designer, animation settings
