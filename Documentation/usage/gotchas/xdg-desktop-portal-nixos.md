# xdg-desktop-portal under non-KDE/GNOME WMs + home-manager

xdg-desktop-portal is fragile on NixOS when running a WM that isn't KDE or
GNOME (Hyprland, mango, niri, cosmic, sway, wlroots, ...) combined with
home-manager. Common symptom: Chromium-based apps (Helium, Chromium, Chrome,
Brave, Electron apps) silently fail to open file pickers - the dialog just
never appears. Print, Screenshot, and AppChooser portals can break the same
way.

## How the portal decides what's exposed

The portal frontend is one D-Bus service, `org.freedesktop.portal.Desktop`.
It exposes an interface (e.g. `org.freedesktop.portal.FileChooser`) only when
at least one backend implementation loads for the current
`XDG_CURRENT_DESKTOP`. Two independent gates control that.

### Gate 1 - `UseIn=` in each backend's `.portal` manifest

Stock NixOS values: `xdg-desktop-portal-gtk`/`-gnome` → `UseIn=gnome`,
`xdg-desktop-portal-kde` → `UseIn=KDE`, `-hyprland`/`-wlr` → wlroots-family
desktops but **no FileChooser interface at all**. Under
`XDG_CURRENT_DESKTOP=mango` (or Hyprland/niri/cosmic) every FileChooser-capable
backend is gated out - our `xdg.portal.config` routing can only choose
*between* loadable backends, it can't override `UseIn=`.

**Fix:** patch the `.portal` manifests to expand `UseIn=` to a permissive
desktop list. Adding a new WM later = append it to that list.

### Gate 2 - which directory the portal scans

Controlled by `NIX_XDG_DESKTOP_PORTAL_DIR`. NixOS-level `xdg.portal.enable`
points it at `/run/current-system/sw/share/xdg-desktop-portal/portals`;
home-manager's own `xdg.portal.enable` points it at the per-user profile path
instead, and **home-manager wins** because its session-vars script runs after
the system one. Home-manager's `xdg.portal.enable` is auto-enabled by
HM-side WM modules (e.g. `wayland.windowManager.hyprland.enable`), so it can
be active even with no explicit `xdg.portal.enable = true` anywhere in this
repo.

**Fix:** install the patched portal packages at **both** levels - NixOS
`extraPortals` for system D-Bus registration, and home-manager's own
`xdg.portal.extraPortals` (via `home.always`) so the per-user profile also
gets the patched manifests.

## Implementation

Lives in `xdg-portal.nix` (toplevel module): an overlay patching
`UseIn=` on `xdg-desktop-portal-gtk`/`-kde` to a permissive desktop list,
registered via `nixpkgs.overlays`, then wired into both `nixos.always`
(`xdg.portal.extraPortals` + `environment.pathsToLink`) and `home.always`
(`xdg.portal.extraPortals`) with a shared `portalConfig`.

### Do not remove or "simplify" these - each is load-bearing

