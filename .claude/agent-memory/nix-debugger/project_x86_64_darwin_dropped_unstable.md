---
name: x86-64-darwin-dropped-unstable
description: nixpkgs unstable hard-throws on x86_64-darwin, so `nix flake check --all-systems` fails for any template flake listing it in supportedSystems
metadata:
  type: project
---

nixpkgs **unstable** removed `x86_64-darwin` support. Importing nixpkgs with
`system = "x86_64-darwin"` throws at eval time via `lib.trivial.throwIf` - even
`pkgs.hello` fails, so it is never a package-specific bug.

**Why:** upstream dropped the Intel-Mac platform (see the x86_64-darwin entry in
the nixpkgs unstable release notes). The throw message points at a
release-specific darwin nixpkgs branch as the escape hatch.

**How to apply:** this hits the template flakes under `templates/krit/...` that
pin FlakeHub `nixpkgs/0.1` (unstable) and list all four systems in
`supportedSystems`. The repo itself now tracks nixos-unstable too, but only
`aarch64-darwin` is in use (Active Hosts table in CLAUDE.md); flake.nix still
lists `x86_64-darwin` only in the `isDarwin` guard, which is harmless.
Symptom: `nix flake check --all-systems` fails with a `throwIf` trace while plain
`nix flake check` (current system only) passes.

- Do **not** diagnose this as a broken package. Confirm by evaluating `hello`
  for `x86_64-darwin` against the same input - if that throws too, it is the
  platform removal.
- Real fix when it matters: drop `"x86_64-darwin"` from that flake's
  `supportedSystems`. Out of scope unless the user asks - pre-existing in every
  affected template, not a regression from the change being debugged.

Related: [[pkgs-unstable-separate-config]] (the separate-nixpkgs-instance config trap).
