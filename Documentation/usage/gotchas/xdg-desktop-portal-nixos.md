# xdg-desktop-portal under non-KDE/GNOME WMs + home-manager

xdg-desktop-portal is fragile on NixOS when running a WM that isn't KDE or
GNOME (Hyprland, mango, niri, cosmic, sway, wlroots, ...) combined with
home-manager. Common symptom: Chromium-based apps (Helium, Chromium, Chrome,
Brave, Electron apps) silently fail to open file pickers - the dialog just
never appears. Print, Screenshot, and AppChooser portals can break the same
way.

## How the portal decides what's exposed (xdg-desktop-portal 1.22)

The portal frontend is one D-Bus service, `org.freedesktop.portal.Desktop`.
For every backend interface (FileChooser, Screenshot, Secret, ...) it picks one
`*.portal` backend. Four rules decide which:

1. **Portals load from every `XDG_DATA_DIRS` entry**, in order
   (`/etc/profiles/per-user/<user>/share` from home-manager before
   `/run/current-system/sw/share`). Both levels are loaded; a home-manager copy
   only shadows a system copy with the **same file name**. The binary ignores
   `NIX_XDG_DESKTOP_PORTAL_DIR` (the string is not in it), so the variable
   home-manager still sets has no effect.
2. **Config files are layered**: `~/.config/xdg-desktop-portal/`, then
   `/etc/xdg/xdg-desktop-portal/`, then every
   `XDG_DATA_DIRS/xdg-desktop-portal/<desktop>-portals.conf` shipped by
   packages (niri, plasma, cosmic, mango and hyprland ship one). Per interface,
   the first file whose list names a loaded backend implementing it wins. The
   `<desktop>` is each `XDG_CURRENT_DESKTOP` entry, lowercased. Our
   `default = [ ... "gtk" ]` lists make our file win nearly every interface.
3. **`UseIn=` in the `.portal` manifest is only the deprecated fallback.** It is
   consulted only when no config file names a usable backend for an interface;
   xdg-desktop-portal then logs
   `Choosing X.portal for IFACE via the deprecated UseIn key`. It does not gate
   loading and config routing ignores it.
4. **`none` stops the fallback.** An explicit `Interface=none` route makes the
   portal expose no backend for it instead of falling back.

### What goes wrong: bleeding

Because of rule 3, a backend whose manifest claims many desktops becomes the
fallback winner in sessions it does not belong to. The old permissive `UseIn=`
patch on gtk/kde/gnome did exactly that: in COSMIC, mango and XFCE the
portal fell back to `xdg-desktop-portal-kde` for Background, GlobalShortcuts,
RemoteDesktop, Clipboard, InputCapture and Usb (KWin/kglobalaccel dependent).
Stock `hyprland.portal` (`UseIn` includes `wlroots`) can leak into mango
(`XDG_CURRENT_DESKTOP=mango:wlroots`) the same way.

### How the repo handles it

`modules/nixos/toplevel/xdg-portal.nix`:

- gtk, kde and gnome keep their stock manifests. Only `xdg-desktop-portal-wlr`
  is overlay-patched (`wlrDesktops` = `mango;sway;wlroots`); the manifest-only
  `gnome-keyring.portal` carries its own `UseIn=` list.
- `portalConfig.mango`, `.cosmic` and `.common` (used by unlisted desktops such
  as the guest XFCE) route the session-only interfaces `Background`,
  `GlobalShortcuts`, `RemoteDesktop`, `Clipboard`, `InputCapture`, `Usb` to
  `none` (`common` also `ScreenCast`). mango also sets `Inhibit = none`
  (an empty list renders as an empty `Inhibit=` line, which xdp treats as
  unset, so `[ ]` does nothing).
- **Principle: follow each desktop's upstream default portal config.** The
  `<desktop>-portals.conf` shipped by the desktop package is the baseline
  (hyprland `hyprland;gtk`, niri `gnome;gtk` with Access/Notification = gtk,
  cosmic `cosmic;gtk`, mango `gtk` with wlr ScreenCast/Screenshot). The repo
  adds only what upstream leaves open: `Secret = gnome-keyring` everywhere, `none`
  routes where an unrouted interface would land on the deprecated `UseIn`
  fallback, and a gtk `FileChooser` for niri so the picker never depends on
  nautilus. Look and behaviour differences between desktops are accepted. The
  former "prefer the KDE file picker in Hyprland/niri/mango" overrides (Qt
  theme consistency) were removed: gtk is the upstream file picker there.
