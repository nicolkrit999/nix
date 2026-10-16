# test-ibus-autostart-hidden

Guards the fix for the "IBus Notification: IBus should be called from the desktop session in Wayland" popup on login in non-GNOME Wayland sessions.

Why: nixpkgs' GNOME module implicitly enables ibus (`i18n.inputMethod` `enable`/`type` as `mkDefault`), which ships the system XDG autostart entry `ibus-daemon.desktop` (`NotShowIn=GNOME;KDE;`). systemd's xdg-autostart-generator starts it under uwsm and its panel pops the warning on every login. `modules/nixos/toplevel/gnome.nix` therefore defines a user-level `~/.config/autostart/ibus-daemon.desktop` with `Hidden=true`; the XDG autostart spec lets a same-named user file override the system one. A different file name would not override anything (the bug class of the removed `kde-ibus-kill.desktop`), and the old `pkill ibus-daemon` in the Hyprland startup never worked (it ran before the uwsm autostart).

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-ibus-autostart-hidden` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-ibus-autostart-hidden/check-nixos-ibus-autostart-hidden.sh
```

From inside the directory:

```bash
bash check-nixos-ibus-autostart-hidden.sh
```

Eval only, no builds. Runs in the `nixos-b` CI group with a 5 minute cap (`test.conf`).

## How it works

`01-scenario-ibus-autostart-hidden.nix` reads the real `nixosConfigurations.nixos-desktop` and `nixos-laptop` (base plus every specialisation) and exposes `label<TAB>result` lines (`ok` or `FAIL: ...`) as `report` and `control`. Which variants enable GNOME is not asserted; the checks only follow the contract: wherever GNOME is on, the override must exist. The positive checks need at least one GNOME variant per host, otherwise they would be vacuous and the test fails.

`control` builds twins of the desktop's GNOME specialisation through `extendModules` with ibus disabled (`enable = false`), with another input method type (`fcitx5`), and with GNOME forced off (`myconfig.programs.gnome.enable = false`) while ibus is forced on; none may define the override. The GNOME-off twin first asserts its own premises (GNOME off, ibus on) so it cannot pass vacuously. The `Hidden=true` parser is also fed planted wrong texts that it must reject.

The check script additionally greps the Hyprland, KDE and GNOME module sources (this repo's other source-pattern checks do the same) for `pkill`/`killall` of ibus and `kde-ibus-kill`, with a planted line proving the regex matches.

## Checks

Per host variant with GNOME enabled:

| Check | Expected |
|-------|----------|
| ibus is on under GNOME | `i18n.inputMethod.enable` and `type == "ibus"` (premise of the override) |
| override file exists | `home-manager.users.<user>.xdg.configFile."autostart/ibus-daemon.desktop"` is defined |
| override has Hidden=true | text has the `[Desktop Entry]` header and a `Hidden=true` line, no `Hidden=false` |
| only the exact ibus-daemon.desktop name is defined | the only configFile name containing `ibus` is `autostart/ibus-daemon.desktop` |

Per host variant (any):

| Check | Expected |
|-------|----------|
| no kde-ibus-kill autostart | no configFile name contains `kde-ibus-kill` |
| override only with GNOME and ibus | the override exists exactly when GNOME and ibus are both on |

Per host:

| Check | Expected |
|-------|----------|
| at least one GNOME variant evaluated | non-vacuity of the positive checks |

Controls and source guards:

| Check | Expected |
|-------|----------|
| control: ibus disabled drops the override | GNOME specialisation twin with `i18n.inputMethod.enable = false`: file absent |
| control: non-ibus input method drops the override | twin with `type = "fcitx5"`: file absent |
| control: GNOME forced off (ibus forced on) drops the override | twin with `myconfig.programs.gnome.enable = false` and ibus forced on: premises hold (GNOME off, ibus on) and file absent |
| control: Hidden=false text is rejected | parser rejects planted `Hidden=false` |
| control: text without Hidden is rejected | parser rejects a text with no `Hidden` line |
| hyprland-main.nix has no ibus kill | no `pkill`/`killall` of ibus, no `kde-ibus-kill` |
| kde-main.nix has no ibus kill or kde-ibus-kill autostart | same patterns absent |
| gnome.nix has no ibus kill | same patterns absent |
| control: planted pkill ibus-daemon is detected | the guard regex matches a planted line |
