---
name: spec-mkforce-needs-harness-decl
description: New myconfig.programs.X referenced from guest/secure-travel specs breaks 3 hand-listed test harnesses ("option ... does not exist" only in spec scenarios)
metadata:
  type: project
---

When a new module's option is set inside `modules/nixos/specializations/{guest,secure-travel}.nix` (e.g. `agent-reach.enable = lib.mkForce false`), every test harness that loads those spec files with a hand-picked module list fails with `specialisation.<s>.configuration.myconfig.programs.<X>' does not exist` - base scenarios still pass, so it looks spec-specific.

Harnesses to update (2026-10-20, agent-reach / d0070b7d):
- `test-arch-compat` both scenario files (module path) + both `shared/host-*.nix` (enable like the real hosts)
- `test-spec-contract/01-scenario-spec-contract.nix` (module path)
- `test-coffee/shared/nixos-extra-x86_64/option-sinks.nix` (`sinks [...]` list)

Same trap when an option MOVES between modules (2026-10-28, 8b019d9f: docEditor/sheetEditor/slideEditor moved from constants-nixos to `modules/nixos/toplevel/mime.nix` -> guest's `myconfig.mime.*` mkForce broke spec-contract; fixed by adding mime.nix to the 3 scenario lists + a `mime` str sink in coffee).

**Why:** harnesses don't use denix auto-discovery; grep `templates/tests` for `specializations/guest.nix` and check each also declares X.
**How to apply:** the arch-compat runner ignores the worktree you run from unless `FLAKE_ROOT` is exported (scenario defaults to /home/krit/nix).
