---
name: ryoku-aarch64-enable-throws
description: Ryoku upstream nixosModules.default throws "attribute 'aarch64-linux' missing" when enabled on aarch64; the spec carries an isX86 assertion (landed) instead of a mkIf
metadata:
  type: project
---

Upstream Ryoku (`github:Ryoku-dev/Ryoku-on-NixOS`) exposes `packages`/`apps`/`checks` for `x86_64-linux` only. Its `nix/modules/ryoku.nix:11` does `self.packages.${pkgs.stdenv.hostPlatform.system}`, so importing the module on aarch64-linux is fine but enabling it throws `attribute 'aarch64-linux' missing`.

**Why:** verified 2026-11-12 with a scratch `nixosSystem` on aarch64-linux: enable=false evaluates, enable=true throws. No aarch64 NixOS host exists, so it was latent.

**How to apply:** `modules/nixos/specializations/ryoku.nix` now defines `isX86` and asserts it in its assertions list ("Ryoku is x86_64-linux only"), plus `enable = isX86` further down. Keep guarding via assertion/enable flag, not a `mkIf` on the unconditional import. Whether the assertion fires before the throw on aarch64 was never verified. Related: [[darwin-undeclared-nixos-option-definitions]]
