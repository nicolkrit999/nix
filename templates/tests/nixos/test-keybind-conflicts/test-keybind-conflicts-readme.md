# test-keybind-conflicts

Verifies that the per-compositor keybinding modules (Hyprland, Niri, GNOME, KDE) render collision-free, well-formed binds on the real hosts.

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

`01-scenario-keybind-conflicts.nix` evaluates the real flake (`nixosConfigurations.nixos-desktop` / `nixos-laptop`) plus every specialisation of each, and for every variant where a desktop module is enabled reads the final home-manager values. Bind strings are normalised (lowercased, modifiers sorted, `Mod`/`Meta`/`Win` aliased to `super`) before comparing, so reordered or differently-cased duplicates are caught. Checks are exposed as `"ok"` / `"FAIL: ..."` strings under `results`; `control` holds matcher self-tests on synthetic inputs, and `gnome-scripts` holds the rendered GNOME screenshot script text.

`check-nixos-keybind-conflicts.sh` runs `nix eval --json --impure` on each attribute, prints a per-check PASS/FAIL list and `bash -n`s the screenshot script. It exits non-zero on any failure. Eval-only apart from building the small screenshot script; about 10-20 s warm.

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

### Niri (per variant with niri enabled)
| Check | Expected |
|-------|----------|
| `niri-binds-present` | more than 50 binds |
| `niri-binds-unique` | no two bind names collide after normalisation |
| `niri-spawn-nonempty-strings` | every `action.spawn` is a non-empty list of non-empty strings |

### GNOME (per variant with gnome enabled)
| Check | Expected |
|-------|----------|
| `gnome-custom-entries-present` | at least one `custom<i>` entry |
| `gnome-custom-list-matches-entries` | `custom-keybindings` list equals the set of `custom<i>` entries |
| `gnome-entries-complete` | each entry has non-empty name, command, binding |
| `gnome-custom-bindings-unique` | custom binding strings unique |
| `gnome-all-bindings-unique` | custom bindings do not collide with wm/shell keybindings, screensaver or logout |
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

### Controls
| Check | Expected |
|-------|----------|
| `hypr-detects-order-and-case` / `hypr-distinguishes-different-mods` | normaliser flags reordered duplicates, not distinct binds |
| `niri-detects-mod-alias` | `Mod+Shift+A` and `Super+SHIFT+a` collide |
| `gnome-detects-order-and-case` / `gnome-distinguishes-plain-key` | same for GNOME `<Super>` syntax |
| `kde-detects-hotkey-vs-shortcut` | case-variant hotkey/shortcut collision is found |
| `dups-ignores-unique` | duplicate helper returns only real duplicates |
| `bash -n rejects broken script` | the syntax check can fail |
