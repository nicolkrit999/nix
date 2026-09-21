# test-nixos-wallpapers

Unit tests for the wallpaper dispatch logic: awww (static), mpvpaper (gif/video), skwdWall, and shell-owned. Covers x86_64 and aarch64, the `skwd-paper-plasma` arch guard, the video>gif>static priority chain, wildcard vs named monitor targeting, and the DE (GNOME/KDE) always-static invariant.

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

`shared/eval-scenario.nix` loads the host with a minimal nixos-extra stub (platform, home-base, stylix-hm) and exposes helpers to extract the evaluated exec lists (`getHyprExecLua`, `getMangoExecStr`, `getNiriSpawnStr`), home package names (`hmHasPkg`), the `services.skwd-deck.enable` flag (`skwdDeckEnabled`), and KDE's `wallpaperCustomPlugin.plugin` (`kdeWallpaperCustomPlugin`) for assertion.

The `_test.nix` files assert substring presence/absence in the WM exec strings and package list membership. Since `fetchurl`'s store path suffix is derived from the URL's basename (not the sha256), gif/video/static entries are told apart by their file extension in the exec string (e.g. `may_chill.gif` vs `loop.mp4` vs `chainsaw_makima.png`), not by the sha256 fragment.

### Key invariants under test

| Condition | WM exec result |
|-----------|---------------|
| Shell active on this WM | neither `awww-daemon`/`mpvpaper` (skwdWall gates the same way) |
| `skwdWall.enable = true` | neither `awww-daemon` nor `mpvpaper` in any WM exec, regardless of which media fields are set or whether a shell is also active - `skwdWallActive` short-circuits before the shell/animated/static branches are evaluated |
| `skwdWall.enable = false`, no shell, only `wallpaperURL` set | `awww-daemon` + `awww img <path>` |
| `skwdWall.enable = false`, no shell, `gifURL` or `videoURL` set | `mpvpaper -f -o "loop mute=yes panscan=1.0" <output> <path>` (not `awww img`) |
| `videoURL` set | video wins over gif and static - mpvpaper uses `videoURL` |
| `gifURL` set (no `videoURL`) | gif wins over static - mpvpaper uses `gifURL` |
| gifURL/videoURL set (GNOME/KDE) | static `wallpaperURL` store path (DEs never see gifURL/videoURL) |
| `targetMonitor = "*"` | awww gets no `-o` flag; mpvpaper gets `-o loop ALL` |
| `targetMonitor = "DP-1"` | awww gets `-o DP-1`; mpvpaper gets `-o loop DP-1` |
| `skwdWall.enable = true` (KDE) | `wallpaperCustomPlugin.plugin = "org.skwd.wall.plasma"`, `workspace.wallpaper` unset (null), `skwd-paper-plasma` in home packages (x86_64 only) |
| `skwdWall.enable = true` | `services.skwd-deck.enable = true` at the system level |
| GNOME | always uses the static `wallpaperURL`, unconditionally - not part of the `skwdWall` toggle at all |

## Checks

### W01 - x86_64, static-only, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `awww img` | true |
| mango exec contains `awww-daemon` | true |
| niri spawn contains `awww-daemon` | true |
| KDE plasma wallpaper list non-empty | true |
| KDE `wallpaperCustomPlugin` unset | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| `services.skwd-deck.enable` | false |
| `skwd-paper-plasma` in home packages | false |

### W02 - x86_64, gif+static, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL` (gif via mpvpaper, wildcard monitor) | true |
| hyprland exec contains gif filename (gif wins over static) | true |
| hyprland exec contains `awww img` | false |
| mango/niri: same mpvpaper + no `awww img` | true/false as above |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W03 - x86_64, static, skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `awww img` | false |
| mango exec contains `awww-daemon` | false |
| niri spawn contains `awww-daemon` | false |
| `services.skwd-deck.enable` | true |
| KDE `wallpaperCustomPlugin.plugin` | `"org.skwd.wall.plasma"` |
| KDE `workspace.wallpaper` | null |
| `skwd-paper-plasma` in home packages (x86_64) | true |
| GNOME background URI has `file:///nix/store/` prefix (unaffected) | true |

