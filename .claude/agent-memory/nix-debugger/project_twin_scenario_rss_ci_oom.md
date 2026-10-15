---
name: twin-scenario-rss-ci-oom
description: Test scenarios with many extendModules twins in ONE nix eval grow ~300 MB RSS per twin (never GC'd); >16 GB thrashes ubuntu-latest -> silent timeout with empty log
metadata:
  type: project
---

A scenario `.nix` that defines many `extendModules` twins in one `let` keeps every twin alive for the whole `nix eval` process (all check thunks share the let env), so RSS grows linearly, ~300 MB per full NixOS+HM twin. nixos-app-resolution (62 twins) peaked at 22 GB locally and ran 2 min, but on CI (ubuntu-latest, 16 GB) it hit the 20 min cap with an EMPTY log (output is printed only after the single eval returns). Run 38788879011, 2026-10-15.

**Why:** "passes locally in minutes, times out cold on CI" pointed at cold-store fetching or eval count. The real cause was memory, and only `/run/current-system/sw/bin/time -v` (Max RSS) showed it.

**How to apply:** for a CI timeout of an eval-only test, measure max RSS before trying to cut evals. Fix pattern: split checks into named groups, export `groupNames` plus `groupResults name`, run one eval per group (sequential), and guard against labels repeated across groups. See templates/tests/nixos/test-app-resolution. Related: [[ci-tests-narrow-substituters]], [[nix-tests-readonly-ifd]].
