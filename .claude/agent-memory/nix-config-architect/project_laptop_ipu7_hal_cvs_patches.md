---
name: laptop-ipu7-hal-cvs-patches
description: nixos-laptop IPU7 camera HAL now pinned to specific upstream commits + 2 CVS-bridge patches, ported from gossamer reference config; build-verified, not yet reboot-verified
metadata:
  type: project
---

`hosts/nixos-laptop/camera.nix`'s overlay (`krit.services.laptop.camera`) pins
`ipu7-camera-bins` and `ipu75xa-camera-hal` to specific upstream commits
(`intel/ipu7-camera-bins@403c67db6b279dd02752f11db6a34552f31a3ac5`,
`intel/ipu7-camera-hal@b1f6ebef12111fb5da0133b144d69dd9b001836c`, both via
`.overrideAttrs { src = final.fetchFromGitHub {...}; }` inside the overlay)
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

**How to apply:** the source-fetch hashes and patch-fetchurl hashes are
final/confirmed (independently re-resolved via `nurl`/`nix flake prefetch`
this session, matched what the task already specified). Real (non-dry) build
of `ipu75xa-camera-hal` via
`nix build .#nixosConfigurations.nixos-laptop.pkgs.ipu75xa-camera-hal --no-link`
succeeded 2026-09-25 - both patches applied cleanly against the pinned
commit, no hunk failures. **This only proves patch-application + compile,
not runtime camera behavior (black-frame vs. real image) - that still needs
a physical reboot to confirm**, not yet done as of this write. See
`~/.claude memory "nixos-laptop-panther-lake-hardware-issues"` (main
session's project memory, not this agent's) for the full hardware
background/symptom history - update that file's webcam section once a real
reboot confirms working (or still-broken) capture.
