---
name: kernel-dev-systemmap-depmod
description: Since nixpkgs PR #571170 (2026-10-11) kernel.dev ships build/System.map, so out-of-tree `make modules_install` runs depmod and the module output collides in the kernel-modules buildEnv (v4l2loopback)
metadata:
  type: project
---

nixpkgs 48c3567255 "linux: keep enough to rebuild images from `vmlinux`" (#571170) keeps `$buildRoot/System.map` in `kernel.dev`. The kernel's `scripts/depmod.sh` only skipped depmod for external modules because System.map was missing; now it runs and writes `lib/modules/<ver>/modules.*` into the module package output. Result: `linux-*-modules> pkgs.buildEnv error: two given paths contain a conflicting subpath ... modules.dep`, only at the final aggregate (all inputs build fine).

v4l2loopback's `sed -i '/depmod/d' Makefile` only strips its own Makefile's call, not the kernel's. Fix in repo: `boot.kernelPackages = (...).extend` overriding `v4l2loopback` with `env.DEPMOD = "true"` (depmod.sh honours `${DEPMOD:=depmod}`) in modules/nixos/toplevel/kernel.nix. ipu7-drivers was unaffected (copies .ko manually).

**Why:** upstream regression, not fixed on master as of 2026-10-20.
**How to apply:** any other out-of-tree module that runs kernel `modules_install` can hit the same collision; check its output for `modules.*` files and extend the same override. Remove when nixpkgs sets DEPMOD for kernelModuleMakeFlags or v4l2loopback's output stops shipping modules.dep.
