# test-keybind-conflicts

Verifies that the per-compositor keybinding modules (Hyprland, Niri, GNOME, KDE, COSMIC, plus the mango waybar binds) render collision-free, well-formed binds on the real hosts, that every niri bind names a real action and that the waybar toggle binds hit the running bar.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-keybind-conflicts` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-keybind-conflicts/check-nixos-keybind-conflicts.sh
```

Or from inside the directory:

```bash
bash check-nixos-keybind-conflicts.sh
```

## How it works

`01-scenario-keybind-conflicts.nix` evaluates the real flake (`nixosConfigurations.nixos-desktop` / `nixos-laptop`) plus every specialisation of each, and for every variant where a desktop module is enabled reads the final home-manager values. Bind strings are normalised (lowercased, modifiers sorted, `Mod`/`Meta`/`Win` aliased to `super`) before comparing, so reordered or differently-cased duplicates are caught. Checks are exposed as `"ok"` / `"FAIL: ..."` strings under `results`; `control` holds matcher self-tests on synthetic inputs (the niri/mango/Hyprland mutation controls use small literal bind sets, only the niri action lists are parsed from the real niri package source), and `gnome-scripts` holds the GNOME screenshot script text, taken from the `.drv` (its `__json` `text` field, context kept) so the script is never built or realised.

The niri action lists are parsed at test time from the source of the niri package the host actually uses (`programs.niri.package.src`): `niri-config/src/binds.rs` `enum Action` minus the `#[knuffel(skip)]` variants is what a `config.kdl` bind node may name (IPC-only actions like `load-config-file` are skipped there and rejected by `niri validate`), `niri-ipc/src/lib.rs` `enum Action` is what `niri msg action X` accepts. Names are converted from CamelCase to kebab-case. Nothing is hardcoded except the contract itself (the 8 `allow-when-locked` keys).

`check-nixos-keybind-conflicts.sh` runs `nix eval --json --impure` on each attribute, prints a per-check PASS/FAIL list and `bash -n`s the screenshot script. It exits non-zero on any failure. Eval-only (the screenshot script is read from its `.drv`, never built); about 10-20 s warm.

## Checks

### Hyprland (per variant with hyprland enabled)
| Check | Expected |
|-------|----------|
| `hyprland-binds-present` | more than 50 binds |
| `hyprland-binds-shape` | every bind has a key and an `hl.dsp.*` dispatcher |
| `hyprland-binds-unique` | no duplicate normalised (mods, key) |
| `hyprland-ws-focus-1-to-0` | `SUPER+N` exists once and targets workspace N (key 0 targets 10) |
| `hyprland-ws-move-1-to-0` | `SUPER+SHIFT+N` moves to workspace N (0 is 10) |
| `hyprland-ws-follow-1-to-0` | `SUPER+ALT+N` moves to workspace N (0 is 10) |
| `hyprland-waybar-toggle-bind` / `hyprland-waybar-reload-bind` | `SUPER+SHIFT+W` / `SUPER+ALT+W` run `pkill -SIGUSR1` / `-SIGUSR2 waybar` with no `-x` (the process is `.waybar-wrapped`) |

### Niri (per variant with niri enabled)
| Check | Expected |
|-------|----------|
| `niri-binds-present` | more than 50 binds |
| `niri-binds-unique` | no two bind names collide after normalisation |
| `niri-spawn-nonempty-strings` | every `action.spawn` is a non-empty list of non-empty strings |
| `niri-bind-actions-bindable` | every bind's action node is a variant niri accepts in `config.kdl` (derived from the niri source, see above) |
| `niri-msg-actions-exist` | every `niri msg action X` in a spawn bind, `spawn-sh` or `spawn-at-startup` command names an action in the niri IPC enum |
| `niri-reload-bind-is-load-config-file` | `Mod+Shift+R` exists and reloads via `load-config-file`, never `reload-config` |
| `niri-media-keys-allow-when-locked` | exactly volume up/down/mute, mic mute, monitor and keyboard brightness up/down have `allow-when-locked = true`; playback keys and `Mod+Delete` exist and do not |

### Mango (per variant with mango enabled)
| Check | Expected |
|-------|----------|
| `mango-waybar-toggle-bind` / `mango-waybar-reload-bind` | `SUPER+SHIFT,W` / `SUPER+ALT,W` are exactly one spawn of `pkill -SIGUSR1` / `-SIGUSR2 waybar`, no `-x` |

### GNOME (per variant with gnome enabled)
| Check | Expected |
|-------|----------|
| `gnome-custom-entries-present` | at least one `custom<i>` entry |
| `gnome-custom-list-matches-entries` | `custom-keybindings` list equals the set of `custom<i>` entries |
| `gnome-entries-complete` | each entry has non-empty name, command, binding |
| `gnome-custom-bindings-unique` | custom binding strings unique |
| `gnome-all-bindings-unique` | custom bindings do not collide with wm/shell keybindings, screensaver or logout |
| `gnome-wm-keybindings-merged` | `org/gnome/desktop/wm/keybindings` `close` contains the module's `<Super><Shift>c` plus every host-declared `programs.gnome.wmKeybindings.close` entry, and every other declared key is rendered unchanged |
| `gnome-minimize-maximize-mapped` | on hosts whose `wmKeybindings` declares `minimize`: every declared `minimize` key is in rendered `minimize` and not in `close`; `toggle-maximized` holds `<Super>m`; `close` keeps `<Super><Shift>c` (hosts without the map skip it) |
| `gnome-message-tray-frees-super-m` | `org/gnome/shell/keybindings` `toggle-message-tray` does not contain `<Super>m` |
| `gnome-native-screenshot-key-freed` | `media-keys.screenshot == []` |
| `gnome-native-screenshot-custom-print` | a custom `Print` binding exists |
| `bash -n launch-screenshot` | rendered screenshot script parses |

