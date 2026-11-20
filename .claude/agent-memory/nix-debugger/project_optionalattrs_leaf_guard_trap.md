---
name: optionalattrs-leaf-guard-trap
description: `x.y.z = lib.optionalAttrs (options has z) {...}` still defines x.y.z = {} when the option is missing -> "option does not exist" in test fixtures that omit the module
metadata:
  type: project
---

Guarding an optional-module setting as `myconfig.services.foo = lib.optionalAttrs (cond) { bar = true; };` does NOT remove the definition when cond is false: the module system still sees a definition `{}` at `myconfig.services.foo` and throws "The option ... does not exist" (the error's "Definition values" is truncated in test logs, so it looks like the guard was evaluated wrong). Real hosts pass because they load the module; hand-listed test fixtures (test-spec-contract, test-spec-ryoku) do not.

**Why:** hit 2026-11-20 in ryoku.nix (media-idle-inhibit ryokuSession inside specialisation.ryoku.configuration).

**How to apply:** guard the whole module instead, e.g. put `(lib.optionalAttrs (lib.hasAttrByPath [ "myconfig" "services" "foo" ] options) { myconfig.services.foo.bar = true; })` in `imports` (outer `options`, same as ryoku's mkOff), or optionalAttrs at a level whose parent option always exists. Related: [[spec-mkforce-needs-harness-decl]], [[test-controls-host-toggle-coupling]].
