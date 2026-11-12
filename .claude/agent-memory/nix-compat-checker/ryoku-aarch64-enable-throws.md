---
name: ryoku-aarch64-enable-throws
description: Ryoku upstream nixosModules.default is inert on aarch64-linux but throws "attribute 'aarch64-linux' missing" when programs.ryoku.enable is set; guard with an assertion in the spec, not a mkIf
metadata:
  type: project
---

Upstream Ryoku (`github:Ryoku-dev/Ryoku-on-NixOS`) exposes `packages`/`apps`/`checks` for `x86_64-linux` only. Its `nix/modules/ryoku.nix:11` does `self.packages.${pkgs.stdenv.hostPlatform.system}`, so importing the module on aarch64-linux is fine but enabling it throws `attribute 'aarch64-linux' missing`.

**Why:** verified 2026-11-12 with a scratch `nixosSystem` on aarch64-linux: enable=false evaluates, enable=true throws. No aarch64 NixOS host exists and the arch-compat fixtures never load ryoku.nix, so it is latent.

**How to apply:** the Ryoku spec (`modules/nixos/specializations/ryoku.nix`) should carry an `isx86_64` assertion at the top level of its `nixos.ifEnabled` body (precedent: `hosts/*/flatpak.nix:33`), not a `mkIf` guard on the unconditional import. Re-check by evaluating the aarch64 scratch expression with enable=true once the assertion lands; the assertion must fire before the throw (unverified at time of writing). Related: [[darwin-undeclared-nixos-option-definitions]]
