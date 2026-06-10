# test-nixos-wallpapers

Unit tests for the three-way wallpaper dispatch logic: awww (static/gif), waypaper, and shell-owned. Covers x86_64 and aarch64, the `linux-wallpaperengine` arch guard, and the DE (GNOME/KDE) always-static invariant.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix` evaluates a fake host and asserts on the resulting config without building anything.

## Run

From repo root:

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/test-nixos-wallpapers
```

From inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## How it works

Each scenario is a `host.nix` (built via `shared/mk-fake-host.nix`) that enables all three WMs (hyprland, mango, niri), GNOME, and KDE in a single fake host. The host's `myconfig.constants.wallpapers` is set to a static-only or static+gif entry depending on the scenario.

`shared/eval-scenario.nix` loads the host with a minimal nixos-extra stub (platform, home-base, stylix-hm) and exposes helpers that extract the evaluated exec lists (`getHyprExecLua`, `getMangoExecStr`, `getNiriSpawnStr`) and home package names (`hmHasPkg`) for assertion.

The `_test.nix` files assert substring presence/absence in WM exec strings and package list membership.

### Key invariants under test

| Condition | WM exec result |
|-----------|---------------|
| Shell active on this WM | neither `awww-daemon` nor `waypaper --restore` |
| `waypaper.enable = false`, no shell | `awww-daemon` + `awww img <path>` |
| `waypaper.enable = true`, no shell | `waypaper --restore` |
| gifURL set (WMs) | `awww img <gif-store-path>` (not static) |
| gifURL set (GNOME/KDE) | static `wallpaperURL` store path (DEs never see gifURL) |
| x86_64 + waypaper enabled | `linux-wallpaperengine` in home packages |
| aarch64 + waypaper enabled | `linux-wallpaperengine` NOT in home packages |

## Checks

### W01 — x86_64, static-only, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `awww img` | true |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `awww-daemon` | true |
| mango exec contains `waypaper --restore` | false |
| niri spawn contains `awww-daemon` | true |
| niri spawn contains `waypaper --restore` | false |
| `linux-wallpaperengine` in home packages | false |
| `waypaper` in home packages | false |

### W02 — x86_64, gif+static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `awww img` | true |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `awww-daemon` | true |
| niri spawn contains `awww-daemon` | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W03 — x86_64, static, waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `waypaper --restore` | true |
| hyprland exec contains `awww-daemon` | false |
| mango exec contains `waypaper --restore` | true |
| niri spawn contains `waypaper --restore` | true |
| `linux-wallpaperengine` in home packages | true |
| `waypaper` in home packages | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W04 — aarch64, static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `awww-daemon` | true |
| niri spawn contains `awww-daemon` | true |
| `waypaper` in home packages | false |

### W05 — aarch64, gif+static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `awww img` | true |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `awww-daemon` | true |
| niri spawn contains `awww-daemon` | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W06 — aarch64, static, waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `waypaper --restore` | true |
| hyprland exec contains `awww-daemon` | false |
| mango exec contains `waypaper --restore` | true |
| niri spawn contains `waypaper --restore` | true |
| `waypaper` in home packages | true |
| `linux-wallpaperengine` in home packages | false |

### W07 — noctalia on hyprland, waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `waypaper --restore` | true |
| mango exec contains `awww-daemon` | false |
| niri spawn contains `waypaper --restore` | true |
| niri spawn contains `awww-daemon` | false |
| `waypaper` in home packages | true |

### W08 — caelestia on hyprland + noctalia on mango+niri, waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `awww-daemon` | false |
| mango exec contains `waypaper --restore` | false |
| niri spawn contains `awww-daemon` | false |
| niri spawn contains `waypaper --restore` | false |
| `waypaper` in home packages | true |
| `linux-wallpaperengine` in home packages | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |
