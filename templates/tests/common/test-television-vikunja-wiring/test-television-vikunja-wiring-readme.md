# test-television-vikunja-wiring

Checks the option wiring of the common modules `programs.television` (`modules/common/programs/television.nix`) and `programs.vikunja-desktop` (`modules/common/programs/vikunja-desktop.nix`): enabling must put the package into `home.packages` and generate the config / desktop entry / handler the module promises, and disabling must leave nothing behind.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only common-television-vikunja-wiring` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/common/test-television-vikunja-wiring/check-common-television-vikunja-wiring.sh
```

From inside the directory:

```bash
bash check-common-television-vikunja-wiring.sh
```

Eval only, no builds (about 10 s). Default CI group (`common`), default cap.

## How it works

`01-scenario-television-vikunja-wiring.nix` extends `nixosConfigurations.template-host-minimal` (the slim host, no desktop) with both modules forced on (`mkForce`) and, as the negative twin, forced off. Results are read from `home-manager.users.<user>`: package presence compares `drvPath`s against `sys.pkgs`, the television config is parsed with `fromTOML`, store paths are compared with `outPath`. Whether a real host enables these programs is deliberately not asserted.

The vikunja desktop entry and mime handler are Linux-only in the module, so this test is meaningful on the Linux flake outputs (the slim host is a NixOS host).

Controls: a third twin overrides the generated values with broken ones (television config without keys, activation replaced by a no-op, desktop entry exec `/bin/false`, empty mimeType, wrong mime handler); the same check functions must report FAIL for each of those five checks.

## Checks

| Check | Expected |
|-------|----------|
| television on: package in home.packages | `pkgs.television` drv is in `home.packages` |
| television on: config.toml is generated | `xdg.configFile."television/config.toml"` exists |
| television on: config.toml parses with integer tick_rate | the file is valid TOML with an integer `tick_rate` |
| television on: activation updates channels with the pinned package | `updateTelevisionChannels` runs `<television outPath>/bin/tv update-channels` |
| television off: no package, config or activation entry | none of the three exists |
| vikunja-desktop on: package in home.packages | `pkgs.vikunja-desktop` drv is in `home.packages` |
| vikunja-desktop on: desktop entry execs the packaged binary | `exec` starts with `<outPath>/bin/vikunja-desktop ` |
| vikunja-desktop on: desktop entry advertises the OAuth scheme | `mimeType` contains `x-scheme-handler/vikunja-desktop` |
| vikunja-desktop on: default handler is the generated desktop entry | `mimeApps.defaultApplications` for the scheme is `vikunja-desktop.desktop` |
| vikunja-desktop off: no package, desktop entry or handler | none of the three exists |

Controls (broken twin, each must be rejected):

| Check | Expected |
|-------|----------|
| control: broken twin is rejected by 'television on: config.toml parses with integer tick_rate' | check reports FAIL |
| control: broken twin is rejected by 'television on: activation updates channels with the pinned package' | check reports FAIL |
| control: broken twin is rejected by 'vikunja-desktop on: desktop entry execs the packaged binary' | check reports FAIL |
| control: broken twin is rejected by 'vikunja-desktop on: desktop entry advertises the OAuth scheme' | check reports FAIL |
| control: broken twin is rejected by 'vikunja-desktop on: default handler is the generated desktop entry' | check reports FAIL |
