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
no session switch. Cold about 12 min, warm about 6 min (`test.conf`: group `nixos-b`, timeout 20).

## How it works

- `01-scenario-portal-routing.nix` evaluates `xdg.portal.config` (system and HM) and whether HM portals are enabled, per specialisation.
- `02-sessions.nix` joins `services.displayManager.sessionPackages`; `portal_routing.py desktops` reads `DesktopNames=` from the session files, giving the `XDG_CURRENT_DESKTOP` values.
- `portal_routing.py write-config` renders the config like the NixOS module (`<desktop>-portals.conf`, `portals.conf`).
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
