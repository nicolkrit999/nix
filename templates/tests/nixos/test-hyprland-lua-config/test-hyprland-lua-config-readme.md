# test-hyprland-lua-config

Guards the Hyprland 0.56 Lua configuration of the real hosts: rendered config is valid Lua, no legacy `hyprctl dispatch` syntax survives, hypridle chain is sane, and the HM/waybar workarounds are still wired in.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-hyprland-lua-config` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-hyprland-lua-config/check-nixos-hyprland-lua-config.sh
```

From inside the directory:

```bash
bash check-nixos-hyprland-lua-config.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo. Runtime is about one minute (one evaluation of both hosts and their specialisations). Nothing is built: every script is read from its derivation, never from a realised output.

## How it works

`01-scenario-hyprland-lua-config.nix` reads the real `nixos-desktop` and `nixos-laptop` configs and every specialisation whose home-manager Hyprland is enabled (discovered dynamically). `results` maps variant to check to `"ok"` / `"FAIL: <detail>"`. The shell script prints each as PASS/FAIL, then pipes the rendered `hypr/hyprland.lua` through `luac -p` (Lua 5.4) and the `universal-lock` script through `bash -n`. The `universal-lock` text is the derivation's `text` attribute (exactly what `writeShellScriptBin` writes, shebang included), not `builtins.readFile` of its output: realising it would build its `noctalia` input from source on CI, which is in none of the CI caches, and greps the sources for the legacy form.

The legacy-dispatch scan covers the rendered lua, `hypridle.conf`, the waybar config, `universal-lock`, all user service Exec lines and the jetkvm teardown script (read from its `.drv` with the string context kept, never from an unbuilt output, so it passes on an empty store; the waybar `.drv` reads follow the same rule); every `hyprctl dispatch` must be followed by `'hl.`. Caelestia's logout script is covered by the repo-wide source grep because no host enables it. Controls prove the matchers bite (legacy text flagged, lua text accepted, `luac` rejects `A`, stock waybar lacks the patch).

## Checks

### Per variant (hosts and Hyprland specialisations)
| Check | Expected |
|-------|----------|
| `lua-text-nonempty`, `config-type-lua` | rendered file exists, `configType == "lua"` |
| `no-json-unicode-escape` | no `\u00` in hyprland.lua |
| `no-legacy-dispatch` | every `hyprctl dispatch` uses `'hl.` form |
| `hypridle-three-listeners`, `hypridle-timeouts-increase` | 3 listeners, strictly increasing timeouts |
| `hypridle-dpms-lua` | off/on use `hl.dsp.dpms({ action = ... })` incl. `after_sleep_cmd` |
| `universal-lock-present` | `universal-lock` is in `home.packages` and its derivation carries a non-empty script `text` |
| `hypridle-lock-cmd` | `lock_cmd` equals the `universal-lock` package binary |
| `systemd-no-stop-command` | `systemd.extraCommands` is only the start command |
| `waybar-service-present`, `waybar-lua-dispatch-patch` | service exists and its waybar derivation includes the lua-dispatch patch |
| `waybar-control-stock-unpatched` | stock waybar does not contain the patch |
| `xwayland-phantom-rule-*` | `class ^$` + xwayland + `no_focus` rule in settings and rendered lua |
| `jetkvm-teardown-gated-no-ls-pipe` | when a variant has `hyprland-jetkvm-teardown`: `Service.ExecCondition` is set (acts only in a Hyprland session) and the teardown script has no `\| head` (glob over `$XDG_RUNTIME_DIR/hypr/*` instead of `ls`) |
| `wrapper-capabilities-empty`, `with-uwsm` | `security.wrappers.Hyprland.capabilities == ""`, `withUWSM` |

### Script-level
| Check | Expected |
|-------|----------|
| `luac -p hyprland.lua` per variant | exit 0 |
| `bash -n universal-lock` per variant | exit 0 |
| source grep for `hyprctl dispatch` without `'hl.` | no matches |
| controls | matchers flag bad text, the `\| head` matcher discriminates, accept good text, variants cover both hosts (specialisations are tested when they enable Hyprland, none required) |
