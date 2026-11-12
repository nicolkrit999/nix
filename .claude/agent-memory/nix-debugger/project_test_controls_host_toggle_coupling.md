---
name: test-controls-host-toggle-coupling
description: Test "control" checks reading the REAL host break when the user flips a host module toggle (darwin-home-paths sops control died when MacBook thunderbird was disabled 2026-11-12)
metadata:
  type: project
---
A non-vacuity control that reads the real host (e.g. "some sops.templates path is under /Users") silently depends on which modules that host enables. When the user turns modules off in hosts/*/default.nix (8fd2284f disabled thunderbird on Krits-MacBook-Pro, the only darwin `/Users` sops template), the control goes red with no config regression.

**Why:** test rules say a host's enabled programs are a host choice, not something tests assert.
**How to apply:** on a red "control:" check, first `git log -p hosts/<host>/default.nix` for recently disabled toggles; fix by moving the control onto an `extendModules` variant that mkForce-enables the module supplying the anchor, not by re-enabling it on the host. Related: [[test-stylix-stub-targets]].
