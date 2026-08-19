# test-nixos-wallpapers

Unit tests for the wallpaper dispatch logic: awww (static), mpvpaper (gif/video), waypaper, and shell-owned. Covers x86_64 and aarch64, the `linux-wallpaperengine` arch guard, the video>gif>static priority chain, wildcard vs named monitor targeting, and the DE (GNOME/KDE) always-static invariant.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) - each `_test.nix` evaluates a fake host and asserts on the resulting config without building anything.

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

Each scenario's `host.nix` (built via `shared/mk-fake-host.nix`) enables all three WMs (hyprland, mango, niri), GNOME, and KDE in a single fake host. The host's `myconfig.constants.wallpapers` entry is set to a static-only, static+gif, static+video, or static+gif+video combination depending on the scenario.

`shared/eval-scenario.nix` loads the host with a minimal nixos-extra stub (platform, home-base, stylix-hm) and exposes helpers to extract the evaluated exec lists (`getHyprExecLua`, `getMangoExecStr`, `getNiriSpawnStr`) and home package names (`hmHasPkg`) for assertion.

The `_test.nix` files assert substring presence/absence in the WM exec strings and package list membership. Since `fetchurl`'s store path suffix is derived from the URL's basename (not the sha256), gif/video/static entries are told apart by their file extension in the exec string (e.g. `may_chill.gif` vs `loop.mp4` vs `chainsaw_makima.png`), not by the sha256 fragment.

### Key invariants under test

| Condition | WM exec result |
|-----------|---------------|
| Shell active on this WM | neither `awww-daemon`/`mpvpaper` nor `waypaper --restore` |
| `waypaper.enable = false`, no shell, only `wallpaperURL` set | `awww-daemon` + `awww img <path>` |
| `waypaper.enable = false`, no shell, `gifURL` or `videoURL` set | `mpvpaper -f -o loop <output> <path>` (not `awww img`) |
| `waypaper.enable = true`, no shell | `waypaper --restore` (wins over static/gif/video regardless of which are set) |
| `videoURL` set | video wins over gif and static - mpvpaper uses `videoURL` |
| `gifURL` set (no `videoURL`) | gif wins over static - mpvpaper uses `gifURL` |
| gifURL/videoURL set (GNOME/KDE) | static `wallpaperURL` store path (DEs never see gifURL/videoURL) |
| `targetMonitor = "*"` | awww gets no `-o` flag; mpvpaper gets `-o loop ALL` |
| `targetMonitor = "DP-1"` | awww gets `-o DP-1`; mpvpaper gets `-o loop DP-1` |
| x86_64 + waypaper enabled | `linux-wallpaperengine` in home packages |
| aarch64 + waypaper enabled | `linux-wallpaperengine` NOT in home packages |

## Checks

### W01 - x86_64, static-only, no waypaper

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

### W02 - x86_64, gif+static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `mpvpaper -f -o loop ALL` (gif via mpvpaper, wildcard monitor) | true |
| hyprland exec contains gif filename (gif wins over static) | true |
| hyprland exec contains `awww img` | false |
| hyprland exec contains `waypaper --restore` | false |
| mango/niri: same mpvpaper + no `awww img` / no `waypaper --restore` | true/false as above |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W03 - x86_64, static, waypaper enabled

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

### W04 - aarch64, static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `awww-daemon` | true |
| niri spawn contains `awww-daemon` | true |
| `waypaper` in home packages | false |

### W05 - aarch64, gif+static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `mpvpaper -f -o loop ALL` (gif via mpvpaper) | true |
| hyprland exec contains gif filename | true |
| hyprland exec contains `waypaper --restore` | false |
| mango/niri exec contain `mpvpaper -f -o loop ALL` | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W06 - aarch64, static, waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `waypaper --restore` | true |
| hyprland exec contains `awww-daemon` | false |
| mango exec contains `waypaper --restore` | true |
| niri spawn contains `waypaper --restore` | true |
| `waypaper` in home packages | true |
| `linux-wallpaperengine` in home packages | false |

### W07 - noctalia on hyprland, waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `waypaper --restore` | false |
| mango exec contains `waypaper --restore` | true |
| mango exec contains `awww-daemon` | false |
| niri spawn contains `waypaper --restore` | true |
| niri spawn contains `awww-daemon` | false |
| `waypaper` in home packages | true |

### W08 - caelestia on hyprland + noctalia on mango+niri, waypaper enabled

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

### W09 - named monitor (`DP-1`), static-only, no waypaper

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `awww-daemon` | true |
| hyprland/mango/niri exec contain `-o DP-1` (named monitor, awww syntax) | true |
| hyprland/mango/niri exec contain `awww img` | true |
| hyprland/mango/niri exec contain `waypaper --restore` | false |

### W10 - gifURL set + waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `waypaper --restore` (waypaper wins over gif branch) | true |
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains gif filename | false |
| mango/niri exec contain `waypaper --restore` | true |
| mango exec contains `awww-daemon` | false |
| `waypaper` in home packages | true |

### W11 - noctalia enabled but dormant on every WM (all `enableOnXxx = false`)

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `awww-daemon` | true |
| hyprland/mango/niri exec contain `awww img` | true |
| hyprland/mango/niri exec contain `waypaper --restore` | false |

### W12 - x86_64, video+static, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `mpvpaper -f -o loop ALL` (video wins over static, wildcard monitor) | true |
| hyprland exec contains video filename | true |
| hyprland exec contains `awww img` | false |
| hyprland exec contains `waypaper --restore` | false |
| mango/niri exec contain `mpvpaper -f -o loop ALL`, not `awww img` | true |
| GNOME background URI has `file:///nix/store/` prefix (static, DEs never see videoURL) | true |
| KDE plasma wallpaper list non-empty | true |

### W13 - x86_64, video+gif+static all set, no waypaper

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `mpvpaper -f -o loop ALL` (video wins over gif and static) | true |
| hyprland exec contains video filename | true |
| hyprland exec contains gif filename (video beats gif) | false |
| hyprland exec contains `awww img` | false |
| mango/niri exec contain gif filename | false |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W14 - videoURL set + waypaper enabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `waypaper --restore` (waypaper wins over video branch) | true |
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `mpvpaper` | false |
| hyprland exec contains video filename | false |
| mango/niri exec contain `waypaper --restore`, not `mpvpaper` | true/false as above |
| `waypaper` in home packages | true |

### W15 - named monitor (`DP-1`), video-only, no waypaper

| Check | Expected |
|-------|----------|
| hyprland exec contains `mpvpaper -f -o loop DP-1` (named monitor, mpvpaper syntax) | true |
| hyprland exec contains `mpvpaper -f -o loop ALL` | false |
| hyprland exec contains `awww img` | false |
| hyprland exec contains `waypaper --restore` | false |
| mango/niri exec contain `mpvpaper -f -o loop DP-1`, not `awww img` | true/false as above |
