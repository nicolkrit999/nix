---
name: darwin-tests-run-on-linux
description: darwin-* test folders are NOT skipped by run-tests.sh on this Linux host; they run eval-only and pass without a Mac (eval, not a darwin build)
metadata:
  type: reference
---

On this Linux laptop, `bash templates/tests/run-tests.sh --only darwin-<name>` runs the darwin test (it is not skipped) and evaluates the Krits-MacBook-Pro config from Linux. Verified 2026-10-21 for darwin-home-paths, darwin-host-contract, darwin-module-defaults, darwin-minimal-defaults.

**Why:** the darwin tests are eval-only (per their readmes), so they do not need a Mac. Passing them proves the evaluated darwin options, not that the darwin toplevel builds; that still needs the separate `nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run`.

**How to apply:** when asked to run darwin tests on Linux, run them via the runner and report PASS/FAIL normally. Do not write SKIP unless the runner actually skips them. Still say the result is eval-only and not a darwin build. Re-check if the runner's platform filter changes.
