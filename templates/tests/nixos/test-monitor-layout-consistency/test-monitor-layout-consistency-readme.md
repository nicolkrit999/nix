# test-monitor-layout-consistency

Asserts that the monitor layout declared three times (hyprland, mango, niri) agrees on the real `nixos-desktop` and `nixos-laptop` hosts, and that the laptop `home` specialisation is self-consistent.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-monitor-layout-consistency` (name as shown by `--list`); the direct command is below.

From repo root:

```bash
bash templates/tests/nixos/test-monitor-layout-consistency/check-nixos-monitor-layout-consistency.sh
```

From inside the directory:

```bash
bash check-nixos-monitor-layout-consistency.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo (default: the tree containing the script).

## How it works

`01-scenario-monitor-layout-consistency.nix` loads the real flake and normalises the three sources into one shape (width, height, rounded refresh, scale, position, rotation in degrees, off): `myconfig.programs.hyprland.monitors` (mode/position strings, `mirror` counts as off), `myconfig.programs.mango.monitors` (`monitor_rule` strings parsed, `disable:1` is off, `rr` is rotation) and `myconfig.programs.niri.outputs`. A shared comparison function reports per-field mismatches. Mode (width, height, refresh), scale and position are skipped for disabled or mirrored outputs and when fewer than two outputs are active. A field unset in one source counts as a mismatch. Control checks run the same function on a niri copy with mutated values and require it to flag them. Each `check-*` attribute is `"ok"` or `"FAIL: <detail>"`; the script runs `nix eval --raw --impure` per attribute. Eval only, no builds. Host-choice pins (concrete rotation/mode values, which outputs are enabled, which WMs are on, waybar icons) are deliberately not asserted; only cross-source agreement and the specialisation's lid contract. The test uses the real hosts, no synthetic host. niri off-state is read from `enable` (`!(o.enable or true)`).

## Checks

### desktop
| Check | Expected |
|-------|----------|
| presence | DP-1, DP-2, HDMI-A-1 in hyprland, mango and niri |
| width / height / refresh / scale | equal across the three |
| rotation | equal across the three |
| position | equal for enabled outputs |
| HDMI-A-1 | mirrored/disabled in all three (niri: `enable = false`; hyprland: mirror or `disabled`; mango: `disable:1`) |

### laptop base
| Check | Expected |
|-------|----------|
| presence, mode, rotation | eDP-1 in all three and equal |
| scale | equal |
| position | equal (skipped: single active output) |

### laptop specialisation home
| Check | Expected |
|-------|----------|
| desc: monitors | each has a niri output keyed `make model serial` |
| mode / scale / rotation / position | hyprland equals niri per output |
| niri outputs | none without a hyprland monitor |
| monitorWorkspaces, wallpapers targetMonitor | refer to declared outputs |
| `HandleLidSwitch*` | all `ignore` |

### controls
| Check | Expected |
|-------|----------|
| mutated scale / refresh / position / rotation | flagged |
| disabled HDMI-A-1 | not part of the position comparison |
