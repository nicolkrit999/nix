---
name: mkshell-path-precedence
description: In template devShells, $PATH order == `packages` list order; lib.hiPrio and postShellHook are both no-ops in mkShell/mkShellNoCC
metadata:
  type: project
---

In `pkgs.mkShell`/`mkShellNoCC`, `$PATH` is a plain concatenation of each `packages`
entry's `bin/` in **list order**. Two things that look like fixes but are not:

- `lib.hiPrio` - only affects `buildEnv`/profile symlink-conflict resolution
  (nix-env, home-manager, `environment.systemPackages`). Zero effect on devShell PATH.
- `postShellHook` - a real nixpkgs hook name, but it is only ever executed by hooks
  that call `runHook postShellHook` (`venv-shell-hook.sh`, `pip-build-hook.sh`).
  Putting `ps.venvShellHook` inside `python3.withPackages (...)` does **not** register
  its setup hook (withPackages is a buildEnv; member setup hooks are not propagated),
  so `shellHook` stays empty and `postShellHook` is dead. `venvShellHook` belongs in
  `nativeBuildInputs`, standalone, alongside `venvDir`.

**Why:** cost three failed fix attempts on
`templates/krit/dev-environments/language-combined/sql/flake.nix`, where a
`python313.withPackages` env lost to nixpkgs' bare python3 propagated by
litecli/pgcli/sqlite-web/sqlite-utils.

**How to apply:** to make a `withPackages` interpreter win, put it **first** in
`packages`. Verify with `nix print-dev-env | grep shellHook` (empty string means no
hook is running) and `nix develop -c which python3`.

Related: [[pkgs-unstable-separate-config]]
