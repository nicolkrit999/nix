---
name: wallpaper-test-eval-scenario
description: gnome/kde pkgs.fetchurl is safe in pure nix eval; how to include DE modules in wallpaper test eval-scenario; fetchurl store-path-suffix gotcha for asserting which media field was chosen
metadata:
  type: feedback
---

`gnome-main.nix` and `kde-main.nix` both call `pkgs.fetchurl` inside `home.ifEnabled` to produce wallpaper store paths. This is safe in a pure `nix eval` / nix-tests context because fixed-output derivations compute their store path from the hash without fetching. No network access occurs during evaluation.

For the wallpaper test suite (`test-nixos-wallpapers`), the `eval-scenario.nix` nixosPaths therefore includes:
- `modules/nixos/toplevel/gnome.nix` (enable option)
- `modules/nixos/toplevel/kde.nix` (enable option)
- `modules/nixos/programs/de-wm/gnome/gnome-main.nix`
- `modules/nixos/programs/de-wm/kde/kde-main.nix`
- `modules/nixos/programs/waypaper.nix`

The GNOME background URI assertion checks `lib.hasPrefix "file:///nix/store/"` on the dconf `picture-uri` value; the KDE assertion checks `builtins.length hm.programs.plasma.workspace.wallpaper > 0`.

**Why:** Without gnome/kde modules the DE invariant (always uses static wallpaperURL, never gifURL) cannot be tested. Including them is safe because eval doesn't build derivations.

**How to apply:** Any future test that asserts on DE wallpaper config must add the gnome/kde toplevel + main modules to its eval-scenario nixosPaths. The kde-main.nix also needs `inputs.plasma-manager.homeModules.plasma-manager` imported - this happens via `nixos.always` inside kde-main itself.

## fetchurl store-path-suffix gotcha (found while adding mpvpaper/video coverage)

`pkgs.fetchurl { url; sha256; }`'s resulting store path is `<hash-prefix>-<basename-of-url>` - the hash prefix is computed from name+url+sha256 together, NOT simply the sha256 base32 string. Asserting `hyprExecHas gifSHA256Fragment` or similar against the raw sha256 constant **always fails** (false negative) because that literal string never appears in the exec string.

**Why:** discovered when W02/W05/W13 test assertions for "gif/video store path chosen" failed even though the dispatch logic was correct - the sha256 constant just isn't part of the store path text.

**How to apply:** to prove *which* media field (`wallpaperURL` vs `gifURL` vs `videoURL`) was picked by the dispatch logic, assert on the **URL's basename** (e.g. `"may_chill.gif"`, `"loop.mp4"`, `"chainsaw_makima.png"`) instead of the sha256. Give each base-constants-*.nix fixture a distinct, recognizable filename per media field for this reason.