- Hyprland is exactly upstream (`hyprland;gtk`) plus Secret.
- KDE routes `Notification` to `plasmanotify;gtk` (kde.portal has no
  Notification interface, so `kde;gtk` would otherwise match gtk first).
- niri mirrors `niri-portals.conf` (`gnome;gtk`, Access and Notification gtk),
  plus `FileChooser = gtk`; ScreenCast/Screenshot reach gnome through the
  default list (niri implements `org.gnome.Mutter.ScreenCast`).
- mango routes `ScreenCast`/`Screenshot` to `wlr` (`lib.mkForce`, because the
  mango flake sets the same keys system-side only, and it also adds wlr to the
  system `extraPortals`; home-manager installs wlr as well).
- The same `portalConfig` is set at system level (`nixos.always`) and
  home-manager level (`home.always`), so the two never disagree.

## Implementation

Lives in `xdg-portal.nix` (toplevel module): an overlay patching `UseIn=` on
`xdg-desktop-portal-wlr`, registered via `nixpkgs.overlays`, then wired into
both `nixos.always` (`xdg.portal.extraPortals` = gtk, gnome, kde and a
manifest-only `gnome-keyring.portal`, plus `environment.pathsToLink`) and
`home.always` (`xdg.portal.extraPortals` = the same plus wlr) with a shared
`portalConfig`.

### Do not remove or "simplify" these - each is load-bearing

| Construct | What breaks if removed |
|---|---|
| `nixpkgs.overlays` patch (vs. inline `overrideAttrs`) | Inline wrapping creates a duplicate derivation → `user-units` symlink collision (`File exists: xdg-desktop-portal-gtk.service`) when other modules (flatpak, plasma6, hyprland, gnome) reference the same package. |
| `home.always` block (looks like a redundant duplicate of `nixos.always`) | home-manager's `xdg.portal.enable` writes the per-user config and share; without matching portals/config there, the two levels diverge. |
| `none` routes for the session-only interfaces in `mango`/`cosmic`/`common` | xdp falls back via `UseIn` to a backend of another desktop (kde, or hyprland under mango). |
| Re-adding a permissive `UseIn=` patch on gtk/kde/gnome | Reintroduces the bleeding described above (and rebuilds those portals locally from source). `test-secret-service` fails on it. |
| `environment.pathsToLink = [ "/share/xdg-desktop-portal" ]` | Home-manager's `xdg.portal` module asserts on this when `useUserPackages = true` (active in this repo) - removing it fails evaluation with an explicit error. |
| Shared `portalConfig` let-binding between both levels | Diverging config between the two levels makes the active routing depend on which copy is read first. |
| `home.always = { ... }: { ... }` with no `pkgs` destructure | denix's `home.always` doesn't pass `pkgs`; requesting it errors with `function 'always' called without required argument 'pkgs'`. Use the outer-scope (overlay-patched) `pkgs` instead. |

## Files that interact with this

- `xdg-portal.nix` (toplevel) - primary implementation.
- `home-manager.nix` (common toplevel, `nixos.always` block) - sets
  `useGlobalPkgs = false` / `useUserPackages = true`. First is why the
  home-level patch is needed at all (overlay doesn't propagate to home-manager
  pkgs otherwise); second triggers the `pathsToLink` assertion above. Don't
  flip either without verifying.
- `stylix-nixos.nix` / `qt.nix` - own dialog *rendering* (theme/dark-mode),
  orthogonal to whether the portal loads at all - see
  [stylix-qt-kde-gtk-theming.md](stylix-qt-kde-gtk-theming.md).
- Per-WM main modules (`mango-main.nix`, `hyprland-main.nix`, `niri-main.nix`)
  - `hyprland-main.nix` sets `XDG_CURRENT_DESKTOP` in Hyprland's own env block
  (its session only); `mango-main.nix` just forwards it into the systemd user
  environment (`systemd.variables`); `niri-main.nix` does not touch it. Never put
  `XDG_CURRENT_DESKTOP` / `XDG_SESSION_DESKTOP` / `XDG_SESSION_TYPE` in
  `home.sessionVariables`: `hm-session-vars` is sourced by every session's login
  shell and overwrites the value SDDM set from the session file (this once made
  COSMIC and GNOME report `mango`). Don't append extra desktop names here as a
  portal workaround - fix the routing in `portalConfig` instead.
- `helium.nix` (and other Chromium-based browser modules) - most visible
  symptom carrier. Don't add browser-specific flags as a fix; the issue is
  system-wide.

## Diagnosis recipe

