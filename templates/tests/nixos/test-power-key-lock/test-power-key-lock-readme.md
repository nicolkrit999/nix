# test-power-key-lock

Tests the power-button lock feature: `services.powerKeyLock` (`modules/nixos/services/power/power-key-lock.nix`) and the per-session overrides that keep the compositor/desktop from handling the power key itself:

- logind: `HandlePowerKey = "lock"` and `HandlePowerKeyLongPress = "poweroff"` whenever any of the six sessions (hyprland, niri, mango, gnome, kde, cosmic) is enabled and the option is on.
- niri: `power-key-handling.enable = false` (`niri-main.nix`).
- GNOME: `power-button-action = "nothing"` plus a custom keybinding `XF86PowerOff` running `loginctl lock-session` (`gnome-binds.nix`).
- KDE: powerdevil `powerButtonAction = lockScreen` on AC, battery and lowBattery (`kde-kscreenlocker.nix`).
- COSMIC: shortcut `XF86PowerOff` = `System(LockScreen)` (`cosmic-binds.nix`).
- Hyprland and Mango need no override: logind emits the Lock signal and the hypridle `lock_cmd` reacts to it.

Not covered: the live behaviour of the power key (needs a real session), and which sessions a real host enables.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-power-key-lock`.

From repo root:

```bash
bash templates/tests/nixos/test-power-key-lock/check-nixos-power-key-lock-eval.sh
```

From inside the directory:

```bash
bash check-nixos-power-key-lock-eval.sh
```

Runtime: about 50 s local warm (eval only), CI group `heavy-a` with cap 4 (`test.conf`).

## How it works

`shared/host-power-key-lock.nix` is a fake host `power-key-host` built from scratch (user `krit` via `constants.user`, the convention of `test-coffee`) with hyprland, niri and mango off. It loads only: home-manager, the constants modules, the real toplevels of hyprland, niri and mango, the real `niri-main.nix`, `gnome-binds.nix`, `kde-kscreenlocker.nix`, `cosmic-binds.nix`, `hypridle.nix` and `power-key-lock.nix`. Each check evaluates an `extendModules` twin of that host with exactly one session forced on (`mkOverride 10`), with or without `services.powerKeyLock.enable = false`.

**Fixture simplification (explicit):** GNOME, KDE and COSMIC are NOT loaded as full desktops. Their toplevel modules (plasma6, cosmic, gnome `services.desktopManager.*`) and their `*-main.nix` files are not part of the fixture; `shared/nixos-extra-x86_64/option-sinks.nix` declares `myconfig.programs.{gnome,kde,cosmic}.enable` and the few option fields the loaded override files read (`extraBinds`, `wmKeybindings`, `disabledDefaults`) as plain options. The override files themselves are the real ones, and the real home-manager modules they write to (home-manager `dconf`, plasma-manager `programs.plasma.powerdevil`, cosmic-manager `wayland.desktopManager.cosmic`) are loaded from the flake inputs, so a wrong option path or value still fails. The niri and stylix stubs reproduce `niri.nix`'s own `niri-stylix-off-enable-stub` (same module key) because that stub is only added when niri is enabled.

Specific points:

- KDE: plasma-manager's `powerButtonAction` has an `apply` that turns `lockScreen` into the number 32, so the check compares the applied value `32`. `programs.plasma.enable` is not set (kde-main is not loaded), so `powerdevilrc` is not rendered.
- COSMIC: only assertions mentioning `programs.cosmic` are evaluated (fixture-level assertions such as the missing root file system are expected and ignored). A `disabledDefaults = [ "XF86PowerOff" ]` twin must trip the clash assertion while the option is on and not when it is off.
- `no session enabled` / `option disabled` twins prove that the logind keys depend on both conditions.

## Checks

### contract (31)

| Check | Expected |
|-------|----------|
| option `services.powerKeyLock.enable` defaults to false | default and fixture host value false |
| `default (option off) with a session enabled: no HandlePowerKey settings` | no logind power keys |
| `real hosts: laptop enables powerKeyLock, desktop does not` | laptop true, desktop false |
| `<session> only: logind HandlePowerKey=lock, LongPress=poweroff` (hyprland, niri, mango, gnome, kde, cosmic: 6 rows) | exactly those two `HandlePowerKey*` keys |
| `no session enabled: no HandlePowerKey settings` | no `HandlePowerKey*` key |
| `option disabled (<session> on): no HandlePowerKey settings` (6 rows) | no `HandlePowerKey*` key |
| `hyprland` / `niri` / `mango: hypridle lock_cmd exists` (3 rows) | hypridle enabled and its config has `lock_cmd` |
| `gnome only: no hypridle lock_cmd` | hypridle not configured (it is for the three WMs) |
| `niri on: compositor power-key handling disabled` | `power-key-handling.enable == false` |
| `niri on, option off: ... stays true` | `power-key-handling.enable == true` |
| `gnome on: power-button-action = nothing` | dconf power plugin key is `nothing` |
| `gnome on: custom keybinding XF86PowerOff runs loginctl lock-session` | exactly one such binding with that command |
| `gnome on, option off: no power-button-action and no XF86PowerOff binding` | power plugin empty, no binding |
| `gnome on, option off: the other custom keybindings are still generated` | binding count off > 0 and on = off + 1 |
| `kde on: powerdevil powerButtonAction applied value 32 ...` | 32 on AC, battery, lowBattery |
| `kde on, option off: no powerButtonAction set` | null on all three profiles |
| `cosmic on: shortcut XF86PowerOff is System(LockScreen)` | exactly one such shortcut |
| `cosmic on, option off: no XF86PowerOff shortcut` | none |
| `cosmic on: no failed programs.cosmic assertion` | none |
| `cosmic: disabledDefaults = XF86PowerOff trips the clash assertion while the lock bind is on` | one clash message |
| `cosmic: the same disabledDefaults entry is fine when the option is off` | no clash message |

### scenario controls (7)

| Check | Expected |
|-------|----------|
| `logindSet rejects an unset host` | the predicate fails on the no-session host |
| `logindUnset rejects a host with the keys` | the predicate fails on a locked host |
| `niri` / `gnome` / `kde` / `cosmic twin differs between option on and off` (4 rows) | on and off values differ, so the on/off checks are not vacuous |
| `lockVariant rejects a plain Spawn action` | the COSMIC predicate does not accept a non-lock action |
