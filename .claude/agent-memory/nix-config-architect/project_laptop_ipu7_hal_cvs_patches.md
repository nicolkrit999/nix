---
name: laptop-ipu7-hal-cvs-patches
description: nixos-laptop IPU7 camera HAL now pinned to specific upstream commits + 2 CVS-bridge patches, ported from gossamer reference config; runtime tested: link setup fixed, frames still black (open upstream issue)
metadata:
  type: project
---

`hosts/nixos-laptop/camera.nix`'s overlay (`krit.services.laptop.camera`) pins
`ipu7-camera-bins` and `ipu75xa-camera-hal` to specific upstream commits
(`intel/ipu7-camera-bins@403c67db6b279dd02752f11db6a34552f31a3ac5`,
`intel/ipu7-camera-hal@b1f6ebef12111fb5da0133b144d69dd9b001836c`, both via
`.overrideAttrs (_old: { src = prev.fetchFromGitHub {...}; })` inside the overlay)
instead of whatever revision `nixpkgs-unstable` currently ships, and applies
two patches on top of the HAL (`omarchyPatch` helper, `pkgs.fetchurl` from
`raw.githubusercontent.com/omacom/omarchy-pkgs/59732a3e6fc5f158360b480ad38f479faf1f3677/pkgbuilds/intel-ipu7-camera/000{5,6}-...patch`).

**Why:** stock nixpkgs-unstable HAL revision lacks Intel CVS-bridge routing
(Linux 7.2+ inserts a Synaptics SVP7500 CVS bridge between the `ov08x40`
sensor and the IPU7 on this exact laptop model, Dell XPS 16 DA16260 Panther
Lake) - without it, capture opens but every frame is solid black (confirmed
on real hardware 2026-09-25, symptom: `MediaControl: failed to setup Link
ov08x40 S ... ==> Intel IPU7 CSI2 0` + `CaptureUnit: Devices stream on
failed:-38`). Ported from a reference config for the identical laptop model
(source repo no longer present on disk as of this session - gone from
`/home/krit/Downloads/nixos-config-master/` - treat any future re-port from
that source as needing re-fetch, not assumed-cached).

**Runtime status (checked 2026-10-17):** booted and tested. The two CVS
patches fix the link setup (the `failed to setup Link` / `stream on failed:-38`
errors are gone), but captured frames are still black. That remaining failure
is an open upstream issue, not something this overlay can fix. The intel_cvs
wake-irq kernel patch is still needed on 7.3-rc7 (recheck thesofproject/linux#5940
at the next kernel bump). Camera overlay pins are still ahead of nixpkgs.

**How to apply:** the source-fetch hashes and patch-fetchurl hashes are
final/confirmed (re-resolved via `nurl`/`nix flake prefetch`). A real build of
`ipu75xa-camera-hal` via
`nix build .#nixosConfigurations.nixos-laptop.pkgs.ipu75xa-camera-hal --no-link`
succeeded 2026-09-25, both patches apply cleanly against the pinned commit.
See the main session's project memory `project_laptop_panther_lake_issues.md`
for the full hardware background and symptom history.