### W04 - aarch64, static, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| mango exec contains `awww-daemon` | true |
| niri spawn contains `awww-daemon` | true |
| `services.skwd-deck.enable` | false |

### W05 - aarch64, gif+static, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL` (gif via mpvpaper) | true |
| hyprland exec contains gif filename | true |
| mango/niri exec contain `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL` | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W06 - aarch64, static, skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `awww-daemon` | false |
| `services.skwd-deck.enable` | true |
| `skwd-paper-plasma` in home packages (aarch64 has no skwd-wall package) | false |

> **Known gap:** as of this writing, `kde-main.nix` accesses `inputs.skwd-wall.packages.${pkgs.system}.skwd-paper-plasma` unconditionally when `skwdWallActive` is true, with no arch guard beyond "not Darwin". The skwd-wall flake only publishes packages for `x86_64-linux`, so this scenario currently fails at eval with `attribute 'aarch64-linux' missing` rather than cleanly asserting "not installed". This is intentional - the check is left in place (not weakened) so the gap stays visible until a guard is added in `kde-main.nix`.

### W07 - noctalia on hyprland, skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| mango exec contains `awww-daemon` | false |
| niri spawn contains `awww-daemon` | false |
| `services.skwd-deck.enable` | true |

### W08 - caelestia on hyprland + noctalia on mango+niri, skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| mango exec contains `awww-daemon` | false |
| niri spawn contains `awww-daemon` | false |
| `services.skwd-deck.enable` | true |
| KDE `wallpaperCustomPlugin.plugin` | `"org.skwd.wall.plasma"` |
| `skwd-paper-plasma` in home packages | true |
| GNOME background URI has `file:///nix/store/` prefix (unaffected) | true |

### W09 - named monitor (`DP-1`), static-only, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `awww-daemon` | true |
| hyprland/mango/niri exec contain `-o DP-1` (named monitor, awww syntax) | true |
| hyprland/mango/niri exec contain `awww img` | true |

### W10 - gifURL set + skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `mpvpaper` | false |
| hyprland exec contains gif sha fragment | false |
| mango/niri exec contain `awww-daemon` | false |
| `services.skwd-deck.enable` | true |

### W11 - noctalia enabled but dormant on every WM (all `enableOnXxx = false`)

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `awww-daemon` | true |
| hyprland/mango/niri exec contain `awww img` | true |

### W12 - x86_64, video+static, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | true |
| hyprland exec contains `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL` (video wins over static, wildcard monitor) | true |
| hyprland exec contains video filename | true |
| hyprland exec contains `awww img` | false |
| mango/niri exec contain `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL`, not `awww img` | true |
| GNOME background URI has `file:///nix/store/` prefix (static, DEs never see videoURL) | true |
| KDE plasma wallpaper list non-empty | true |

### W13 - x86_64, video+gif+static all set, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL` (video wins over gif and static) | true |
| hyprland exec contains video filename | true |
| hyprland exec contains gif filename (video beats gif) | false |
| hyprland exec contains `awww img` | false |
| mango/niri exec contain gif filename | false |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W14 - videoURL set + skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland exec contains `awww-daemon` | false |
| hyprland exec contains `mpvpaper` | false |
| hyprland exec contains video filename | false |
| mango/niri exec contain `mpvpaper` | false |
| `services.skwd-deck.enable` | true |

### W15 - named monitor (`DP-1`), video-only, skwdWall disabled

| Check | Expected |
|-------|----------|
| hyprland exec contains `mpvpaper -f -o "loop mute=yes panscan=1.0" DP-1` (named monitor, mpvpaper syntax) | true |
| hyprland exec contains `mpvpaper -f -o "loop mute=yes panscan=1.0" ALL` | false |
| hyprland exec contains `awww img` | false |
| mango/niri exec contain `mpvpaper -f -o "loop mute=yes panscan=1.0" DP-1`, not `awww img` | true/false as above |
