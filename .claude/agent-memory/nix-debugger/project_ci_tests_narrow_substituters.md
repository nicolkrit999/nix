---
name: ci-tests-narrow-substituters
description: tests-nixos.yml trusts only cache.nixos.org + catppuccin + krit-nixos; any test that realises a flake-input package (noctalia) source-builds silently and hits the 10-min timeout
metadata:
  type: project
---

CI test legs (tests-nixos.yml) use only cache.nixos.org, catppuccin.cachix and krit-nixos.cachix. build.yml trusts more (hyprland, cosmic, walker, claude-code, vicinae), and the desktop also has NAS/attic. So "passes locally on an empty store" can still mean a long source build on CI. `nix eval` prints no build logs, so it looks like a hang after the banner.

Seen 2026-10-11 (run 38135221346): hyprland-lua-config `readFile "${universal-lock}/bin/..."` realised noctalia-5.2.1 (krit-nixos cachix holds it only until storage eviction; seen evicted 2026-10-11 01:19-11:37, so a test cannot rely on it). Fixed by reading `pkg.text` instead. portal-routing now builds home.path filtered of bin-only script packages (03-homepath.nix), which drops universal-lock and noctalia.

Seen again 2026-10-12 (run 38275067935, portal-routing heavy-c 30-min timeout on a03428cd): NOT a commit regression; b01->b02 "will be built" sets differed only in system-path/home-manager-path. krit-nixos had evicted desktop-only heavy paths: openlogi (flake input, gpui Rust app, ~25 min on build.yml), ~128 doom-emacs packages (sources on codeberg, 503'd that day), gnome-shell/gdm overlay rebuilds, krokiet. Laptop leg pushed=0, desktop leg rebuilt 1499 drvs. Fix = rerun after build.yml repopulates krit-nixos; verify readiness with a chroot-store dry-run over every host/spec.

**Why:** the timeout gives no hint of the cause, and a local repro hides it unless substituters are restricted.
**How to apply:** for a CI-only test timeout, repro with an empty chroot store plus NIX_CONFIG restricted to CI's 3 substituters, then `nix build --dry-run <drv>^out --store local?root=…` to list "will be built". See [[nix-tests-readonly-ifd]].
