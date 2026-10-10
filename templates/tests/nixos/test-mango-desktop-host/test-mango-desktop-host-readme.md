# test-mango-desktop-host

Evaluates the real `nixos-desktop` host (not a fake one) and asserts its mango settings, its hypridle DPMS strings, that the generated mango config parses silently, and how the `mango-dpms` script behaves at runtime.

## Run

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

For `mango-dpms` it takes the script from the hypridle string, drops the `export PATH=` line and runs it against a stateful `wlopm` stub (rejects `*` and unknown arguments) in a temp `XDG_RUNTIME_DIR`. The stub models DP-1 and DP-2 on, HDMI-A-1 off.

## Checks

### settings
| Check | Expected |
|-------|----------|
| SUPER,P | spawns `mango-pip` |
| SUPER+ALT,Z | `toggle_scratchpad` |
| SUPER+SHIFT Return/F/B | spawn `mango-scratch` |
| scratch-term / scratch-fs window rules | carry `tags:0` |
| HDMI-A-1 monitor rule | has `disable:1` |
| `window_rule_once` | empty (no zen rule) |
| startup | has `mango-place DP-1 ^zen-beta$ --` line |
| `env` | contains `GDK_SCALE,1` |
| `exec` | absent or empty (`exec_once` only) |
| `bindl` / `bindsl` | volume/next in `bindl`; Play/Pause in `bindsl` and not in `bind` |
| combos across `bind`/`bindl`/`bindsl` | unique |
| XF86Launch6 | `togglefullscreen` |
| `switch_proportion_preset` | never without argument |
| window rules | no `opacity:0` |

### hypridle
| Check | Expected |
|-------|----------|
| any hypridle command string | no direct `wlopm` call (no `wlopm --on '*'`) |
| `after_sleep_cmd` | runs `mango-dpms on` |
| screen-off listener | `mango-dpms off` / `mango-dpms on` |
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
