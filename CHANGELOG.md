# Changelog

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