### KDE (per variant with kde enabled)
| Check | Expected |
|-------|----------|
| `kde-hotkeys-present` | more than 5 hotkeys |
| `kde-hotkeys-all-have-key` | each hotkey command has a key |
| `kde-hotkeys-unique` | hotkey keys unique after normalisation |
| `kde-hotkeys-vs-shortcuts` | no hotkey key equals a non-`none` `plasma.shortcuts` value |

### COSMIC (per variant with cosmic enabled)
| Check | Expected |
|-------|----------|
| `cosmic-shadows-only-defaults` | every `Disable` entry is a bare `{ __type = "enum"; variant = "Disable"; }` without description on one of the five shadow keys (`Super+Escape`, `Super+Shift+Escape`, `Super+q`, `Super+F11`, `Super+t`) |
| `cosmic-shadows-unique-and-separate` | the `Disable` shadows are unique and collide with no active bind |
| `cosmic-binds-present` | more than 3 active (non-`Disable`) shortcuts |
| `cosmic-binds-unique` | active keys unique after normalisation (lowercased, modifiers sorted) |
| `cosmic-binds-spawn-shape` | every action is an enum `Spawn` with exactly one non-empty command string, a plain value-less `Close`/`Minimize`/`Fullscreen`/`Maximize` window action, or a `System` action wrapping exactly one value-less `LockScreen`/`LogOut` enum |

### Controls
| Check | Expected |
|-------|----------|
| `hypr-detects-order-and-case` / `hypr-distinguishes-different-mods` | normaliser flags reordered duplicates, not distinct binds |
| `niri-detects-mod-alias` | `Mod+Shift+A` and `Super+SHIFT+a` collide |
| `gnome-detects-order-and-case` / `gnome-distinguishes-plain-key` | same for GNOME `<Super>` syntax |
| `kde-detects-hotkey-vs-shortcut` | case-variant hotkey/shortcut collision is found |
| `niri-action-lists-parsed` | parsed lists contain `close-window`/`spawn`, IPC list has `load-config-file` and `focus-column-first`, bindable list lacks `load-config-file`, nobody has `reload-config` |
| `niri-synthetic-baseline-passes` | the synthetic niri bind set (8 locked media keys, playback keys, `Mod+Delete`, `Mod+Shift+R` = `load-config-file`) passes every mutated check, so the mutations below start clean |
| `waybar-synthetic-baseline-passes` | the synthetic mango and Hyprland waybar binds pass both waybar checks |
| `niri-mutation-reload-config-spawn-fails` | synthetic binds with `Mod+Shift+R` = `niri msg action reload-config`: `niri-msg-actions-exist` and the reload check fail |
| `niri-mutation-load-config-file-spawn-passes` | same bind as `niri msg action load-config-file`: all three pass (acceptance) |
| `niri-mutation-bare-ipc-action-node-fails` / `niri-mutation-unknown-action-node-fails` | action node `load-config-file` / `reload-config` fails `niri-bind-actions-bindable` |
| `niri-mutation-startup-bogus-action-fails` | a `niri msg action no-such-action` in `spawn-at-startup` is flagged |
| `niri-mutation-unlocked-media-key-fails` / `-locked-playback-key-fails` / `-missing-media-key-fails` | removing `allow-when-locked` from a media key, adding it to a playback key, or dropping a playback key fails the media-key check |
| `waybar-cmd-matcher` | accepts `pkill -SIGUSR1 waybar`; rejects `-x`, `-fx`, `--exact`, `.waybar-wrapped`, `killall`, wrong signal |
| `waybar-mutation-mango-x-flag-fails` / `-mango-missing-bind-fails` / `-hyprland-x-flag-fails` | synthetic mango/Hyprland binds mutated with `-x` or a removed bind fail the matching waybar check, the untouched sibling bind stays ok |
| `cosmic-synthetic-baseline-passes` | the synthetic COSMIC bind set (including a command with arguments and the three window actions) passes all COSMIC checks (it includes the Super+M/Super+Alt+A window binds and two `Disable` shadows) |
| `cosmic-mutation-duplicate-key-fails` / `-reordered-modifier-duplicate-fails` | a case-variant or modifier-reordered duplicate key fails `cosmic-binds-unique` |
| `cosmic-mutation-non-spawn-fails` / `-two-command-spawn-fails` | a non-`Spawn` action (`Terminate`) or a `Spawn` with two strings fails the shape check (uniqueness stays ok for the first) |
| `cosmic-mutation-system-wrong-variant-fails` | a `System` action with another variant (`PowerOff`) fails the shape check |
| `cosmic-mutation-system-flat-fails` | a `System` action without its nested value fails the shape check |
| `cosmic-mutation-window-action-with-value-fails` | a `Close` action carrying a value fails the shape check |
| `cosmic-mutation-disable-on-active-key-fails` | a `Disable` on an active bind key fails both shadow checks |
| `cosmic-mutation-disable-unknown-key-fails` / `-disable-with-description-fails` | a `Disable` outside the shadow set, or one carrying a description, fails `cosmic-shadows-only-defaults` |
| `cosmic-mutation-empty-list-fails` | an empty bind list fails `cosmic-binds-present` |
| `dups-ignores-unique` | duplicate helper returns only real duplicates |
| `bash -n rejects broken script` | the syntax check can fail |
