# test-dev-env-templates

Eval-time contract test for the 19 dev-environment template flakes under `templates/krit/dev-environments/`, evaluated against the repo's locked nixpkgs.

## Run

From the repo root:

```bash
bash templates/tests/common/test-dev-env-templates/check-common-dev-env-templates.sh
```

From inside the directory:

```bash
bash check-common-dev-env-templates.sh
```

Needs network on a cold cache (fenix and nix-tests are fetched per the templates' own locks). Takes about 1.5 minutes warm.

## How it works

`01-scenario-dev-env-templates.nix` is a function applied (`--apply`) to a template's `devShells`. For every system and shell it returns a summary: whether `drvPath` instantiates, package names, first package (name, version, python env contents), `shellHook`/`postShellHook`, `JAVA_HOME`, `JAVA_TOOL_OPTIONS`, `RUST_SRC_PATH`, go versions and the lombok store path. Everything is wrapped in `tryEval` so one broken shell is reported as a failed check instead of aborting the run.

`check-common-dev-env-templates.sh` evaluates each template once with `nix eval --override-input nixpkgs github:NixOS/nixpkgs/<rev from flake.lock> --no-write-lock-file` (no FlakeHub fetch of nixpkgs, no lock file written) and asserts with `jq`. Hooks are written to a file and checked with `bash -n` plus an explicit heredoc-terminator scan; two controls prove the lint rejects an indented `EOF` and accepts a column-0 one. Every `[pkg] present` check can fail: a missing name is reported per system. The registry check fails if a flake appears on disk that the table does not list.

All 19 templates are covered. `web-development/fullstack` is expected to use `github:nixos/nixpkgs/nixos-unstable`, all others the FlakeHub `NixOS/nixpkgs/0.1` url. No exclusions.

## Checks

### registry / inputs

| Check | Expected |
|-------|----------|
| every template flake on disk is covered | on-disk set == table |
| nixpkgs url per template | FlakeHub 0.1 (fullstack: github nixos-unstable) |
| fenix / nix-tests follow nixpkgs (lock) | `inputs.nixpkgs` is a follows array |

### evaluation

| Check | Expected |
|-------|----------|
| devShells instantiate (per template) | every shell on x86_64-linux, aarch64-linux, aarch64-darwin has a drvPath |
| x86_64-darwin | no template advertises it (flake.nix text or devShells output) |
| expected tools present (per template) | key package names present on the three supported systems |
| shellHook / postShellHook (per template) | pass `bash -n`, heredocs closed (python fails: terminator indented by Nix stripping) |
| lint controls | bad heredoc flagged, good heredoc accepted |

### per-template contracts

| Check | Expected |
|-------|----------|
| python versions | default 3.15, py-stable 3.13, py-lts 3.12 (from the hook text); no py311 shell exists |
| sql | python env with pandas is the first package; litecli/pgcli still follow it |
| c-cpp, rust | gdb absent on aarch64-darwin, present on x86_64-linux and aarch64-linux |
| go | go version 1.26.* on all three systems |
| java | `JAVA_HOME == jdk25.home` (from nixpkgs); `JAVA_TOOL_OPTIONS` is `-javaagent:<lombok in packages>/share/java/lombok.jar` |
| rust | `RUST_SRC_PATH` ends in `/lib/rustlib/src/rust/library` |
