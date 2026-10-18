# test-flatpak-craft-arch

The storytold "Craft" Flatpak bundles in `hosts/nixos-desktop/flatpak.nix` and `hosts/nixos-laptop/flatpak.nix` are `linux-x86_64` release files. Both modules therefore emit an assertion (`krit.services.desktop.flatpak: ...` / `krit.services.laptop.flatpak: ...`) that must fail on any non-x86_64 host platform and hold on x86_64. This test guards that contract without a (infeasible) aarch64 host evaluation.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-flatpak-craft-arch` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-flatpak-craft-arch/check-nixos-flatpak-craft-arch.sh
```

From inside the directory:

```bash
bash check-nixos-flatpak-craft-arch.sh
```

Eval only, sub-second, no builds. Runs in the `nixos-b` CI group with a 5 minute cap (`test.conf`).

## How it works

A minimal harness imports the REAL module files with a stub `delib` (`module = args: args`, `singleEnableOption = default: default`), the real flake `inputs`, and a plain `import nixpkgs { system = ...; }` as `pkgs` for `aarch64-linux` and `x86_64-linux`. The module's `nixos.ifEnabled` function is then called with a stub `myconfig` (only `constants.timeZone`) and its `assertions` list is read. Only the module's own assertions are selected, by the message prefix `"<module name>:"` taken from the module itself; an empty selection fails (no vacuous pass). The wider NixOS config is deliberately not evaluated (a full aarch64 host eval pulls IFD builds).

Control: a mutant of each file (`hostPlatform.isx86_64` replaced by `hostPlatform.isLinux`, via `builtins.toFile`) is run through the same aarch64 check, which must report FAIL, proving the check can detect a missing arch guard.

Not covered: that `services.flatpak` is actually enabled on a real host, and the rest of the module on aarch64.

## Checks

| Check | Expected |
|-------|----------|
| desktop: fails on aarch64-linux | every `krit.services.desktop.flatpak:` assertion is false (and at least one exists) |
| desktop: passes on x86_64-linux | same assertions are true |
| laptop: fails on aarch64-linux | every `krit.services.laptop.flatpak:` assertion is false |
| laptop: passes on x86_64-linux | same assertions are true |
| control: desktop check rejects a mutant without isx86_64 | the aarch64 expectation reports FAIL on the mutant |
| control: laptop check rejects a mutant without isx86_64 | same |