| Construct | What breaks if removed |
|---|---|
| `nixpkgs.overlays` patch (vs. inline `overrideAttrs`) | Inline wrapping creates a duplicate derivation → `user-units` symlink collision (`File exists: xdg-desktop-portal-gtk.service`) when other modules (flatpak, plasma6, hyprland, gnome) reference the same package. |
| `home.always` block (looks like a redundant duplicate of `nixos.always`) | If only NixOS-level config exists, patched manifests land in `/run/current-system/sw/share/...` but the running portal scans the per-user profile (HM's `xdg.portal.enable` wins the env var). FileChooser vanishes. |
| `permissiveDesktops` including desktops "not currently used" | Adding a new WM later silently breaks if the list wasn't already permissive. Cheap insurance. |
| `environment.pathsToLink = [ "/share/xdg-desktop-portal" ]` | Home-manager's `xdg.portal` module asserts on this when `useUserPackages = true` (active in this repo) - removing it fails evaluation with an explicit error. |
| Shared `portalConfig` let-binding between both levels | Diverging config between the two levels makes the active routing depend on which env var wins - flaky. |
| `home.always = { ... }: { ... }` with no `pkgs` destructure | denix's `home.always` doesn't pass `pkgs`; requesting it errors with `function 'always' called without required argument 'pkgs'`. Use the outer-scope (overlay-patched) `pkgs` instead. |

## Files that interact with this

- `xdg-portal.nix` (toplevel) - primary implementation.
- `home-manager.nix` (common toplevel) - sets `useGlobalPkgs = false` /
  `useUserPackages = true`. First is why the home-level patch is needed at
  all (overlay doesn't propagate to home-manager pkgs otherwise); second
  triggers the `pathsToLink` assertion above. The file has a comment
  explaining `useGlobalPkgs = false` is intentional for Darwin compat - don't
  flip it without verifying.
- `stylix-nixos.nix` / `qt.nix` - own dialog *rendering* (theme/dark-mode),
  orthogonal to whether the portal loads at all - see
  [stylix-qt-kde-gtk-theming.md](stylix-qt-kde-gtk-theming.md).
- Per-WM main modules (`mango-main.nix`, `hyprland-main.nix`, `niri-main.nix`)
  - set `XDG_CURRENT_DESKTOP` for their own session only. Never put
  `XDG_CURRENT_DESKTOP` / `XDG_SESSION_DESKTOP` / `XDG_SESSION_TYPE` in
  `home.sessionVariables`: `hm-session-vars` is sourced by every session's login
  shell and overwrites the value SDDM set from the session file (this once made
  COSMIC and GNOME report `mango`). Don't append extra desktop names here as a
  portal workaround - fix `UseIn=` instead.
- `helium.nix` (and other Chromium-based browser modules) - most visible
  symptom carrier. Don't add browser-specific flags as a fix; the issue is
  system-wide.

## Diagnosis recipe

1. **Confirm it's the portal** - run the failing app from a terminal;
   look for `org.freedesktop.DBus.Error.InvalidArgs: No such interface
   "org.freedesktop.portal.FileChooser"`. Confirm with:
   ```fish
   busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep FileChooser
   ```
   Empty → no backend loaded at all.

2. **Find the scanned directory:**
   ```fish
   PID=$(pgrep -f "xdg-desktop-portal\$" | head -1)
   cat /proc/$PID/environ | tr '\0' '\n' | grep NIX_XDG_DESKTOP_PORTAL_DIR
   ```

3. **Verify patched manifests are actually there:**
   ```fish
   grep '^UseIn=' /run/current-system/sw/share/xdg-desktop-portal/portals/*.portal
   grep '^UseIn=' /etc/profiles/per-user/*/share/xdg-desktop-portal/portals/*.portal
   ```
   Both `gtk.portal` and `kde.portal` need the permissive `UseIn=` list in
   whichever directory step 2 named.

4. **Run the portal manually with debug output:**
   ```fish
   systemctl --user stop xdg-desktop-portal
   G_MESSAGES_DEBUG=all XDP_DEBUG=1 \
     $(systemctl --user cat xdg-desktop-portal | grep ExecStart | cut -d= -f2-) --replace > /tmp/xdp.log 2>&1 &
   sleep 3
   pkill -f "xdg-desktop-portal --replace"
   grep -E "load portals from|loading|unrecognized|providing portal" /tmp/xdp.log
   ```
   Look for `loading .../gtk.portal`/`kde.portal` and
   `providing portal org.freedesktop.portal.FileChooser`.

5. **Restart cleanly once fixed:**
   ```fish
   systemctl --user restart xdg-desktop-portal
   busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep FileChooser
   ```
   A reboot may be needed if both NixOS and HM env vars need to re-export
   through PAM.

## Dead ends to skip

1. Adding flags to the failing app (`--ozone-platform=auto`, etc.) - the bug
   is system-wide; flags don't help (`--ozone-platform=auto` is also invalid
   and breaks startup - only valid for `--ozone-platform-hint`).
2. Editing `XDG_CURRENT_DESKTOP` per-WM (e.g. `mango:KDE`) - works for one
   WM, doesn't generalize, drags in unrelated DE behaviors.
3. Adding a portal package without patching its `UseIn=` - installed but
   still rejected.
4. Patching only at NixOS level - the running portal may scan the per-user
   profile instead (home-manager wins the env var).
5. Inline `overrideAttrs` at NixOS level instead of the overlay - causes a
   `user-units` symlink collision.

## When to update this doc

New WM added and not in `permissiveDesktops`; xdg-desktop-portal or
home-manager version bumps that change `UseIn=`/env-var semantics;
`useGlobalPkgs`/`useUserPackages` flipped; a new portal-using app fails the
`busctl` check after a refactor.

## `portalConfig` keys must be lowercase

xdg-desktop-portal (>= 1.18) lowercases each `XDG_CURRENT_DESKTOP` entry before
looking up `<desktop>-portals.conf`, on a case-sensitive filesystem. Keys such
as `Hyprland`, `KDE`, `GNOME` therefore never match; the `common`/`portals.conf`
file silently won instead. Keep the keys in `xdg-portal.nix` lowercase
(`hyprland`, `kde`, `gnome`, `cosmic`, `niri`, `mango`). `UseIn=` matching is
case-insensitive, so `permissiveDesktops` is unaffected.

Note: the running portal only loads backends from `NIX_XDG_DESKTOP_PORTAL_DIR`
(the per-user profile: gtk, kde, hyprland), so `gnome`/`cosmic` backends are not
loadable regardless of the config keys. Open follow-up, not fixed here.
