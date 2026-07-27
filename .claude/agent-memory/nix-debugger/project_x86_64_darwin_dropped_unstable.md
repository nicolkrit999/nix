---
name: x86-64-darwin-dropped-unstable
description: nixpkgs unstable/26.11 hard-throws on x86_64-darwin, so `nix flake check --all-systems` fails for any template flake listing it in supportedSystems
metadata:
  type: project
---

nixpkgs **unstable** (post-26.05, i.e. the 26.11 development branch) removed
`x86_64-darwin` support. Importing nixpkgs with `system = "x86_64-darwin"` throws
at eval time via `lib.trivial.throwIf` - even `pkgs.hello` fails, so it is never a
package-specific bug.

**Why:** upstream dropped the Intel-Mac platform; see
`nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.11`. The
throw message suggests switching flake inputs to
`github:NixOS/nixpkgs/nixpkgs-26.05-darwin`.

**How to apply:** this hits the template flakes under `templates/krit/...` that
pin FlakeHub `nixpkgs/0.1` (unstable) and list all four systems in
`supportedSystems`. Symptom: `nix flake check --all-systems` fails with a
`throwIf` trace while plain `nix flake check` (current system only) passes.

- Do **not** diagnose this as a broken package. Confirm by evaluating
  `hello` for `x86_64-darwin` against the same input - if that throws too, it is
  the platform removal.
- The repo's own hosts are unaffected (only `aarch64-darwin` is in use - see
  the Active Hosts table in CLAUDE.md).
- Real fix when it matters: drop `"x86_64-darwin"` from that flake's
  `supportedSystems`. Treat as out of scope unless the user asks - it is
  pre-existing in every affected template, not a regression from the change
  being debugged.

Related: [[pkgs-unstable-separate-config]] (other unstable-pin footgun in template flakes).
