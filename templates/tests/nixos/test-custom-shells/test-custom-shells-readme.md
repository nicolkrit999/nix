# test-custom-shells

Unit tests for shell/waybar activation logic (caelestia, noctalia, waybar variants).

Why: shell ownership gates many consumer modules (swayosd, swaync, hypridle, hyprlock,
execOnce, packages). A regression does not fail the build; it silently starts two bars,
drops the idle/lock daemons, or leaves a dormant shell controlling a WM.

## How it works

Uses [nix-tests](https://github.com/danielefongo/nix-tests): each `_test.nix` file
evaluates a scenario host (built from `shared/eval-scenario.nix`) and asserts on the
resulting config (packages present, assertions firing, keybinds correct) without
building anything.

The Hyprland scenarios set one `wallpapers` entry (`shared/one-wallpaper.nix`) so the
`hyprland-wallpaperd` supervisor is present or suppressed depending on shell ownership.
With `wallpapers = [ ]` the supervisor never starts, so the check would be vacuous.

Each positive/dormant check is tied to one specific key (`H.hyprBind`, `H.mangoBinds`,
niri attr names) rather than "any bind matches". Dormant scenarios are compared by equality
against the matching no-shell positive scenario (swaync, binds, Hyprland startup block), and
shell-active Hyprland scenarios keep a control (no-shell) that proves the wallpaper supervisor
check can fail. Fake hosts enable only what a check needs: no-shell/dormant hosts do not enable
waybar or assert on hyprlock/waybar (those are host choices). `allAssertionsPass` covers
home-manager assertions only; system assertions are not evaluated in these minimal hosts.

## Run all tests

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-custom-shells` (name as shown by `--list`).

```bash
nix run github:danielefongo/nix-tests --inputs-from . --override-input nixpkgs nixpkgs -- templates/tests/nixos/test-custom-shells
```

Or from inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## Run a single test file manually

```bash
nix run github:danielefongo/nix-tests -- conflict/01-two-shells-on-hyprland_test.nix
```

## Test categories

| Prefix | What it checks |
|--------|---------------|
| `conflict/` | Assertions that must fire when two conflicting modules are both active |
| `positive/` | Valid combinations that must NOT fire any assertion |
| `dormant-flag/` | `enable = false` with `enableOnWM = true` — config must equal the no-shell scenario |
| `consumers/` | Consumer modules (swayosd, swaync, hypridle, hyprlock, execOnce, home.packages) gate correctly on shell ownership |

## Launcher bind (Shift+A) contract

`vicinae` is a stub option (`shared/vicinae-option.nix`, default true) so scenarios can switch it off; the real module is not loaded.

| Scenario | Expected |
|----------|----------|
| no shell (or dormant shell) on hyprland / niri / mango, vicinae on | `SUPER+SHIFT + A` / `Mod+Shift+A` / `SUPER+SHIFT,A` runs `vicinae toggle` (P03, P05, P07, D01-D04) |
| shell active | the shell's launcher IPC: `caelestiaqs ipc call drawers toggle launcher` (P01), `noctalia msg panel-toggle launcher` (P02, P04, P06); `SUPER + Delete` / `Mod+Delete` / `SUPER,Delete` run `caelestiaqs ipc call lock lock` / `noctalia msg session lock` |
| P08: no shell, vicinae disabled, hyprland | `SUPER+SHIFT + A` and `SUPER + A` are not bound; `SUPER + Delete` still is (control) |
| P08: no shell, vicinae disabled, mango | `SUPER+SHIFT,A` is exactly one bind to `true`; `SUPER,A` unbound; `SUPER,Delete` still bound (control) |
| P08: no shell, vicinae disabled, niri | `Mod+Shift+A` is `[ "true" ]`; `Mod+A`, `Mod+Period`, `Mod+V` unbound; `Mod+Delete` still bound (control); with vicinae on (P05 host) the same three binds exist and `Mod+Shift+A` is `vicinae toggle` (control) |

## consumers/ checks

`shared/eval-scenario.nix` additionally loads `swayosd.nix` and `hypridle.nix`. "execOnce" below means `hyprland.execOnce ++ hyprland.shellExecOnce` (shells autostart through `shellExecOnce`, which specs never `mkForce`).
Scenario hosts live in `consumers/NN-*/default.nix`; each `_test.nix` evaluates them.

| Check | Expected |
|-------|----------|
| C01 caelestia on hyprland | swayosd-server absent, swaync off, execOnce has `caelestiaqs` not `start-noctalia`, packages match |
| C02 noctalia on hyprland | swayosd-server absent, swaync off, execOnce has `start-noctalia` not `caelestiaqs`, `start-noctalia` packaged |
| C03 noctalia on niri / C04 on mango | swayosd-server absent, swaync off, `start-noctalia` packaged |
| C05 hyprland, no shell | swayosd-server present, swaync on with PartOf exactly `hyprland-session.target`, no shell launcher in execOnce or packages |
| C06 both shells dormant on hyprland | identical to C05 (dormant-flag regression) |
| C07 hyprland+niri+mango, noctalia only on niri | swayosd and swaync kept; swaync PartOf = hyprland + mango targets only; hypridle on |
| C08 no WM | swayosd-server absent, swaync, hypridle, hyprlock all disabled |
| C09 control (hyprland) | hypridle and hyprlock enabled, proving C08 can fail |
| C10 hypridle on hyprland only | `Install.WantedBy` is exactly `hyprland-session.target` (no `graphical-session.target`), `PartOf`/`After` equal it; no `on-timeout` contains an inline `pgrep -f`, all run the `nix-busy` script (control: the dpms timeout still contains `pgrep -x`); dim uses `brightnessctl -c backlight -s set` / `-r`; no `unlock_cmd` (control: `lock_cmd` set); `security.pam.services.hyprlock` exists |
| C11 hypridle on hyprland+niri+mango | same contract; `WantedBy` is exactly `hyprland-session.target`, `niri.service`, `mango-session.target` |
| C12 control (no WM) | `security.pam.services.hyprlock` absent, hypridle disabled |

The positive C01-C04 package/execOnce checks make the absence checks non-vacuous.

**Store independence:** the `stylix-hm.nix` stubs use the inline scheme `templates/tests/lib/scheme-catppuccin-mocha.nix` instead of reading the base16-schemes package. The harness evaluates read-only, so an IFD only works on a warm store (fresh CI legs failed with "base16-schemes ... .drv is not valid"); `run-test.py` runs harness commands with `allow-import-from-derivation = false` so a regression fails locally too.
