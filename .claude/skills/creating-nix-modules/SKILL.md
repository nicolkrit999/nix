---
name: creating-nix-modules
description: Use this skill when adding or modifying nix configuration that introduces new functionality, such as new denix modules, enabling programs/services, host constants, theming, or home-manager config. Trigger phrases include 'add a module', 'enable X on host Y', 'install/integrate package Z', 'configure <service> in nix', 'add this to my nixos config', 'set up <program> via home-manager'. Drives the research-author-lint-verify pipeline across nix-package-researcher, nix-config-architect, nix-syntax-linter, and nix-checker. Does NOT cover diagnosing an existing build failure (use debugging-nix-failures instead) or pure attribute/option lookups with no authoring (dispatch nix-package-researcher directly).
---

# Creating Nix Modules

The repo CLAUDE.md mandates delegating authoring, linting, and verification
to agents - never do this work directly in the main loop. The orchestrator
(this chat) dispatches each stage and loops; agents cannot call each other.

## The pipeline

**1. RESEARCH - dispatch `nix-package-researcher`** to confirm exact
attribute paths, option names, and channel availability before any authoring
begins. Training data lags nixpkgs, so don't trust remembered attribute names.
Skip this step only if the task genuinely needs no lookup (e.g. purely
structural change with no new packages/options).

**2. AUTHOR - dispatch `nix-config-architect`** with the task plus the
researcher's findings. It follows repo patterns: denix `delib.module`/`host`
conventions, the 3-way common/nixos/darwin split, the constants system, and
must never bump `stateVersion`.
- If there's doubt about cross-platform/cross-arch placement (does this
  belong in common, or does it need per-OS handling?), dispatch
  `nix-compat-checker` first and feed its judgment into the architect's task.

**3. LINT - dispatch `nix-syntax-linter`** to parse/format-check the new code
and check for denix anti-patterns. It is read-only - findings go back to
`nix-config-architect` to fix, not applied by the linter itself.

**4. VERIFY - dispatch `nix-checker`** to run flake check, the relevant
per-host dry-builds, and the tests suite.
- On failure, switch to the `debugging-nix-failures` loop: dispatch
  `nix-debugger` with the verbatim error, then re-check via `nix-checker`.

**5. Loop 3 -> 4** until the linter reports no findings AND nix-checker is
fully green.

**Safeguard:** after ~4 rounds without convergence, stop and report the
remaining issues to the user instead of continuing indefinitely.

**6. DOCUMENT - dispatch `nix-config-architect`** to add an entry for each
new module to `Documentation/usage/denix/possibilities.md`, under the
matching section (Common Modules, NixOS-Only Modules, or Darwin-Only
Modules - and the correct subsection, e.g. Programs/Services/System) based on
where the module was placed. Follow the file's existing bullet format:
module path in backticks, a one/two-sentence description, and a
`**Warning:**` line only when disabling or misusing the module has real
consequences (mirroring the style already used throughout that file). Skip
this step for changes to an already-documented existing module - it only
applies to genuinely new modules. `nix-config-architect` is used here (not
another agent) because it authored the module and already holds its purpose
and placement in context; no other agent in this pipeline touches
documentation.

## Exit condition

Linter clean + `nix-checker` green + `possibilities.md` updated for any new
modules. Report to the user exactly what was created or modified, on which
host(s), and confirm the documentation entry was added.

## Out of scope

- Diagnosing an already-failing build/eval with no new authoring involved -
  that's `debugging-nix-failures`.
- A pure attribute/option lookup with nothing to author - dispatch
  `nix-package-researcher` directly instead of running this pipeline.
