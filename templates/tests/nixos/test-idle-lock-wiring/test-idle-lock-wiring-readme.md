# test-idle-lock-wiring

Wiring contract for the idle/lock chain of the REAL `nixos-desktop` and `nixos-laptop` configurations: the generated hypridle listeners and their nix-busy guard, the hyprlock PAM service, swaync versus a shell's notifications, and the SDDM theme modules. The coffee linger directory in the impermanence persist list is checked on a minimal fixture host (coffee + impermanence only), not on the real hosts. It does not test which WMs, shells or SDDM theme a host picks.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-idle-lock-wiring` (name as shown by `--list`); the direct commands are below.

From the repo root:

```bash
bash templates/tests/nixos/test-idle-lock-wiring/check-nixos-idle-lock-wiring.sh
```

Or from inside the directory:

```bash
bash check-nixos-idle-lock-wiring.sh
```

Needs `nix`, `jq`, `bash`. Eval plus one tiny build (the `nix-busy` script is read at eval time); about 25 s per host.

## How it works

`01-scenario-idle-lock-wiring.nix` takes `{ host }`, loads `flake.nixosConfigurations.<host>` via `builtins.getFlake` (`FLAKE_ROOT` is exported by the runner) and exposes `results`, an attrset of `label -> "ok" | "FAIL: ..."`. Every property is a function from a config to a list of problems; the real config must give `[]`. A `control(...)` check applies the SAME function to a broken `extendModules` twin (or a literal bad input) and passes only when a problem is reported. `02-scenario-coffee-linger.nix` takes no host: it builds `template-host-minimal` through `lib/fixture-host.nix` with only coffee and impermanence forced on. `check-nixos-idle-lock-wiring.sh` runs the first scenario per host and the second once, and refuses to pass with fewer than 33 checks (14 per host x 2 + 5). Results go through `builtins.tryEval`, which turns a module-system throw (e.g. conflicting `mkForce` definitions in a twin) into `FAIL: eval error`; for such a check the script re-evaluates that one check without `tryEval` and prints the `error:` lines and their `at` locations.

Busy guard: each hypridle `on-timeout` has the form `<store>-nix-busy && exit 0; <command>`. When nix is busy the guard exits 0 and the command is skipped; otherwise `pgrep` fails and the command runs. The test pins that shape (`&&`, then `;`, a real command after it) and reads the `nix-busy` script body at eval time: it must contain `pgrep` for nix build / nixos-rebuild and must not swallow the status (`|| true`, `exit N`, `set -e`), because that would make the guard skip every on-timeout or none. This is the nearest eval-only stand-in for "on-timeout runs when not busy"; a real idle run (a compositor, hypridle and a busy nix process) is NOT covered.

Linger: `coffee-on` enables linger at runtime, which writes `/var/lib/systemd/linger`. A host with coffee and impermanence (the fixture) must either persist that directory or `coffee-on.sh` must handle a stale `linger-by-coffee` marker (the marker survives while linger itself is lost on reboot). The text is read from the flake source, so staged files only.

SDDM: the exclusivity check is split from the wiring check because enabling both theme modules also makes the two `theme` definitions collide at eval time; the exclusivity control only reads the assertion list.

## Checks

### Both real hosts
| Check | Expected |
|-------|----------|
| hypridle listeners | exactly 3 listeners; each `on-timeout` is `<nix-busy> && exit 0; <cmd>` with one shared guard script and a non-`exit` command; dim uses brightnessctl, lock runs `loginctl lock-session`, screen-off switches dpms off; no `on-resume` behind the guard; timeouts equal the hypridle options and strictly increase; `before_sleep_cmd` is `loginctl lock-session`; `lock_cmd` is a `universal-lock` package in `home.packages`; every `on-timeout` appears in the generated `hypridle.conf` |
| busy guard body | contains `pgrep`, matches nix build and nixos-rebuild, has no `\|\| true`, explicit `exit` or `set -e` |
| hyprlock | `security.pam.services.hyprlock` present with a WM enabled, absent with all WMs off |
| swaync | Hyprland-only twin: `services.swaync.enable` true without a shell, false with noctalia active on Hyprland |
| sddm | exactly one of sddm-pixie / sddm-astronaut enabled, sddm on, theme matches the active module, `/var/lib/sddm` persisted, no failed assertion |

### Coffee linger fixture
| Check | Expected |
|-------|----------|
| coffee linger | `/var/lib/systemd/linger` is persisted, or `coffee-on.sh` has the stale-marker branch |

### Controls (must be flagged)
| Control | Expected |
|---------|----------|
| unguarded listeners twin | hypridle check reports a problem |
| bodies with `\|\| true`, `exit 0`, no pgrep | busy-body check reports each |
| linger list emptied, stale text replaced | linger check reports; with the real `coffee-on.sh` text the emptied twin is accepted |
| impermanence off / coffee off fixture twin (`mkOverride 10 false` over the fixture's `mkForce true`) | linger check reports the vacuity |
| WM-less twin vs WM-expected | hyprlock check reports |
| shell twin vs swaync-expected | swaync check reports |
| both / no sddm module | exclusivity check reports |
