# test-nixos-wallpapers

Unit tests for the wallpaper dispatch logic: the shared per-WM `<wm>-wallpaperd` supervisor (awww for stills, mpvpaper for gif/video), skwdWall, and shell-owned. Covers x86_64 and aarch64, the `skwd-paper-plasma` arch guard, the video>gif>static priority chain, wildcard vs named monitor targeting, and the DE (GNOME/KDE) always-static invariant.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) - each `_test.nix` evaluates a fake host and asserts on the resulting config without building anything.

## Run

Via the suite runner (from the repo root; runs the nix-tests files and then the `asserts/` bash companion as one test with one log): `bash templates/tests/run-tests.sh --only nixos-wallpapers` (name as shown by `--list`).

The nix-tests part directly, from the repo root (the harness is pinned to one commit and forced onto this repo's nixpkgs; the exact command lives in `templates/tests/lib/discover.py`, `NIX_TESTS`):

```bash
nix run github:danielefongo/nix-tests/866429d23a6ebf6e03837434f18e4cace9c37bc5 --inputs-from . --override-input nixpkgs nixpkgs -- templates/tests/nixos/test-nixos-wallpapers
```

The bash companion is run separately, see [asserts/](#asserts---mk-wallpaperd-asserts-real-host-wallpapers-empty-list-bash-companion).

## How it works

Each scenario's `host.nix` (built via `shared/mk-fake-host.nix`) enables all three WMs (hyprland, mango, niri), GNOME, and KDE in a single fake host. The host's `myconfig.constants.wallpapers` entry is set to a static-only, static+gif, static+video, or static+gif+video combination depending on the scenario.

`shared/eval-scenario.nix` loads the host with a minimal nixos-extra stub (platform, home-base, stylix-hm) and exposes helpers to extract the evaluated exec lists (`getHyprExecLua`, `getMangoExecStr`, `getNiriSpawnStr`), home package names (`hmHasPkg`), the `services.skwd-deck.enable` flag (`skwdDeckEnabled`), and KDE's `wallpaperCustomPlugin.plugin` (`kdeWallpaperCustomPlugin`) for assertion.

The `_test.nix` files assert substring presence/absence in the WM exec strings and package list membership. Since `fetchurl`'s store path suffix is derived from the URL's basename (not the sha256), gif/video/static entries are told apart by their file extension in the exec string (e.g. `may_chill.gif` vs `loop.mp4` vs `chainsaw_makima.png`), not by the sha256 fragment.

All three WMs (hyprland, mango, niri) use the same shared supervisor (`de-wm/wallpaperd/`, built by `mk-wallpaperd.nix`), package name `<wm>-wallpaperd`. Wallpapers are handed to it as `OUT=KIND:PATH` specs (`KIND` = `image` or `video`; `OUT` = connector name, `desc:...` or `*` = fallback for outputs without their own entry). `awww img` / `mpvpaper ... ALL` therefore never appear in any WM startup string. `awww-daemon --no-cache` is a separate startup entry emitted only when at least one entry is a still image, and not at all for `wallpapers = [ ]`.

`shared/eval-scenario.nix` provides `perWm` plus the `expect` constructors (`supervisor`, `daemon`, `noDaemon`, `spec`, `noSpec`, `noDirectAwww`, `noDirectMpv`, `noSupervisor`): one expectation expands into one check per WM (`hyprland: ...`, `mango: ...`, `niri: ...`), so the three WMs are always asserted identically. `wmCount` counts substring occurrences in one WM's startup string.

### Mango reads its specs from the launcher script

mango 0.18 silently cuts config values at 255 chars (commit `4eaaab89`), so `mk-wallpaperd.nix` writes a `mango-wallpaperd-start` launcher script that holds the `OUT=KIND:PATH` specs, and mango's `exec_once` only carries that script's store path (hyprland and niri keep the specs inline). `getMangoExecStr` therefore rebuilds the launcher through `mk-wallpaperd.nix` from `config.myconfig.constants.wallpapers` and `flake.inputs.nixpkgs.legacyPackages.<system>` (`mangoLauncher`), and splices the launcher text into the string only when an `exec_once` entry equals the launcher store path. The store path hashes the script text, so a match proves the wired launcher contains exactly those specs; a mismatch or missing launcher leaves the specs out and the positive `spec` checks fail instead of passing vacuously. Scenarios that expect a supervisor also get `mango: wallpaperd launcher store path is an exec_once entry`, so a wiring break gives one clear failure. Caveat: a future overlay touching bash/jq/awww/mpvpaper in a scenario would change the rebuilt path and fail the mango checks loudly.

### Key invariants under test

| Condition | Result (every WM) |
|-----------|-------------------|
| Shell active on this WM | no `<wm>-wallpaperd`, no `awww-daemon` (skwdWall gates the same way) |
| `skwdWall.enable = true` | no supervisor, no `awww-daemon`, no `mpvpaper`, regardless of media fields or active shell |
| `skwdWall.enable = false`, no shell, only `wallpaperURL` | `awww-daemon --no-cache` + `<wm>-wallpaperd` with `OUT=image:` |
| `gifURL` or `videoURL` set | `OUT=video:` spec, no `awww-daemon`, no direct `awww img`/`mpvpaper` call |
| `videoURL` set | video wins over gif and static |
| `gifURL` set (no `videoURL`) | gif wins over static |
| gifURL/videoURL set (GNOME/KDE) | static `wallpaperURL` store path (DEs never see gifURL/videoURL) |
| `targetMonitor = "*"` | one `*=KIND:` fallback spec |
| `targetMonitor = "DP-1"` | `DP-1=KIND:` spec, no `*=` entry |
| declared monitor + `*` entry | two separate specs; `*` is a runtime fallback, never stacked under declared outputs; exactly one `*=` |
| still and video mixed (either order) | `awww-daemon` starts; each entry keeps its own kind |
| `skwdWall.enable = true` (KDE) | `wallpaperCustomPlugin.plugin = "org.skwd.wall.plasma"`, `workspace.wallpaper` unset (null), `skwd-paper-plasma` in home packages (x86_64 only) |
| `skwdWall.enable = true` | `services.skwd-deck.enable = true` at the system level |
| GNOME | always uses the static `wallpaperURL`, unconditionally |

Coverage matrix per WM (identical for hyprland, mango, niri): declared-only still (W09) and video (W15), two declared outputs (W18), fallback-only still (W01/W04/W11) and video (W02/W05/W12/W13), mixed still-declared + video-fallback (W16) and video-declared + still-fallback (W17).

## Checks

### W01 - x86_64, static-only on `*`, skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache` | true |
| per WM: spec `*=image:`, no `=video:`, no direct `awww img`/`mpvpaper` | true/false/false/false |
| KDE plasma wallpaper list non-empty; `wallpaperCustomPlugin` unset | true |
| GNOME background URI has `file:///nix/store/` prefix | true |
| `services.skwd-deck.enable` | false |
| `skwd-paper-plasma` in home packages | false |

### W02 - x86_64, gif+static on `*`, skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, spec `*=video:` with the gif filename | true |
| per WM: no `awww-daemon`, no `=image:`, no direct `awww img`/`mpvpaper` | false |
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
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache`, spec `*=image:`, no direct `awww img` | true/true/true/false |
| `services.skwd-deck.enable` | false |

### W05 - aarch64, gif+static on `*`, skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, spec `*=video:` with gif filename | true |
| per WM: no `awww-daemon`, no direct `awww img`/`mpvpaper` | false |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W06 - aarch64, static, skwdWall ENABLED

| Check | Expected |
|-------|----------|
| hyprland/mango/niri exec contain `awww-daemon` | false |
| `services.skwd-deck.enable` | true |
| `skwd-paper-plasma` in home packages (aarch64 has no skwd-wall package) | false |
| KDE `wallpaperCustomPlugin` | unset (`null`) |
| KDE plasma wallpaper list | non-empty (static fallback) |

> `kde-main.nix` guards the `skwd-paper-plasma` lookup with `pkgs.stdenv.hostPlatform.isx86_64` (`skwdWallPlasmaAvailable`), because the skwd-wall flake only publishes packages for `x86_64-linux`. On aarch64 the package is omitted and KDE falls back to the static wallpaper list. The last two rows above are the regression guard: dropping the arch guard turns this scenario into an `attribute 'aarch64-linux' missing` eval error.

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

### W09 - declared-only: named monitor (`DP-1`), static, skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache`, spec `DP-1=image:` | true |
| per WM: no `*=` fallback entry, no `=video:`, no direct `awww img` | false |

### W10 - gifURL set + skwdWall ENABLED

| Check | Expected |
|-------|----------|
| per WM: no `-wallpaperd` supervisor | true |
| per WM: no `awww-daemon` | true |
| per WM: no direct `mpvpaper` / `awww img` | true |
| per WM: spec has no `may_chill.gif` | true |
| `services.skwd-deck.enable` | true |

### W11 - noctalia enabled but dormant on every WM (all `enableOnXxx = false`)

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache`, spec `*=image:` | true |

### W12 - x86_64, video+static on `*`, skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, spec `*=video:` with the video filename | true |
| per WM: no `awww-daemon`, no `=image:`, no direct `awww img`/`mpvpaper` | false |
| GNOME background URI has `file:///nix/store/` prefix (static, DEs never see videoURL) | true |
| KDE plasma wallpaper list non-empty | true |

### W13 - x86_64, video+gif+static all set on `*`, skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, spec `*=video:` with the video filename | true |
| per WM: gif filename absent (video beats gif), no `awww-daemon`, no `=image:`, no direct `awww img` | false |
| GNOME background URI has `file:///nix/store/` prefix | true |
| KDE plasma wallpaper list non-empty | true |

### W14 - videoURL set + skwdWall ENABLED

| Check | Expected |
|-------|----------|
| per WM: no `-wallpaperd` supervisor, no `awww-daemon`, no `mpvpaper`, no video filename | false |
| `services.skwd-deck.enable` | true |

### W15 - declared-only video: named monitor (`DP-1`), skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, spec `DP-1=video:` | true |
| per WM: no `awww-daemon`, no `*=` fallback entry, no `=image:`, no direct `mpvpaper` | false |

### W16 - declared `DP-1` (image) + `*` fallback (video), skwdWall disabled

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache` | true |
| per WM: specs `DP-1=image:` and `*=video:` | true |
| per WM: no `DP-1=video:`, no `*=image:`, no direct `awww img`/`mpvpaper` | false |
| each WM has exactly one `*=` entry | true |

### W17 - declared `DP-1` (video) + `*` fallback (image), skwdWall disabled

Inverse of W16 (`shared/base-constants-mixed-inverse.nix`).

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache` (fallback is a still) | true |
| per WM: specs `DP-1=video:` and `*=image:` | true |
| per WM: no `DP-1=image:`, no `*=video:`, no direct `awww img`/`mpvpaper` | false |
| each WM has exactly one `*=` entry | true |

### W18 - two declared outputs, no fallback, skwdWall disabled

`shared/base-constants-two-declared.nix`: `DP-1` still, `HDMI-A-1` video.

| Check | Expected |
|-------|----------|
| per WM: runs `<wm>-wallpaperd`, starts `awww-daemon --no-cache`, specs `DP-1=image:` and `HDMI-A-1=video:` | true |
| per WM: no `*=` entry, no direct `awww img`/`mpvpaper` | false |

### Shared hardening (all scenarios)

- `perWm` adds `<wm>: startup is non-empty (negative checks are not vacuous)` whenever an expectation is a negative, so a broken/empty WM exec cannot make `noSpec`/`noDaemon`/`noSupervisor` pass vacuously.
- W03, W06, W07, W08 also run `noSupervisor` per WM (previously only `awww-daemon` absence).
- GNOME background checks use `H.isStillUri`: a `/nix/store/` URI ending in the still's basename, so a gif/video store path no longer passes.

## asserts/ - mk-wallpaperd asserts, real-host wallpapers, empty list (bash companion)

`asserts/check-nixos-wallpapers-asserts.sh` is a bash companion (nix-tests cannot read error messages). It runs `nix eval --raw --impure` per check against `asserts/01-scenario-wallpapers-asserts.nix` (about 1 minute), prints a PASS/FAIL line per check and exits non-zero on any failure.

Run from repo root:

```bash
bash templates/tests/nixos/test-nixos-wallpapers/asserts/check-nixos-wallpapers-asserts.sh
```

From inside the directory: `bash asserts/check-nixos-wallpapers-asserts.sh`.

Negative checks grep stderr for the documented `assertMsg` text. Real-host checks read `nixosConfigurations.<host>.config.myconfig.constants.wallpapers` and compare it against values recomputed independently in the scenario (no hash or URL is hardcoded). Scenario dirs `19-empty-wm`, `20-empty-gnome`, `21-empty-kde` (base `shared/base-constants-empty.nix`) and `22-nostar-wm`, `23-nostar-gnome`, `24-nostar-kde`, `25-star-second` (bases `shared/base-constants-no-star.nix` / `base-constants-star-second.nix`) are used only by this script. These hosts are `minimal` (see `mk-fake-host.nix`): only what the check needs is enabled (`19`: the three WMs for hyprlock/startup; `20`/`23`: GNOME only; `21`/`24`: KDE only, plus `kde-kscreenlocker.nix` loaded through `getConfigWith`; `22`: hyprland only; `25`: nothing but the constants); no shell, waybar or swaync lines.

| Check | Expected |
|-------|----------|
| valid targets (`DP-1`, `desc:...`, `*`) | evaluate (control, proves the negatives bite) |
| duplicate `targetMonitor` | eval fails with `wallpapers: duplicate targetMonitor` |
| `targetMonitor = "$(hostname)"` / backticks | eval fails with `not a shell substitution` |
| synthetic still / video / gif / mixed / empty | `needsAwww` iff any still, `needsMpv` iff any video/gif |
| synthetic runtime inputs | `awww` / `mpvpaper` on the supervisor PATH iff `needsAwww` / `needsMpv` |
| per real host (nixos-desktop, nixos-laptop) | list non-empty; every URL has a 52-char nix32 sha256; targets unique; spec count == entry count |
| per real host | `needsAwww`/`needsMpv` match recomputation; mango PATH has `wlr-randr`; hyprland has `socat`; niri has neither; `WALLPAPERD_MPV_EXTRA=` exactly once in launcher; niri `startupArgv` is a list of string lists |
| per real host | hyprland and mango launcher text pass `bash -n` |
| fallback constant (`fallbackWallpaperURL`/`SHA256`) | set; sha256 is 52-char nix32 |
| `wallpapers = [ ]`, WMs only | no wallpaperd / awww in hyprland, mango, niri startup |
| `wallpapers = [ ]`, hyprlock | background uses the fetched fallback wallpaper constant |
| `wallpapers = [ ]`, GNOME | `gnome-main` dconf settings use the fallback wallpaper constant |
| `wallpapers = [ ]`, KDE | `kde-main` evaluates; `kde-kscreenlocker` appearance wallpaper is the fallback constant |
| `primaryWallpaper` (no `*` entry, 2 declared) | is the first entry (`22-nostar-wm`) |
| hyprlock / `gnome-main` / `kde-kscreenlocker` (no `*` entry) | use the first entry's store path, not the second's, not the fallback (`22`/`23`/`24`, base `shared/base-constants-no-star.nix`) |
| `stylix-nixos.nix` | reads `constants.primaryWallpaper`, has no `findFirst` of its own (source check: it cannot be loaded next to the stub) |
| `*` entry that is not first (`25-star-second`, `shared/base-constants-star-second.nix`) | `primaryWallpaper` is the `*` entry |

Not covered for `[ ]`: `stylix-nixos.nix` (same `findFirst` fallback pattern; cannot be loaded next to the stub that already declares the `stylix` module).
