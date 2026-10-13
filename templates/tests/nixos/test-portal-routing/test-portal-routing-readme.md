# test-portal-routing

Checks which backend xdg-desktop-portal (xdp 1.22) really selects per interface, for both real
hosts, the base system and every specialisation, in every session desktop. Routing is tested by
behaviour (the real xdp binary), not by `UseIn=` strings: on xdp 1.22 `UseIn` only feeds a deprecated
fallback and no longer gates loading.

## Run

From the repo root:

```bash
bash templates/tests/run-tests.sh --only nixos-portal-routing
```

From this folder:

```bash
bash check-nixos-portal-routing.sh
```

Builds `system-path` and the home-manager `home-path` per host/specialisation (mostly cached); no VM,
no session switch. The `home-path` is built without its bin-only script wrappers (see `03-homepath.nix`) and the `system-path` without the heavy portal-less packages listed in `04-systempath.nix` (openlogi, a ~25 min Rust build). Cold about 12 min, warm about 6 min (`test.conf`: group `heavy-c`, timeout 30; CI run 38099944203 measured 14m34s).

## How it works

- `01-scenario-portal-routing.nix` evaluates `xdg.portal.config` (system and HM) and whether HM portals are enabled, per specialisation.
- `02-sessions.nix` joins `services.displayManager.sessionPackages`; `portal_routing.py desktops` reads `DesktopNames=` from the session files, giving the `XDG_CURRENT_DESKTOP` values.
- `portal_routing.py write-config` renders the config like the NixOS module (`<desktop>-portals.conf`, `portals.conf`).
- `03-homepath.nix` builds `home-manager.users.krit.home.path` with every `writeShellScriptBin`/`writeTextFile` entry whose `destination` is under `/bin/` filtered out (they can only ship `bin/`, never `share/xdg-desktop-portal`). This drops `universal-lock` and with it the noctalia source build (about 18 min on CI's narrow caches, a 404 once krit-nixos evicts it; runs 38135221346 and 38136950163). It asserts `home.path` is still an overridable buildEnv and that something was dropped, so it fails loudly instead of silently building the full path.
- `04-systempath.nix` builds `system.path` via `sp.override { paths = kept; }` where `kept` drops the named heavy packages (matched by `lib.getName`; start: `openlogi`). openlogi's package (`packaging/linux/package.nix` in the flake input) installs only `bin/`, `share/applications`, icons, udev, systemd user unit and licenses: nothing under `share/xdg-desktop-portal`, and the simulation reads only `share/xdg-desktop-portal` (session desktops come from `02-sessions.nix`). Each list entry carries its enable predicate; the eval asserts that an enabled entry was really found in `system.path` (no stale name) and that nothing is dropped where disabled. CI runs 38275067935 and 38275067783 hit the timeout on the openlogi build. A package may only be added if it cannot ship `share/xdg-desktop-portal`.
- `portal-xdp-sim.sh` runs the real `xdg-desktop-portal` on a private D-Bus with no service dirs (no backend starts) with `XDG_DATA_DIRS=<hm>/share:<system>/share`, and prints its choice per interface.
- `portal_routing.py verdict` evaluates the output per desktop.

## Checks

| Check | Expected |
|---|---|
| evaluate | `xdg.portal.config` evaluates for base and all specialisations |
| HM config equals system config | `home-manager.users.krit.xdg.portal.config == xdg.portal.config` per specialisation |
| zero deprecated UseIn fallbacks | no `Choosing ... via the deprecated UseIn key` line in any desktop |
| FileChooser | resolved to the expected installed backend (kde in KDE, gnome in GNOME, cosmic in COSMIC, gtk elsewhere) |
| Screenshot / ScreenCast | hyprland, kde, gnome, cosmic, gnome (niri), wlr (mango) |
| Secret | gnome-keyring in every desktop |
| no foreign backend | no backend of another desktop selected (kde outside KDE, hyprland/wlr/gnome/cosmic outside their desktop, kwallet never, plasmanotify only in KDE) |

## Negative controls

| Control | Expected |
|---|---|
| empty config on XFCE (base) | deprecated-UseIn lines appear, proving the harness can see the fallback |
| config variant with kde prepended to every default and all `none` routes dropped (first non-KDE desktop of base) | verdict reports a backend of another desktop |
