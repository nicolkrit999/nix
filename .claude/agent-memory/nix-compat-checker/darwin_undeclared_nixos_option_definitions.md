---
name: darwin-undeclared-nixos-option-definitions
description: A shared (users/krit/common) module that defines a NixOS-only option path breaks darwin eval even inside nixos.ifEnabled; move the definition to a NixOS-only file
metadata:
  type: feedback
---

Writing `nixos.ifEnabled.myconfig.<nixos-only-option>.x = ...` from a shared module (`users/krit/common/...`) breaks `darwinConfigurations` eval with "The option `myconfig.<x>' does not exist", even though the block is `_type = "if"; condition = false`. The option path must not be defined at all on Darwin.

**Why:** seen 2026-11-12 with `neovim.nix` writing `myconfig.mime.editorDesktopIds` (option declared only in `modules/nixos/toplevel/mime.nix`). Removing that one definition made the darwin drvPath eval succeed.

**How to apply:** when a common module needs to feed a NixOS-only option, put the definition in a `users/krit/nixos/` (or `modules/nixos/`) file. Do not rely on a condition inside the common file. Re-check with `nix eval --impure --raw '.#darwinConfigurations.Krits-MacBook-Pro.system.drvPath'` (no allow-import-from-derivation flag; darwin uses an IFD for stylix base16).

Related: [[ryoku-aarch64-enable-throws]]
