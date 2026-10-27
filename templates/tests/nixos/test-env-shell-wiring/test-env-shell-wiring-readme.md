# test-env-shell-wiring

Constants -> resulting NixOS wiring on a minimal fixture host (`template-host-minimal` via `lib/fixture-host.nix`, with only four constants set to non-default values): session variables (`env.nix`), login shell (`user-nixos.nix`), the home-manager backup contract, `hardware.bluetooth.powerOnBoot` and `zramSwap`. It never asserts which browser, terminal, editor, shell or hardware module a real host picks, only how the chosen values are derived. All checks are host-independent, so no real host is used.

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

Needs `nix`, `jq`, `bash`. Eval-only (no builds). One fixture evaluation; the former real-host version took 54 s in CI (run 40212860316), the fixture time is not measured yet.

## How it works

`01-scenario-env-shell-wiring.nix` builds the fixture with `fx.mkNixos` and sets `shell = zsh`, `editor = kate`, `browser = fixture-browser`, `terminal.name = fixture-terminal` (non-default, so the fixture checks cannot pass on defaults by accident). It exposes `results` (`label -> "ok" | "FAIL: ..."`, each check wrapped in `tryEval`). The script evaluates `results` once and fails on any non-`ok`.

- **Fixture checks (14):** read the fixture configuration (login shell, `XDG_BIN_HOME`, `EDITOR`/`BROWSER`/`TERMINAL` against the constants, the home-manager backup contract).
- **Twin checks (40):** `extendModules` twins on the fixture override a constant or a module option with `mkOverride 10`.

The script enforces a floor of 54 checks (also the overall floor), so an emptied scenario cannot pass.

Not covered: `home.sessionVariables` in the standalone-home path (`moduleSystem == "home"`), the Darwin `backupFileExtension`, and the real boot-time effect of `powerOnBoot` / zram priority.

## Checks

**Fixture checks** (14):

| Check | Expected |
|-------|----------|
| fixture: user shell, default shell, `programs.zsh.enable` / `programs.fish.enable` match `constants.shell` | consistent |
| control: three shells map to three distinct packages | distinct |
| env: `XDG_BIN_HOME`, `environment.localBinInPath` | set |
| fixture: exported BROWSER/TERMINAL equal the constants | equal |
| fixture: `EDITOR` is the mapping of `constants.editor` (the same table the editor twins use, unlisted names pass through) | equal |
| control: the `EDITOR` predicate against a deliberately wrong value | false |
| home-manager: `backupFileExtension` set | non-empty |
| home-manager: `removeExistingConfigs` ordered before `checkLinkTargets` | yes |
| home-manager: `removeExistingConfigs` deletes `mimeapps.list.<backupFileExtension>` | script mentions the configured extension |
| control: check helper detects a mismatch | yes |

**Twin checks** (40 more, 54 in total):

| Check | Expected |
|-------|----------|
| shell bash/fish/zsh: `users.defaultUserShell` and `users.users.<user>.shell` | `bash-interactive` / `fish` / `zsh` package |
| shell bash/fish/zsh: `programs.zsh.enable` / `programs.fish.enable` | true only for the matching shell |
| shell bash/fish/zsh: shell package in `environment.systemPackages` | present |
| editor (10 twins: every `editorFlags` key plus an unlisted name) | `EDITOR` equals the blocking flag form, unlisted passes through |
| env: BROWSER / TERMINAL follow `constants.browser` / `constants.terminal.name` (desktop twin) | equal |
| env: server twin exports neither BROWSER nor TERMINAL, still EDITOR | absent / present |
| control: role twin differs from the fixture values | differs |
| control: twin with another backup extension | coherence predicate is false |
| bluetooth: `autoEnableOnBoot` true/false | `hardware.bluetooth.powerOnBoot` true/false |
| bluetooth: enabled module | `hardware.bluetooth.enable` and `services.blueman.enable` |
| zram: enabled, `zramPercent` 37 and 61 | `zramSwap.enable`, `zramSwap.memoryPercent` equal the option |
| control: zram module disabled | `zramSwap.enable` false |

The script counts the checks and fails below the floor of 54.
