# test-env-shell-wiring

Constants -> resulting NixOS wiring on the REAL `nixos-desktop` and `nixos-laptop` configurations (real-host checks on both, `mkOverride 10` twins on the laptop only): session variables (`env.nix`), login shell (`user-nixos.nix`), the home-manager backup contract, `hardware.bluetooth.powerOnBoot` and `zramSwap`. It never asserts which browser, terminal, editor, shell or hardware module a host picks, only how the chosen values are derived.

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

Needs `nix`, `jq`, `bash`. Eval-only (no builds); about 30 s warm locally (desktop ~10 s, laptop ~20 s, evaluated one after the other). 54 s on the CI runner (run 40212860316, 2026-10-25; it took 281-420 s before the twins moved to the laptop); the cap is 7 min.

## How it works

`01-scenario-env-shell-wiring.nix` takes `{ host, twins ? true }`, loads `flake.nixosConfigurations.<host>` and exposes `results` (`label -> "ok" | "FAIL: ..."`, each check wrapped in `tryEval`). The script evaluates `results` per host and fails on any non-`ok`.

The checks come in two sets, `realHostChecks // lib.optionalAttrs twins twinChecks`:

- **Real-host checks (14, both hosts):** read the host's own configuration (login shell, `XDG_BIN_HOME`, `EDITOR`/`BROWSER`/`TERMINAL` against the constants, the home-manager backup contract). They are host-dependent, so each host runs them.
- **Twin checks (40, laptop only):** `extendModules` twins override a constant or a module option with `mkOverride 10`, so the result does not depend on what the host chose. `env.nix` is the only NixOS definer of `EDITOR`/`BROWSER`/`TERMINAL` and the hosts only set the bluetooth/zram inputs the twins override, so both hosts give byte-identical twin results. Running them twice bought nothing and cost most of the runtime: the desktop enables GNOME, whose `environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR` references `config.system.path`, so every read of `.EDITOR`/`.BROWSER`/`.TERMINAL` forces the whole `system.path` buildEnv. The 25 twins took ~52 s on the desktop against ~18 s on the laptop (and the old CI runs hit the 7 min cap, 10 times in 60 runs). The desktop therefore runs with `--arg twins false` and the laptop keeps the twins.

With `twins = false` no twin is evaluated: nothing in `realHostChecks` references a twin (laziness), which is what makes the desktop run take ~10 s instead of ~61 s. The script also enforces a per-host floor (desktop at least 10 checks, laptop at least 45) next to the overall floor of 30, so an emptied host cannot hide behind the other.

Not covered: `home.sessionVariables` in the standalone-home path (`moduleSystem == "home"`), the Darwin `backupFileExtension`, and the real boot-time effect of `powerOnBoot` / zram priority.

## Checks

**Real-host checks** (`nixos-desktop` and `nixos-laptop`, 14 each):

| Check | Expected |
|-------|----------|
| real host: user shell, default shell, `programs.zsh.enable` / `programs.fish.enable` match `constants.shell` | consistent |
| control: three shells map to three distinct packages | distinct |
| env: `XDG_BIN_HOME`, `environment.localBinInPath` | set |
| real host: exported BROWSER/TERMINAL equal the constants | equal |
| real host: `EDITOR` is the mapping of `constants.editor` (the same table the editor twins use, unlisted names pass through) | equal |
| control: the `EDITOR` predicate against a deliberately wrong value | false |
| home-manager: `backupFileExtension` set | non-empty |
| home-manager: `removeExistingConfigs` ordered before `checkLinkTargets` | yes |
| home-manager: `removeExistingConfigs` deletes `mimeapps.list.<backupFileExtension>` | script mentions the configured extension |
| control: check helper detects a mismatch | yes |

**Twin checks** (`nixos-laptop` only, 40 more, 54 in total there):

| Check | Expected |
|-------|----------|
| shell bash/fish/zsh: `users.defaultUserShell` and `users.users.<user>.shell` | `bash-interactive` / `fish` / `zsh` package |
| shell bash/fish/zsh: `programs.zsh.enable` / `programs.fish.enable` | true only for the matching shell |
| shell bash/fish/zsh: shell package in `environment.systemPackages` | present |
| editor (10 twins: every `editorFlags` key plus an unlisted name) | `EDITOR` equals the blocking flag form, unlisted passes through |
| env: BROWSER / TERMINAL follow `constants.browser` / `constants.terminal.name` (desktop twin) | equal |
| env: server twin exports neither BROWSER nor TERMINAL, still EDITOR | absent / present |
| control: role twin differs from the real host values | differs |
| control: twin with another backup extension | coherence predicate is false |
| bluetooth: `autoEnableOnBoot` true/false | `hardware.bluetooth.powerOnBoot` true/false |
| bluetooth: enabled module | `hardware.bluetooth.enable` and `services.blueman.enable` |
| zram: enabled, `zramPercent` 37 and 61 | `zramSwap.enable`, `zramSwap.memoryPercent` equal the option |
| control: zram module disabled | `zramSwap.enable` false |

The script counts the checks per host and fails below the floors above (desktop 14 expected, laptop 54).
