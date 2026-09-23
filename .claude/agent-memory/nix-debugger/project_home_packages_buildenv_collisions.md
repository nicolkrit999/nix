---
name: home-packages-buildenv-collisions
description: home.packages buildEnv collisions (two python3 envs via bin/idle, poppler vs poppler-utils) surface only in the SPECIALISATION home-manager-path, never in the base one or in flake check
metadata:
  type: project
---

`home-manager-path` is a `buildEnv`: any two *different* derivations that ship
the same relative path make it fail with
`two given paths contain a conflicting subpath`. Two recurring sources in this
repo:

- **Any `pythonX.withPackages` put into `home.packages`** also ships
  `bin/{python,idle,idle3,pydoc,...}`. Two such envs collide even when the
  package lists are disjoint. If the goal is a single CLI, use
  `pkgs.python3.pkgs.toPythonApplication <buildPythonPackage>` instead - console
  scripts from `buildPythonPackage` are already self-contained (their wrapper
  embeds every dep path via `site.addsitedir`), so the `withPackages` env buys
  nothing but collisions.
- **`poppler` vs `poppler-utils`**: bare `poppler` ships only libs (no
  `pdftoppm`), and its `lib/libpoppler-cpp.so.*` collides with
  `poppler-utils`. Anything wanting PDF previews wants `poppler-utils`.

**Why:** Both bit us at once on nixos-desktop (2026-09-23): `headroom.nix`'s
python env vs the school specialisation's scientific python env, then
`yazi.nix`'s `poppler` vs school's `poppler-utils`.

**How to apply:** These conflicts are usually invisible in the *base*
`home-manager-path` - the second colliding package often lives in a
specialisation, which merges into the parent's home-manager config. So after any
`home.packages` change, build every specialisation's home path, not just the
base one:
`nix build .#nixosConfigurations.<host>.config.specialisation.<s>.configuration.home-manager.users.krit.home.path`
(enumerate `<s>` via `nix eval .#nixosConfigurations.<host>.config.specialisation --apply 'x: builtins.attrNames x'`).
This is a build-phase failure, so see [[flake-check-misses-build-failures]].
