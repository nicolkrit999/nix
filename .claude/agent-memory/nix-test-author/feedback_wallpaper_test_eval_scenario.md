---
name: wallpaper-test-eval-scenario
description: gnome/kde pkgs.fetchurl is safe in pure nix eval; how to include DE modules in wallpaper test eval-scenario; fetchurl store-path-suffix gotcha for asserting which media field was chosen; waypaper->skwdWall 2026-09-21 rename
metadata:
  type: feedback
---

**2026-09-21 update:** the old `programs.waypaper` toggle (module file `waypaper.nix`, "waypaper --restore" exec branch, `linux-wallpaperengine` package) was fully removed and replaced by `programs.skwdWall` (module file `skwd-wall.nix`, option `myconfig.programs.skwdWall.enable`). This is not a like-for-like rename: skwdWall enabled means the WMs (hyprland/niri/mango) emit **no** wallpaper exec at all (skwd-walld owns it at runtime via a systemd service, `services.skwd-deck.enable`), and KDE swaps `programs.plasma.workspace.wallpaper` for `wallpaperCustomPlugin = { plugin = "org.skwd.wall.plasma"; }` plus installs `inputs.skwd-wall.packages.${pkgs.system}.skwd-paper-plasma`. GNOME is not part of this toggle at all - always static, unconditionally. All 15 `test-nixos-wallpapers` scenario dirs/files were renamed from `*waypaper*` to `*skwdwall*` and `mk-fake-host.nix`'s spec field renamed `waypaper` → `skwdWall`. See `skwdDeckEnabled`/`kdeWallpaperCustomPlugin` helpers added to `eval-scenario.nix` for asserting the new behavior.

**Former real bug, FIXED (verified 2026-10-11):** `kde-main.nix` used to look up `inputs.skwd-wall.packages.${pkgs.system}.skwd-paper-plasma` with no arch guard, and the skwd-wall flake only publishes `x86_64-linux`, so aarch64 + KDE + skwdWall failed with `attribute 'aarch64-linux' missing`. Now `skwdWallPlasmaAvailable = skwdWallActive && pkgs.stdenv.hostPlatform.isx86_64` gates both the package and `wallpaperCustomPlugin`; on aarch64 KDE falls back to the static `wallpaper` list. Scenario `06-aarch64-skwdwall` is the regression guard (asserts the package is absent, `kdeWallpaperCustomPlugin == null`, wallpaper list non-empty). Never weaken it; if the arch guard is dropped, route to nix-debugger.

**Requested-but-not-added:** the task also asked for a fixture test covering a Wallpaper Engine ("we"-type) wallpaper entry with a Steam Workshop ID. As of 2026-10-11 (re-verified), `myconfig.constants.wallpapers` (in `modules/nixos/config/constants-nixos.nix`) has only targetMonitor/wallpaperURL+SHA256/gifURL+SHA256/videoURL+SHA256, no `type`/`we`/workshop-id field at all - Wallpaper Engine scene picking is purely skwd-walld runtime JSON state, not a Nix option. Do not fabricate a schema field to pass this coverage; it needs a real schema addition from nix-config-architect first.

`gnome-main.nix` and `kde-main.nix` both call `pkgs.fetchurl` inside `home.ifEnabled` to produce wallpaper store paths. This is safe in a pure `nix eval` / nix-tests context because fixed-output derivations compute their store path from the hash without fetching. No network access occurs during evaluation.

For the wallpaper test suite (`test-nixos-wallpapers`), the `eval-scenario.nix` nixosPaths therefore includes:
- `modules/nixos/toplevel/gnome.nix` (enable option)
- `modules/nixos/toplevel/kde.nix` (enable option)
- `modules/nixos/programs/de-wm/gnome/gnome-main.nix`
- `modules/nixos/programs/de-wm/kde/kde-main.nix`
- `modules/nixos/programs/skwd-wall.nix` (was `waypaper.nix`, see 2026-09-21 update above)

The GNOME background URI assertion checks `lib.hasPrefix "file:///nix/store/"` on the dconf `picture-uri` value; the KDE assertion checks `builtins.length hm.programs.plasma.workspace.wallpaper > 0`.

**Why:** Without gnome/kde modules the DE invariant (always uses static wallpaperURL, never gifURL) cannot be tested. Including them is safe because eval doesn't build derivations.

**How to apply:** Any future test that asserts on DE wallpaper config must add the gnome/kde toplevel + main modules to its eval-scenario nixosPaths. The kde-main.nix also needs `inputs.plasma-manager.homeModules.plasma-manager` imported - this happens via `nixos.always` inside kde-main itself.

## fetchurl store-path-suffix gotcha (found while adding mpvpaper/video coverage)

`pkgs.fetchurl { url; sha256; }`'s resulting store path is `<hash-prefix>-<basename-of-url>` - the hash prefix is computed from name+url+sha256 together, NOT simply the sha256 base32 string. Asserting `hyprExecHas gifSHA256Fragment` or similar against the raw sha256 constant **always fails** (false negative) because that literal string never appears in the exec string.

**Why:** discovered when W02/W05/W13 test assertions for "gif/video store path chosen" failed even though the dispatch logic was correct - the sha256 constant just isn't part of the store path text.

**How to apply:** to prove *which* media field (`wallpaperURL` vs `gifURL` vs `videoURL`) was picked by the dispatch logic, assert on the **URL's basename** (e.g. `"may_chill.gif"`, `"loop.mp4"`, `"chainsaw_makima.png"`) instead of the sha256. Give each base-constants-*.nix fixture a distinct, recognizable filename per media field for this reason.
