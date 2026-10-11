# test-waybar-configs

Verifies the generated waybar configs of `waybar-hyprland`, `waybar-mango` and `waybar-niri`: JSON validity, module wiring, shell syntax of every `exec` / `on-click`, per-monitor bar split on Mango and systemd unit binding.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-waybar-configs` (name as shown by `--list`); the direct command is below.

```bash
bash templates/tests/nixos/test-waybar-configs/check-nixos-waybar-configs.sh
```

Or from inside the directory:

```bash
bash check-nixos-waybar-configs.sh
```

Runs in the `nixos-b` CI group (`test.conf`); 63 s inside the full parallel suite run of 2026-10-11. Needs `jq` and `bash`, supplied through `nix shell` by the script itself.

## How it works

`01-scenario-waybar-configs.nix` evaluates the real flake (`nixos-desktop`, `nixos-laptop`) and a third variant, `nixos-desktop` extended with `mango.monitors = []`. For each variant it reads the generated `xdg.configFile."waybar-<wm>/config"` / `style.css` from home-manager, parses the config with `builtins.fromJSON`, and exposes per-check results as strings (`"ok"` / `"FAIL: ..."`). Expected values come from independent sources (host options such as `keyboardName`, `waybarLayout`, `mango.monitors`, the home-manager stylix palette), not from the module code.

`check-nixos-waybar-configs.sh` runs `nix eval --json --impure` for the results, the scenario controls, the raw config texts and the extracted shell snippets. It then parses each config with `jq` and runs `bash -n` on every `exec` / `on-click*` string, printing a per-check PASS/FAIL list and exiting non-zero on any failure. Hosts without Mango (laptop) assert that no Mango waybar config is generated.

## Checks

### Per window manager (each real host with that WM, plus the no-monitors variant)
| Check | Expected |
|-------|----------|
| config is non-empty JSON | at least one bar with `layer` and `modules-right` |
| every listed module is defined | each name in `modules-left/center/right` is a key of the bar |
| custom/notification iff swaync enabled | presence matches `myconfig.services.swaync.enable` |
| style.css has 16 palette defines | 16 `@define-color base0X #rrggbb;` lines equal to the home-manager stylix palette |
| style.css has rules beyond the defines | file is not just the defines |
| ExecStart points at the generated config and css | `-c %h/.config/waybar-<wm>/config -s .../style.css` |

### Hyprland
| Check | Expected |
|-------|----------|
| single bar | exactly one bar |
| language on-click uses hyprctl switchxkblayout | present |
| switchxkblayout targets the configured keyboard | `keyboardName` if set, else `all` |
| no legacy hyprctl dispatch in config | absent |
| waybarLayout override wins | every `waybarLayout` key lands in `hyprland/language` |
| waybarWorkspaceIcons reach format-icons | all icons present plus `default` |
| unit bound to hyprland-session.target | `WantedBy` and `PartOf` |

### Mango (desktop only; laptop must not generate it)
| Check | Expected |
|-------|----------|
| bar count equals monitor count (>=1) | one bar per monitor, one fallback bar with none |
| every monitor string parses to a name | all strings start with `name:` and yield a clean name |
| bar outputs equal monitor names, in order | `output` list equals names parsed independently |
| bar outputs are distinct | no duplicates |
| no monitors gives one bar without output | fallback bar has no `output` |
| per-monitor modules use their own monitor name | tags/layout/window `exec` carry `--arg mon "<output>"` |
| fallback bar resolves the focused monitor at runtime | focused-monitor jq lookup in `custom/tags` |
| custom/layout case covers every layout symbol | S T M G K CT VT VS VG VK RT DW F VF |
| unit bound to mango-session.target | `WantedBy` and `PartOf` |

### Niri
| Check | Expected |
|-------|----------|
| single bar | exactly one bar |
| language on-click switches layout via niri msg | `niri msg action switch-layout-next` |
| workspaces on-click is activate | `activate` |
| waybarLayout override wins | every key lands in `niri/language` |
| unit bound to niri.service | `WantedBy`, `PartOf`, `After` |

### Cross-WM drift (desktop variants)
| Check | Expected |
|-------|----------|
| weather, wifi, bluetooth, mic, notification, pulseaudio, battery, clock identical | niri and mango copies equal the hyprland copy |

### Syntax and controls
| Check | Expected |
|-------|----------|
| jq parses each generated config | valid object or array; the corpus has at least 5 config files |
| all snippets pass bash -n | every `exec` / `on-click*` string of every bar (at least 50 collected) |
| controls | monitor-name parser, undefined-module detector, snippet collector, no-monitors variant effective, `waybarLayout` non-empty on desktop, jq rejects truncated JSON, bash -n rejects an unterminated `if` |
