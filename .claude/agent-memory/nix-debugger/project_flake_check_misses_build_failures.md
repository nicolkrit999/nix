---
name: flake-check-misses-build-failures
description: nix flake check and --dry-run only evaluate; failures inside a derivation's build phase (config-file validators like mango's parser) need a real nix build to reproduce
metadata:
  type: project
---

`nix flake check` and `nix build --dry-run` **only evaluate**. They cannot catch
a failure that happens inside a derivation's *build phase* - e.g. a generated
config file that a validator rejects at build time.

**Why:** A mango wallpaper regression evaluated perfectly clean (`nix flake
check` green) but blew up on `nh os switch` with
`mango-config.conf> [ERROR]: Unknown keyword: ...`, because mango runs a config
parser as a build step. `--dry-run` would have reported the same green result -
it prints what *would* be built without building it.

**How to apply:** When the reported symptom is a message from a *tool* (a config
parser, a validator, `checkPhase` output) rather than a Nix evaluator error,
reproduce with a real `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link`,
not a dry-run. Verify the fix by evaluating the offending option directly
(`nix eval --json .#...settings.exec`) to confirm the generated value is sane.
For specialisations, reach them at
`.config.specialisation.<name>.configuration.home-manager.users.krit....`.
Nuance to [[tests-no-rebuild-needed]]: `git add` is still enough (no system
activation required), but the *verification command* must be a build, not a check.
