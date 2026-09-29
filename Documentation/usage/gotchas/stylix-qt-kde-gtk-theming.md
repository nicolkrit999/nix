# Stylix + Qt/KDE/GTK theming: safe handling across any DE/WM

Covers three related theming bugs and the rule that prevents the worst one
(a Plasma crash) from coming back.

## Never enable `stylix.targets.qt`

`stylix.targets.qt` forces `qt.platformTheme.name = "qtct"`. This strips
`plasma-integration` from Plasma's own Qt widgets → Plasma either refuses to
start or crashes on the first mouse click (confirmed user experience).

Always keep `qt.enable = false` explicitly in the stylix targets block
(`modules/nixos/toplevel/stylix-nixos.nix`), with a comment explaining why -
stylix's qt module auto-enables via `autoEnable` (`nixosConfig != null`)
unless explicitly forced off.

## KDE file picker zebra-striping

**Symptom:** KDE file picker / Dolphin shows zebra-striped light/dark rows
when `kdeglobals` lacks `[Colors:*]` sections - a `ColorScheme = "BreezeDark"`
label alone isn't enough; `KColorScheme` needs the full `[Colors:View]`,
`[Colors:Window]`, `[ColorEffects:*]` sections.

**Fix:** `stylix.targets.kde = !isCatppuccin` in `stylix-nixos.nix` - writes a
system-level kdeglobals fragment via `xdg.systemDirs.config` plus a `.colors`
file via `XDG_DATA_DIRS`. Safe on any DE/WM: activation wraps
`plasma-apply-lookandfeel` in `|| true`, so it no-ops on non-Plasma hosts.

Writing to system config level is required because `plasma-manager` (with
`overrideConfig = lib.mkForce true` in `kde-main.nix`) wipes
`~/.config/kdeglobals` on every rebuild - any `home.activation` script writing
there directly gets clobbered.

## GTK3 apps / GTK3 portal fallback showing light theme

**Symptom:** GTK3 apps and `xdg-desktop-portal-gtk` (the fallback file picker
portal) show light theme even with `color-scheme = prefer-dark` set. GTK4/
libadwaita reads `color-scheme` from the portal automatically; GTK3 does not -
it needs `gtk-application-prefer-dark-theme = 1` in
`~/.config/gtk-3.0/settings.ini`. (GNOME ≤48 auto-propagated this; GNOME 49
removed the GSettings key that did so.)

Root cause that triggers it: apps can inherit `XDG_CURRENT_DESKTOP` from
whichever session they were originally launched in, routing to the wrong
portal backend (e.g. a `mango`-launched app falling back to
`xdg-desktop-portal-gtk`, which needs the dark setting explicitly).

**Fix:** in `stylix-nixos.nix`, inside `home.ifEnabled`, the `gtk` block
unconditionally sets `gtk3.extraConfig.gtk-application-prefer-dark-theme` and
the GTK4 equivalent, driven by `polarity` - not by which DE/WM is active.
Applies in both catppuccin and base16 modes.

## The two orthogonal axes

- **Theme mode** (`isCatppuccin` vs base16/stylix) - the only axis that
  should drive theming decisions.
- **DE/WM combo** (Plasma, Hyprland, niri, mango, cosmic, ...) - must be
  irrelevant; modules should be self-sustainable regardless of which one is
  active, because `xdg.systemDirs.config` and the unconditional gtk block
  work the same way no matter which portal/DE loads it.

## Backend availability is a separate concern

The above only matters once a portal backend is actually **loaded**.
Whether a backend loads at all under a non-KDE/GNOME WM is a different
problem - see
[xdg-desktop-portal-nixos.md](xdg-desktop-portal-nixos.md).
If `busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep FileChooser`
returns nothing, the bug is backend availability, not theming.

## File map

| File | Role |
|------|------|
| `modules/nixos/toplevel/stylix-nixos.nix` | Stylix target flags + unconditional gtk3/gtk4 dark extraConfig |
| `modules/nixos/toplevel/qt.nix` | QPA env var, qt5ct/qt6ct config, plasma-integration conditional |
| `modules/nixos/programs/de-wm/kde/kde-main.nix` | `overrideConfig = lib.mkForce true` - wipes `~/.config/kdeglobals` every rebuild |
| `xdg-portal.nix` (toplevel) | Backend availability - see the portal doc |

## Checklist when this breaks again

1. Does kdeglobals have a `[Colors:View]` section?
2. Is `stylix.targets.kde` enabled?
3. Is `stylix.targets.qt` still `false`? If someone flipped it `true`, that's the Plasma crash.
4. Did plasma-manager wipe user kdeglobals since the last rebuild?
5. Is `gtk3.extraConfig.gtk-application-prefer-dark-theme` still in the unconditional gtk block?
6. Does `~/.config/gtk-3.0/settings.ini` actually have `gtk-application-prefer-dark-theme=1`?
7. Is the FileChooser interface exposed at all (`busctl` check above)? If not, it's backend-availability - see the portal doc, fixing theming won't help.
