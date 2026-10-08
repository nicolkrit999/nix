---
name: unstable-tracking-realities
description: Repo tracks nixos-unstable only; no pkgs-unstable; pkgsStable is the pin escape hatch; camera.nix is just source pins + CVS patches; hyprland exec-once is a Lua function
metadata:
  type: project
---

- Single nixpkgs (nixos-unstable). `pkgs-unstable` and the `nixpkgs-unstable` input no longer exist; use plain `pkgs.X`. For a per-package pin use the module arg `pkgsStable` (built in flake.nix from the permanent `nixpkgs-stable` input, allowUnfree only; docs: Documentation/usage/denix/pkgs-stable.md). It does not carry `permittedInsecurePackages`.
- Never mix channels for ABI-coupled pieces (GStreamer plugins, kernel modules): not needed anymore, since the IPU7 camera stack (`hardware.ipu7`, `ipu7-drivers`, `ipu75xa-camera-hal`, `icamerasrc`) is native in nixpkgs. `hosts/nixos-laptop/camera.nix` only holds `overrideAttrs` source pins plus the Intel CVS bridge patches.
- Hyprland `execOnce` is rendered by hyprland-main.nix as a Lua function bound to the `hyprland.start` event; contributors (e.g. caelestia) only append to the option.
- FlakeHub dev flakes use `nixpkgs/0.1` (rolling); `/0` is the latest release series.
- Darwin was never tested after the switch (no Mac). Details: ~/momentary/nix-unstable-26_11-change/.