0. **Check the routing without switching session** - `test-portal-routing`
   (`templates/tests/nixos/test-portal-routing/`) runs the real
   xdg-desktop-portal on a private D-Bus for every host, specialisation and
   session desktop, with the built shares and `xdg.portal.config`. For a single
   desktop by hand:
   `/home/krit/momentary/test-suite-expansion/95-portal-xdp-sim.sh <XDG_CURRENT_DESKTOP> <hm-share> <system-share> <xdg-config-home> <xdp-binary>`
   (the repo copy is `templates/tests/nixos/test-portal-routing/portal-xdp-sim.sh`,
   which takes one more argument: the dbus `bin` directory).

1. **Confirm it's the portal** - run the failing app from a terminal;
   look for `org.freedesktop.DBus.Error.InvalidArgs: No such interface
   "org.freedesktop.portal.FileChooser"`. Confirm with:
   ```fish
   busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep FileChooser
   ```
   Empty → no backend loaded at all.

2. **Find the scanned directories:**
   ```fish
   PID=$(pgrep -f "xdg-desktop-portal\$" | head -1)
   cat /proc/$PID/environ | tr '\0' '\n' | grep -E '^XDG_(DATA_DIRS|CURRENT_DESKTOP)='
   ```

3. **Verify the backends and config are actually there** (both levels are read):
   ```fish
   ls /run/current-system/sw/share/xdg-desktop-portal/portals/ /etc/profiles/per-user/*/share/xdg-desktop-portal/portals/
   cat ~/.config/xdg-desktop-portal/*-portals.conf /etc/xdg/xdg-desktop-portal/*-portals.conf
   ```

4. **Run the portal manually with debug output:**
   ```fish
   systemctl --user stop xdg-desktop-portal
   G_MESSAGES_DEBUG=all XDP_DEBUG=1 \
     $(systemctl --user cat xdg-desktop-portal | grep ExecStart | cut -d= -f2-) --replace > /tmp/xdp.log 2>&1 &
   sleep 3
   pkill -f "xdg-desktop-portal --replace"
   grep -E "Using .*\.portal for|deprecated UseIn|Skipping duplicate" /tmp/xdp.log
   ```
   Every interface should read `Using X.portal for IFACE (default config)` or
   `(interface specific config)`. Any `via the deprecated UseIn key` line is a
   missing route: add the interface to `portalConfig` (a real backend or `none`).

5. **Restart cleanly once fixed:**
   ```fish
   systemctl --user restart xdg-desktop-portal
   busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep FileChooser
   ```
   A new login may be needed for `XDG_DATA_DIRS` changes to reach the session.

## Dead ends to skip

1. Adding flags to the failing app (`--ozone-platform=auto`, etc.) - the bug
   is system-wide; flags don't help (`--ozone-platform=auto` is also invalid
   and breaks startup - only valid for `--ozone-platform-hint`).
2. Editing `XDG_CURRENT_DESKTOP` per-WM (e.g. `mango:KDE`) - works for one
   WM, doesn't generalize, drags in unrelated DE behaviors.
3. Patching `UseIn=` to make a backend "loadable" - on xdp 1.22 it does not
   gate loading; it only widens the deprecated fallback (bleeding).
4. Setting `NIX_XDG_DESKTOP_PORTAL_DIR` - ignored by the binary.
5. Inline `overrideAttrs` at NixOS level instead of the overlay - causes a
   `user-units` symlink collision.

## When to update this doc

New WM added without a `portalConfig` key; xdg-desktop-portal or home-manager
version bumps that change config lookup or the `UseIn=` fallback semantics;
`useGlobalPkgs`/`useUserPackages` flipped; a new portal-using app fails the
`busctl` check after a refactor; `test-portal-routing` needs a new expectation.

## `portalConfig` keys must be lowercase

xdg-desktop-portal (>= 1.18) lowercases each `XDG_CURRENT_DESKTOP` entry before
looking up `<desktop>-portals.conf`, on a case-sensitive filesystem. Keys such
as `Hyprland`, `KDE`, `GNOME` therefore never match; the `common`/`portals.conf`
file silently won instead. Keep the keys in `xdg-portal.nix` lowercase
(`hyprland`, `kde`, `gnome`, `cosmic`, `niri`, `mango`). 

Note: portals load from every `XDG_DATA_DIRS` entry, so the cosmic backend is
loadable from the system share (`cosmic.portal` serves FileChooser, Screenshot
and ScreenCast in COSMIC sessions); it is not installed at the home-manager
level, which does not matter.
