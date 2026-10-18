# test-env-shell-wiring

Constants -> resulting NixOS wiring on the REAL `nixos-desktop` and `nixos-laptop` configurations: session variables (`env.nix`), login shell (`user-nixos.nix`), the home-manager backup contract, `hardware.bluetooth.powerOnBoot` and `zramSwap`. It never asserts which browser, terminal, editor, shell or hardware module a host picks, only how the chosen values are derived.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-env-shell-wiring` (name as shown by `--list`); the direct command is below.

From the repo root:

```bash
bash templates/tests/nixos/test-env-shell-wiring/check-nixos-env-shell-wiring.sh
```

Or from inside the directory:

```bash
bash check-nixos-env-shell-wiring.sh
```

Needs `nix`, `jq`, `bash`. Eval-only (no builds); about 100 s per host, hosts evaluated one after the other.

## How it works

`01-scenario-env-shell-wiring.nix` takes `{ host }`, loads `flake.nixosConfigurations.<host>` and exposes `results` (`label -> "ok" | "FAIL: ..."`, each check wrapped in `tryEval`). Variants are `extendModules` twins that override a constant or a module option with `mkOverride 10`, so the result does not depend on what the host chose. The script evaluates `results` per host and fails on any non-`ok`.

Not covered: `home.sessionVariables` in the standalone-home path (`moduleSystem == "home"`), the Darwin `backupFileExtension`, and the real boot-time effect of `powerOnBoot` / zram priority.

## Checks

Each row is evaluated per host.

| Check | Expected |
|-------|----------|
| shell bash/fish/zsh: `users.defaultUserShell` and `users.users.<user>.shell` | `bash-interactive` / `fish` / `zsh` package |
| shell bash/fish/zsh: `programs.zsh.enable` / `programs.fish.enable` | true only for the matching shell |
| shell bash/fish/zsh: shell package in `environment.systemPackages` | present |
| real host: user shell, default shell, `programs.*.enable` match `constants.shell` | consistent |
| control: three shells map to three distinct packages | distinct |
| editor (10 twins: every `editorFlags` key plus an unlisted name) | `EDITOR` equals the blocking flag form, unlisted passes through |
| env: BROWSER / TERMINAL follow `constants.browser` / `constants.terminal.name` (desktop twin) | equal |
| env: server twin exports neither BROWSER nor TERMINAL, still EDITOR | absent / present |
| env: `XDG_BIN_HOME`, `environment.localBinInPath` | set |
| control: role twin differs from the real host values | differs |
| real host: exported BROWSER/TERMINAL equal the constants | equal |
| home-manager: `backupFileExtension` set | non-empty |
| home-manager: `removeExistingConfigs` ordered before `checkLinkTargets` | yes |
| home-manager: `removeExistingConfigs` deletes `mimeapps.list.<backupFileExtension>` | script mentions the configured extension |
| control: twin with another extension | coherence predicate is false |
| bluetooth: `autoEnableOnBoot` true/false | `hardware.bluetooth.powerOnBoot` true/false |
| bluetooth: enabled module | `hardware.bluetooth.enable` and `services.blueman.enable` |
| zram: enabled, `zramPercent` 37 and 61 | `zramSwap.enable`, `zramSwap.memoryPercent` equal the option |
| control: zram module disabled | `zramSwap.enable` false |
| control: check helper detects a mismatch | yes |
