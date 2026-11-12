---
name: spec-fixture-traps-ryoku
description: traps from the ryoku spec tests - denix fixtures need the flake's homeUserFollowsConstants copy, assertion messages throw when forced, xdg.portal.config merges to ";" strings, nested mkOverride loses to an option-level mkForce, portal test duration
metadata:
  type: feedback
---

- From-scratch denix fixture with a specialisation that changes `constants.user`: pass `homeManagerUser` AND the flake's `homeUserFollowsConstants` extension (copied into the test folder, with a check that flake.nix still carries the same body), otherwise denix puts home blocks and `users.users.<fixed>` into the spec.
- Never force `.message` of every element of `config.assertions` (filesystem assertion messages throw "attribute cycle missing" on a healthy config): filter `!a.assertion` first, then read messages. To prove an assertion exists, show it FAILS on a case where it must (aarch64) and that a mutant without it reports none.
- `xdg.portal.config` values merge to `;`-joined strings (coercedTo list), so compare against the table after `concatStringsSep ";" (toList v)`, and the table has `mkForce` leaves to unwrap.
- Twin control that overrides a nested path of an option an upstream spec `mkForce`d at option level does nothing: the partial def is discarded at the option level. Override the WHOLE option at `mkOverride 40` with `recursiveUpdate evaluatedValue {...}`.
- Mutants of a module text: `builtins.replaceStrings` + `builtins.toFile`, load as `/. + unsafeDiscardStringContext path`; rewrite relative imports to absolute (string, no context); assert the anchor matches exactly once. Scratch repo copy + `FLAKE_ROOT` (36 MB) proves mutations without touching tracked files.
- Stock `programs.hyprland` with `withUWSM = false` instantiates an UNCACHED hyprland variant; `withUWSM = true` uses the cached `pkgs.hyprland` (portal-routing fake hosts must stay cache.nixos.org-served).
- test-portal-routing took 871 s on 2026-11-12 after the ryoku case (cap 15 min): flag to the orchestrator if it creeps up.

**Why:** each cost an eval round while writing test-spec-ryoku (2026-11-12).
**How to apply:** any fixture host for a user-changing specialisation, any assertion probe, any portal-routing case.
