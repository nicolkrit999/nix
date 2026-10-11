# test-mango-desktop-host

Evaluates the real `nixos-desktop` host (not a fake one) and asserts its mango settings, its hypridle DPMS strings, that the generated mango config parses silently, and how the `mango-dpms` script behaves at runtime.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-mango-desktop-host` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-mango-desktop-host/check-nixos-mango-desktop-host.sh
```

From inside the directory:

```bash
bash check-nixos-mango-desktop-host.sh
```

`DPMS_SCRIPT=<path>` points the runtime part at an alternative copy of the `mango-dpms` script. `FLAKE_ROOT=<path>` evaluates another copy of the repo; by default it is derived from the script location, so the tree containing the script is the tree under test.

## How it works

`01-scenario-mango-desktop-host.nix` reads `nixosConfigurations.nixos-desktop` (home-manager user `krit`): `wayland.windowManager.mango.settings` and `services.hypridle.settings`. Each `check-*` attribute is `"ok"` or `"FAIL: <detail>"`; the script runs `nix eval --raw --impure` per attribute.

The script also builds the mango `config.conf` and runs `mango -c <conf> -p`, requiring exit 0 and empty stdout and stderr (the exit code alone is unreliable: it is 0 even with keybind conflicts).
The mango package is built explicitly together with the config (`nix build "$confdrv^out" "$pkgdrv^out"`, via the `mango-package-drv` scenario attribute): `config.conf` does not reference the package, so building it alone left the binary unrealised on a fresh runner (it only passed on hosts already running mango). A build failure prints the `nix build` error text.

For `mango-dpms` it takes the script from the hypridle string (the `mango-dpms` drv in its context), drops the `export PATH=` line and runs it against a stateful `wlopm` stub (rejects `*` and unknown arguments) in a temp `XDG_RUNTIME_DIR`. The stub models DP-1 and DP-2 on, HDMI-A-1 off.

## Checks

### settings
Which binds, monitors and startup lines the host chooses is deliberately not asserted; only invariants and cross-file consistency are.

| Check | Expected |
|-------|----------|
| every `--class X` of a `mango-scratch` bind | has a window rule with `app_id:^X$` and `tags:0` (bind and rule are two sources); control: predicate rejects wrong class / missing tag |
| `window_rule_once` | empty (re-arms on reload) |
| `exec` | absent or empty (`exec_once` only) |
| Play/Pause | present in `bindl`/`bindsl`, never in plain `bind` |
| combos across `bind`/`bindl`/`bindsl` | unique; control: duplicate predicate flags `A,b,x`+`A,b,y` |
| `switch_proportion_preset` | never without argument; control on the predicate |
| window rules | no `opacity:0` (also `focused_opacity:0`, not `0.01`); control on the predicate |

### bind/rule shape and layouts
| Check | Expected |
|-------|----------|
| `bind`, `bindl`, `bindsl`, `mousebind`, `axisbind`, `gesturebind`, `tag_rule`, `layer_rule` | all non-empty |
| every bind entry | at least 3 comma fields |
| every `tag_rule` / `layer_rule` entry | at least 2 comma fields, each `key:value` |
| `tag_rule` vs `myconfig.programs.mango.monitorLayouts` | tags 1-9 per monitor carry the layout the option names (option and generated rules are two sources; the concrete layouts are a host choice and not hardcoded) |
| `tag_rule` | exactly one entry per (tag, monitor); `defaultLayout` fallback for tags 1-9; entries well formed |
| controls | the field-count and per-monitor predicates reject mutated/short inputs |

The 255-char limit of these lists is not checked here: `test-wallpaperd-runtime` already covers every mango settings string on every host.

### GDK_SCALE and systemd variables
| Check | Expected |
|-------|----------|
| `home.sessionVariables.GDK_SCALE` vs `settings.env` | not `"1"` (first monitor scale is not 1, Hyprland path) vs `GDK_SCALE,1` (mango override) |
| `systemd.variables` | contains `GDK_SCALE`; every name is a session variable or in the allow-list (`DISPLAY`, `WAYLAND_DISPLAY`, `XDG_*` session vars, `XCURSOR_*`); control proves the predicate bites |

### hypridle
| Check | Expected |
|-------|----------|
| any hypridle command string | no direct `wlopm` call (no `wlopm --on '*'`) while a `mango-dpms on` command exists (not vacuous); control on both predicates |
| `after_sleep_cmd` | runs `mango-dpms on` as a whole word (not `mango-dpms once`) |
| screen-off listener | `mango-dpms off` / `mango-dpms on` (whole word) |
| Hyprland and niri branches | still present |

### mango -p
| Check | Expected |
|-------|----------|
| exit code | 0 |
| stdout + stderr | empty |

### mango-dpms (stub wlopm)
| Check | Expected |
|-------|----------|
| `off` | `--off` for DP-1 and DP-2, never HDMI-A-1; record lists DP-1, DP-2 |
| second `off` while all are off | record kept |
| `on` | `--on` for DP-1 and DP-2 only, no HDMI-A-1, no `*`; record removed; HDMI-A-1 still off |
| `on` without a record | no wlopm call |
| unknown argument | exit 2 |
