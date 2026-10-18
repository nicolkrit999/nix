# test-portal-routing

Checks which backend xdg-desktop-portal (xdp 1.22) really selects per interface, in every session
desktop of every portal case the real hosts use (base system and every specialisation). Routing is
tested by behaviour (the real xdp binary), not by `UseIn=` strings: on xdp 1.22 `UseIn` only feeds a
deprecated fallback and no longer gates loading.

## Run

From the repo root:

```bash
bash templates/tests/run-tests.sh --only nixos-portal-routing
```

From this folder:

```bash
bash check-nixos-portal-routing.sh
```

Needs network access to cache.nixos.org. No profile is built, no VM, no session switch. About 3 min
local warm (`NIX_CONFIG='max-jobs = 0'`, 2026-10-18); `test.conf`: group `heavy-a`, timeout 15. On an
empty store the test fetches ~450 MiB from cache.nixos.org (xdp, dbus and the closures of the trivial
builds) and builds 13 trivial derivations (stand-ins, manifests, NixOS helper scripts).

## Design: slim fake hosts, nothing heavy is ever built

Until 2026-10-18 the test built `system.path` and `home.path` of every real host/specialisation.
Against cache.nixos.org alone that was ~1600 derivations per profile (Rust apps, doom-emacs, the
stylix-themed school `inkscape` + `gtksourceview4`, opencloud, openlogi, noctalia, gnome-shell with
the stylix theme), held up only by the evicting krit-nixos cachix; every eviction meant a source
build and a 30/45 min timeout (runs 38135221346, 38275067935, 39159226790). Now:

- **Real hosts are only evaluated** (`01-scenario-portal-routing.nix`): per base/specialisation the
  portal case (`desktops` among hyprland/niri/mango/kde/gnome/cosmic/xfce/icewm, `hmPortal`), the
  system and HM `xdg.portal.config`, the names of `xdg.portal.extraPortals ++ configPackages` (system
  and HM), the session names (`providedSessions`), the xdp store path and the profile entries.
- **One slim fake host per distinct case** (`02-fake-case.nix`, `fake-host/`): only
  `xdg-portal.nix`, the six desktop toggles and the HM integration; stylix off, no user programs, no
  specialisations, no documentation. `fake-host/nixos-extra.nix` mirrors what real hosts get from
  modules it does not load (XFCE/IceWM from the guest/safemode specialisations, HM Hyprland, the
  gnome-keyring service). Today the 13 real base/specs collapse into 6 cases.
- **Drift check:** for every real spec the fake case must reproduce `xdg.portal.config` (system and
  HM), the portal package names, the session names and the xdp store path; otherwise the case's
  routing says nothing about the real host and the test fails.
- **Portal data without building** (`portal_share.py`): for each fake-host profile entry the helper
  checks cache.nixos.org. Cached entries are read from the NAR listing (`nix store ls`) and single
  file reads (`nix store cat`) of `share/xdg-desktop-portal`, `share/wayland-sessions` and
  `share/xsessions`; nothing else of them is downloaded. The trees are merged like `buildEnv`
  (lower `meta.priority` wins, then first in `paths`).
- **Stand-ins** (`portal-common.nix`) replace repo-built entries that would need a compile:
  `xdg-desktop-portal-wlr` (the repo overlay only appends a `UseIn` sed to `postFixup`: the eval
  asserts the package equals stock nixpkgs with the stock `postFixup` and that the extra part only
  touches `$out/share/xdg-desktop-portal`; the stand-in copies the cached stock portal data and runs
  that extra part) and `mango` (flake input: the eval asserts `meson.build` still `install_data`s
  `assets/mango.desktop` and `assets/mango-portals.conf` to those dirs and no install hook touches
  `share/`; the stand-in installs the two files from `src`).
- **Every other uncached entry must be trivial** (no `src`/`srcs`, no fixed-output hash, or
  `preferLocalBuild`) and is built; a non-trivial one fails the case with "add a stand-in".
- **Regression guard:** before building, the case's build set (stand-ins, trivial entries, xdp,
  dbus) is dry-run against an empty chroot store that only sees cache.nixos.org; any derivation
  that would be built and is not trivial fails the guard (`will-build-heavy`). This holds regardless
  of what krit-nixos cachix or the CI store snapshot still has.
- **Real portal files covered:** every `share/xdg-desktop-portal` file that a real spec's
  cache.nixos.org-served entries ship must exist in its fake case. Real entries that are not on
  cache.nixos.org cannot be read without a build; the names not modelled by the fake case are
  printed (dim) as "not inspected".

## How the simulation works

- `portal_routing.py write-config` renders the config like the NixOS module (`<desktop>-portals.conf`, `portals.conf`).
- `portal_routing.py desktops` reads `DesktopNames=` from the assembled session files, giving the `XDG_CURRENT_DESKTOP` values.
- `portal-xdp-sim.sh` runs the real `xdg-desktop-portal` on a private D-Bus with no service dirs (no backend starts) with `XDG_DATA_DIRS=<hm>/share:<system>/share`, and prints its choice per interface.
- `portal_routing.py verdict` evaluates the output per desktop.

## Checks

| Check | Expected |
|---|---|
| evaluate (real hosts, fake cases) | everything evaluates; stand-in assertions hold |
| HM config equals system config | `home-manager.users.krit.xdg.portal.config == xdg.portal.config` per real spec |
| fake reproduces real | config, portal package names, session names, xdp path equal per real spec |
| uncached entries | stand-in or trivial |
| guard | empty-store dry run against cache.nixos.org builds nothing non-trivial |
| real portal files present | cached real entries' portal files all exist in the fake case |
| zero deprecated UseIn fallbacks | no `Choosing ... via the deprecated UseIn key` line in any desktop |
| FileChooser | resolved to the expected installed backend (kde in KDE, gnome in GNOME, cosmic in COSMIC, gtk elsewhere) |
| Screenshot / ScreenCast | hyprland, kde, gnome, cosmic, gnome (niri), wlr (mango) |
| Secret | gnome-keyring in every desktop |
| no foreign backend | no backend of another desktop selected (kde outside KDE, hyprland/wlr/gnome/cosmic outside their desktop, kwallet never, plasmanotify only in KDE) |

## Negative controls (per case)

| Control | Expected |
|---|---|
| empty config, packaged `*-portals.conf` removed, a desktop named in some `.portal`'s `UseIn` (XFCE if present) | deprecated-UseIn lines appear, proving the harness can see the fallback |
| config variant with kde prepended to every default and all `none` routes dropped (first non-KDE desktop) | verdict reports a backend of another desktop |

## Known limits

- Real-host entries that cache.nixos.org does not serve (repo-built apps, the stylix-themed
  gnome-shell/gnome-session) are not read; they are listed as "not inspected". The drift check
  still pins their portal package names, and the fake case reads the stock version of the same
  package.
- The merge emulates `buildEnv`'s priority/first-wins rule but ignores `propagated-user-env-packages`
  and non-default `outputsToInstall`; a portal file reachable only that way would be missed.
