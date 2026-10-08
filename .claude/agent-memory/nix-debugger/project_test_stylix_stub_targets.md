---
name: test-stylix-stub-targets
description: templates/tests stylix stubs replace stylix-nixos.nix and must forward myconfig.stylix.targets (`// cfg.targets`), or tests diverge from real hosts
metadata:
  type: project
---

The test suites (arch-compat, minimal-defaults, spec-contract, darwin minimal-defaults) don't load production `modules/nixos/toplevel/stylix-nixos.nix`. They load a `stylix-stub.nix` that copies it (dummy wallpaper). If a stub declares `myconfig.stylix.targets` but doesn't merge `// cfg.targets` into `stylix.targets`, every program module's `myconfig.stylix.targets.*` is silently dropped in tests only. Real hosts pass and the test fails with a stylix-vs-repo "conflicting definition values" error.

**Why:** On 2026-10-08, after the switch to unstable, the new stylix vicinae target produced a font conflict that showed up only in arch-compat. nix-checker blamed a "stale eval cache", which was wrong: it reproduced deterministically.

**How to apply:** If a test fails on a stylix target conflict that real hosts don't show, diff the test's stylix stub against stylix-nixos.nix before suspecting the module. Never accept "eval cache" as the explanation. See [[catppuccin-global-enable-gate]].
