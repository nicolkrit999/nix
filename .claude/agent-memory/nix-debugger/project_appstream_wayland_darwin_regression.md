---
name: appstream-wayland-darwin-regression
description: nixpkgs appstream 1.2.3 (PR #560255, 2026-11-19) adds wayland unconditionally -> every darwin consumer (zathura) fails eval; latex/typst dev-env templates gate zathura to Linux
metadata:
  type: project
---

nixpkgs PR #560255 (appstream 1.1.3 -> 1.2.3, merged 2026-11-19) put `wayland` in appstream's buildInputs with no platform guard. On aarch64-darwin, anything that has appstream as an input (zathura via nativeBuildInputs) throws "Refusing to evaluate package 'wayland'". zathura's own meta.platforms still lists darwin, so `lib.meta.availableOn` does NOT detect it. Only `tryEval drvPath` or an isLinux guard does.

It showed up as the common-dev-env-templates failure "not instantiable: aarch64-darwin/default" for language-specific/latex and typst. The fix (2026-11-20) moved zathura and its banner check into `lib.optionals stdenv.hostPlatform.isLinux`.

**Why:** the PR was labelled rebuild-darwin: 0 because darwin eval broke, so Hydra never surfaced it.
**How to apply:** if another template or darwin home module fails with a wayland platform error, run `--show-trace` and look for appstream in the derivation chain. The isLinux gate can be dropped once locked nixpkgs gates wayland in appstream (check pkgs/development/libraries/appstream/default.nix buildInputs).
