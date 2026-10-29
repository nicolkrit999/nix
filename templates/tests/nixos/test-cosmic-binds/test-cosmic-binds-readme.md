# test-cosmic-binds

Contract of the declarative COSMIC keybinds (`modules/nixos/programs/de-wm/cosmic/cosmic-binds.nix` plus the `programs.cosmic.extraBinds` option in `cosmic-main.nix`) and of the declarative COSMIC monitor layout (`cosmic-monitors.nix` plus the `programs.cosmic.monitors` option; second scenario, see "Monitor layout" below), evaluated on twins of the minimal `template-host-minimal` fixture (`lib/fixture-host.nix`) that enable only COSMIC (and KDE for the comparison). It does not test which DE a host enables. The module mirrors the KDE hotkeys (`kde-binds.nix`) with `Meta` becoming `Super`; the KDE spectacle and default-rebind entries are not ported.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-cosmic-binds` (name as shown by `--list`); the direct commands are below.

From the repo root:

```bash
bash templates/tests/nixos/test-cosmic-binds/check-nixos-cosmic-binds.sh
```

Or from inside the directory:

```bash
bash check-nixos-cosmic-binds.sh
```

Needs `nix`, `jq`, `bash`. About 25 s warm (eval only, both scenarios); the cap is 4 min (`test.conf`, group `nixos-b`, which has no room for a 5 min cap in its CI step budget).

## How it works

`01-scenario-cosmic-binds.nix` exposes `results` (`label -> "ok" | "FAIL: ..."`, each check wrapped in `tryEval`). The checkers are plain functions over a shortcut list (`{key, description, action}` as in `wayland.desktopManager.cosmic.shortcuts`):

- `uniqueProblems` normalises every key (lowercase, modifiers sorted) and reports duplicates.
- `setProblems` compares the key -> command map with a predicted map and reports missing, unexpected and wrong-command keys, plus any action that is not one non-empty `Spawn` string.
- The predicted map is derived at test time from the twin's own constants (`terminal.name`, `browser`, `editor`, `fileManager`, `terminalApps`) with the `<terminal> -e <app>` wrapper for `terminalApps` members; the KDE comparison derives its map from the same twin's `programs.plasma.hotkeys.commands` (`Meta` to `Super`, `.` to `period`, because COSMIC uses xkb keysym names).

Twins: defaults (editor in `terminalApps`, fileManager not), alternate constants (kitty, firefox, code, yazi: the wrapping flips), vicinae off, extra binds (one with quoted arguments, one with reordered modifiers), an extra colliding with a built-in key, two extras colliding with each other, and cosmic off (with and without stylix). The launcher/vicinae checks look at the 7 Spawn binds only (the two screenshot binds are checked separately); the five window actions (Fullscreen on Super+M and Super+Shift+F, Maximize on Super+Alt+A, Close on Super+Shift+C, Minimize on Super+Shift+M) and the two System actions (Super+Delete = LockScreen, Super+Shift+Delete = LogOut, nested `System` enum) are checked separately by exact enum shape, and uniqueness covers all of them. Negative controls apply the same checkers to synthetic lists (duplicated, case-variant, missing and extra entries, non-`Spawn` action, wrong window variant) and to mismatching predictions, and must report a problem. The stylix-off twin uses `myconfig.stylix.enable = false` (setting `stylix.enable` directly breaks the home-manager stylix options).

## Checks

### Built-in binds
| Check | Expected |
|-------|----------|
| keys unique (defaults) | no duplicate normalised key |
| command set equals constants-derived set | exact key -> command equality |
| every action one non-empty Spawn string | shape holds for all shortcuts |
| seven Spawn binds | 4 launcher binds plus 3 vicinae binds as `Spawn` |
| sixteen active binds in total | the 7 Spawn binds plus 2 screenshot binds plus 5 window actions plus 2 System actions |
| 21 shortcut entries | the 16 active binds plus the 5 `Disable` shadows (`programs.cosmic.disabledDefaults`) |
| Disable shadows | exactly `Super+Escape`, `Super+Shift+Escape`, `Super+q`, `Super+F11`, `Super+t`, each exactly `{ key; action = { __type = "enum"; variant = "Disable"; }; }` (no description), none equal to an active bind; identical with vicinae off, alternate constants and extras; controls: Disable on an active key, wrong variant, extra unknown Disable, missing Disable, description on a Disable |
| Super+M / Super+Alt+A | `Super+M` is exactly one `Fullscreen` (replaces COSMIC's default Maximize), `Super+Alt+A` exactly one `Maximize` |
| system actions | exactly `Super+Delete` = `{ __type = "enum"; variant = "System"; value = [ { __type = "enum"; variant = "LockScreen"; } ]; }` and `Super+Shift+Delete` = the same with `LogOut`, each with a description; identical with vicinae off, alternate constants and extras; controls: missing bind, wrong variant, flat shape, unexpected key, missing description |
| screenshot binds | `Super+Ctrl+3` is a single script path whose content sets `dir` to `constants.screenshots`, runs `mkdir -p "$dir"` and `grim "$dir/Screenshot_$(date +%F_%H-%M-%S).png"`; `Super+Ctrl+4` is the bare `cosmic-screenshot` binary without flags; identical with alternate constants, vicinae off and extras; `Print` is not rebound; controls: wrong directory, bad Spawn shape |
| window actions | exactly `Super+M` and `Super+Shift+F` = `Fullscreen`, `Super+Alt+A` = `Maximize`, `Super+Shift+C` = `Close`, `Super+Shift+M` = `Minimize`, each `{ __type = "enum"; variant = ...; }` with no value and a description; identical with vicinae off, alternate constants and extras |
| window keys | none shared with a Spawn bind; an extra bind on `Shift+Super+c` is detected as a duplicate across Spawn and window binds |
| window controls | missing bind, unexpected non-Spawn bind, wrong variant, action with a value, missing description are each flagged |

### Constants
| Check | Expected |
|-------|----------|
| alt constants reach the binds | unique and equal to the alt-derived set |
| variation applied | the twin constants are really kitty/firefox/code/yazi |
| terminalApps wrapper flips | defaults wrap the editor not the fileManager; alt wraps the fileManager not the editor (fixture asserted to have that shape) |
| control: command sets differ | default and alt command sets are not equal |
| control: default prediction vs alt binds | flagged |

### Vicinae
| Check | Expected |
|-------|----------|
| enabled | `Super+A`, `Super+V`, `Super+period` present |
| disabled | set equals the prediction without vicinae and unique |
| disabled: no vicinae command | no command starting with `vicinae` |
| control: enabled prediction vs disabled binds | flagged |
| control: disabled prediction vs enabled binds | flagged |

### KDE parity
| Check | Expected |
|-------|----------|
| defaults / alt constants / vicinae disabled | the seven shared KDE binds, mapped, equal the COSMIC set exactly |
| KDE side complete | seven shared KDE binds found (defaults) |
| control: changed KDE command | flagged |
| control: KDE bind missing on COSMIC side | flagged |
| control: extra KDE-only key | flagged |
| control: dot to period mapping skipped | flagged |

### extraBinds
| Check | Expected |
|-------|----------|
| included, clean set | built-ins plus extras, unique, equal to prediction |
| arguments survive | quoted command is one Spawn string, unchanged |
| modifier order | `Shift+Super+Y` present as `shift+super+y` |
| collision with a built-in | uniqueness reports exactly `super+b` |
| two extras colliding (different modifier order) | uniqueness reports exactly `shift+super+z` |
| control: clean sets | no duplicate reported |
| control: extras left out of prediction | flagged |
| control: synthetic duplicate / case-variant duplicate | flagged |
| control: synthetic list missing a built-in / with an unpredicted extra | flagged |
| control: non-Spawn action | flagged by the Spawn shape check |

### Final form
| Check | Expected |
|-------|----------|
| configFile entries == shortcuts (defaults, extras) | `CosmicSettings.Shortcuts` `entries.custom.value` holds the same normalised key -> action pairs, `Disable` shadows included |
| control: truncated entry list | differs from the shortcuts |

### Unchanged by the new module
| Check | Expected |
|-------|----------|
| cosmic-tk-fonts (cosmic + stylix) | present, font files carry the stylix fonts |
| cosmic on, stylix off | no `cosmic-tk-fonts` |
| cosmic off, stylix on | no `cosmic-tk-fonts` |
| control: font check on a cosmic-off twin | reports the missing package |
| `XDG_SCREENSHOTS_DIR` | equals `constants.screenshots` with cosmic on |
| `COSMIC_DATA_CONTROL_ENABLED` | `1` with cosmic on |
| control: cosmic off | neither session variable set, no shortcuts generated even with `extraBinds` declared |
| idle (`cosmic-idle.nix`) | `screen_off_time` = hypridle `screenOffTimeout` * 1000 as an optional, `suspend_on_ac_time` and `suspend_on_battery_time` = optional null (None) |
| control: cosmic off | no idle config |

## Monitor layout (`02-scenario-cosmic-monitors.nix`)

`check-nixos-cosmic-binds.sh` runs `01-scenario-cosmic-binds.nix` and `02-scenario-cosmic-monitors.nix` in turn (same `results` shape) and needs at least 80 checks in total. The second scenario covers the `programs.cosmic.monitors` option and `cosmic-monitors.nix`, which turns it into a plan file (`~/.config/cosmic-monitors/plan`, one `cosmic-randr` argument line per output) and a user oneshot service that applies it inside a COSMIC session; it also reads the two real hosts' declared monitor values.

The scenario exposes `results` (`label -> "ok" | "FAIL: ..."`, each check wrapped in `tryEval`).

- The predicted plan is an independent reimplementation inside the test: rotation 0/90/180/270 maps to `normal`/`rotate90`/`rotate180`/`rotate270`, a disabled output to `disable <name>`, the `"*"` fallback to nothing, numbers rendered through JSON (`1.5`, `240`, `143.999`, floats with an integral value without a fraction). It is compared with the generated plan text as an exact line set (missing, unexpected, count, sorted equality, trailing newline).
- Assertions are read from `config.assertions` of twins; each bad twin must fail exactly the matching `programs.cosmic.monitors:` message, valid twins none.
- The service is read from the home-manager config (`systemd.user.services.cosmic-monitors`); the plan from `xdg.configFile."cosmic-monitors/plan"`.
- The real hosts are read from `nixosConfigurations.nixos-desktop` / `nixos-laptop`: the declared `myconfig.programs.cosmic.monitors` values, and for the desktop the generated plan and service.

Twins: mixed list (two enabled, one rotated, one disabled, fallback), fallback only, awkward numbers (143.999 refresh, 59.94, scale 1.25 and 2.0, negative positions, rotations 180 and 270), only disabled outputs, cosmic off with monitors declared, and the bad twins (duplicate name, two fallbacks, zero width, missing height, zero refresh, scale 0, shell metacharacters, space in a name, a lone disabled output without a mode).

### Monitors: Plan text
| Check | Expected |
|-------|----------|
| mixed twin | generated lines equal the prediction exactly |
| prediction spelled out | the prediction is the three expected lines |
| fallback | no plan line mentions `*` |
| awkward numbers | non-integer refresh, negative positions, rotations 180/270, float scale match |
| 143.999 | exact line present, not rounded |
| only disabled outputs | only `disable` lines |
| only fallback | no plan file, no service |
| control: wrong refresh / wrong rotation / missing disable line / extra line / plan expected but absent | each flagged |

### Monitors: Assertions
| Check | Expected |
|-------|----------|
| valid twins | no `programs.cosmic.monitors:` assertion fails |
| duplicate names | `unique` assertion fails (exactly one) |
| two `"*"` | `at most one` assertion fails |
| missing width / height / refresh | the width, height and refresh assertion fails (exactly one) |
| scale 0 | the scale assertion fails (exactly one) |
| shell metacharacters / space in a name | the name-character assertion fails (exactly one) |
| lone disabled output | needs no mode values |
| control: reader | silent on a valid twin, reports a bad one |

### Monitors: Service
| Check | Expected |
|-------|----------|
| mixed twin | oneshot, `RemainAfterExit`, `ExecCondition` is the is-cosmic-session script, WantedBy/PartOf/After `graphical-session.target` |
| only disabled outputs | service still defined |
| cosmic off, monitors declared | no service, no plan file |
| control: fallback-only twin | the service checker reports it |

### Monitors: Real hosts
| Check | Expected |
|-------|----------|
| desktop DP-1 / DP-2 / HDMI-A-1 | 3840x2160@240 scale 1.5 at 1440,560 unrotated / 3840x2160@144 scale 1.5 at 0,0 rotated 90 / disabled |
| desktop fallback | one `"*"` entry, four entries |
| desktop plan | the three expected lines; equals the prediction from its own monitors |
| desktop service, assertions | service defined, no monitors assertion fails |
| laptop eDP-1 | 3200x2000@120 scale 1.0 at 0,0 |
| laptop fallback, plan | one `"*"` entry, two entries; predicted plan is the single eDP-1 line |
| output names | every declared name matches the name rule |
| control: expectation helper | flags a wrong value and a missing output |
