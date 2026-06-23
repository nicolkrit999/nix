---
name: audio-overlay
description: modules/nixos/services/audio.nix uses a system-wide nixpkgs.overlays to patch pipewire; cross-platform scoping rationale
metadata:
  type: project
---

`modules/nixos/services/audio.nix` (denix `services.audio`) sets a system-wide `nixpkgs.overlays` entry that overrides `pipewire` with `ffadoSupport=false`, `libcamera=null`, `rocSupport=false`.

**Why:** nixpkgs 26.05 regression (commit 3426825) - ffado/libcamera/roc-toolkit pull an i686-linux scons/numpy/openblas build chain on x86_64-linux hosts. None of those features are used (no FireWire/libcamera/ROC network audio).

**How to apply:** The overlay is Darwin-safe by two independent layers:
1. It lives under `nixos.ifEnabled`, which is inert on Darwin (denix only applies `nixos.*` blocks to NixOS builds). Even if the module were moved to `modules/common/`, the overlay would still NOT affect Darwin.
2. The file is in `modules/nixos/` - a NixOS-only path in the flake's 3-way split - so it isn't even auto-discovered for Darwin builds.
Verified: Darwin dry-build of `Krits-MacBook-Pro.system` has zero pipewire/wireplumber/ffado store paths and evaluates clean. See [[cross-platform-split]] for the path-selection mechanics.
