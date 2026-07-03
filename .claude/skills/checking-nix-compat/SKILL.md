---
name: checking-nix-compat
description: Use this skill when a nix change needs cross-platform or cross-architecture judgment before or after authoring. Trigger phrases include 'will this build on the mac', 'is this safe in a shared module', 'where should this module live', 'does this work on aarch64', 'check cross-platform compat', 'is this Linux-only'. Drives the judge-author-verify loop across nix-compat-checker, nix-config-architect, nix-checker, and nix-debugger. Does NOT cover general authoring with no placement/guard question (use creating-nix-modules instead) or diagnosing a failure unrelated to platform differences (use debugging-nix-failures instead).
---

# Checking Nix Compat

The repo CLAUDE.md mandates delegating verification and debugging to agents -
never run dry-builds or the test suite directly in the main loop. The
orchestrator (this chat) dispatches each stage and loops; agents cannot call
each other.

## The loop

**1. JUDGE - dispatch `nix-compat-checker`** with the module or change in
question. It decides correct placement (`modules/common` vs `modules/nixos`
vs `modules/darwin`), whether Linux-only options in a shared module need
`lib.mkIf (moduleSystem == "nixos")` guards, IFD-guard correctness, and
x86_64 vs aarch64 differences. It can apply simple compat fixes (adding a
guard, moving a small block) itself.

**2. AUTHOR - dispatch `nix-config-architect`** only if the judgment requires
a placement move or non-trivial rework (splitting a module, restructuring
options) beyond what the compat-checker applied directly. Pass it the
compat-checker's judgment verbatim, not a paraphrase.

**3. VERIFY - dispatch `nix-checker`** for BOTH per-arch dry-builds
(`nixos-desktop` toplevel for x86_64-linux AND `Krits-MacBook-Pro` system for
aarch64-darwin) plus the arch-compat test in the templates/tests suite.
Remind it Darwin needs `--impure` on `nix flake check`.

**4. On failure - dispatch `nix-debugger`** with the verbatim error from step
3, then loop back to step 3 to re-verify on the SAME checks. A fix for one
platform can break the other, so always re-check both.

**Loop 3 -> 4** until both platforms' dry-builds and the arch-compat test
pass.

**Safeguard:** after ~4 rounds without convergence, stop and report the
remaining issues to the user instead of continuing indefinitely.

## Exit condition

Both platforms' dry-builds green AND the arch-compat test passes. Report to
the user what moved (if anything), what guards were added or confirmed
correct, and why.

## Out of scope

- General module authoring with no cross-platform question at stake - that's
  `creating-nix-modules`.
- Diagnosing a failure that isn't about platform/arch differences (e.g. a
  typo'd option name, a missing package) - that's `debugging-nix-failures`.
