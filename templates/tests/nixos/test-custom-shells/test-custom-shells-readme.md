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

## consumers/ checks

`shared/eval-scenario.nix` additionally loads `swayosd.nix` and `hypridle.nix`.
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

The positive C01-C04 package/execOnce checks make the absence checks non-vacuous.
