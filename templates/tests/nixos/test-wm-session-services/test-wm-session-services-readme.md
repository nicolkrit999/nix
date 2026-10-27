# test-wm-session-services

Verifies the niri session wiring of a minimal niri-only fixture host, and of the real hosts and their specialisations wherever niri is enabled: exactly one polkit agent runs, nobody starts a second X server by hand, and `DISPLAY` is never hardcoded.

Why: niri-flake ships its own `niri-flake-polkit` user unit (polkit-kde agent) while `niri-main.nix` spawns polkit_gnome; both at once means two agents fighting for the session. niri also starts `xwayland-satellite` itself and exports `DISPLAY`; a manual satellite on `:1` or a hardcoded `DISPLAY=:1` breaks X clients and anything gated on `DISPLAY` (tmux autostart).

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-wm-session-services` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-wm-session-services/check-nixos-wm-session-services.sh
```

Or from inside the directory:

```bash
bash check-nixos-wm-session-services.sh
```

## How it works

`01-scenario-wm-session-services.nix` builds a fixture (`template-host-minimal` with only `myconfig.programs.niri.enable` forced on, via `lib/fixture-host.nix`), which is always checked. It also evaluates `nixosConfigurations.nixos-desktop` / `nixos-laptop` plus every specialisation as cross-file consistency (host overrides must not add a second agent or a hardcoded `DISPLAY`); real variants without niri are skipped and never throw. For each checked variant it collects: `spawn-at-startup` commands, niri `environment`, `xwayland-satellite` settings, the `niri-flake-polkit` unit's `enable`, other enabled polkit user units, enabled HM agent services (`polkit-gnome`, `hyprpolkitagent`) and any `DISPLAY` in HM/system session variables. The check functions are pure over that fact set, so `control` runs them on the fixture facts with one property broken at a time and requires the check to fail (plus a passing alternative: the niri-flake unit alone is a valid single agent). Which agent is chosen is not asserted, only that there is exactly one.

The check script prints a per-check PASS/FAIL list, fails when the `fixture-niri` variant is missing (everything would be vacuous), and is eval-only (about 1-2 min warm).

## Checks

### Per variant (`fixture-niri` always, real hosts/specialisations when niri is enabled)
| Check | Expected |
|-------|----------|
| `niri-exactly-one-polkit-agent` | (niri-flake unit enabled) + other polkit user units + HM agent services + spawned agent commands == 1 |
| `niri-flake-polkit-unit-disabled-if-agent-spawned` | a spawned polkit agent and an enabled `niri-flake-polkit` unit never coexist |
| `niri-no-manual-xwayland-satellite` | no `spawn-at-startup` command mentions `xwayland-satellite` |
| `niri-builtin-xwayland-satellite-enabled` | `programs.niri.settings.xwayland-satellite.enable == true` |
| `niri-no-hardcoded-display-in-niri-env` | niri `environment` has no `DISPLAY` and no spawn passes `DISPLAY=` |
| `niri-no-hardcoded-display-in-session-vars` | `DISPLAY` is unset in `home.sessionVariables`, `environment.variables`, `environment.sessionVariables` |

### Controls (fixture facts with one property mutated)
| Check | Expected |
|-------|----------|
| `baseline-fixture-has-one-agent` | the unmutated facts pass the single-agent check |
| `polkit-two-agents-fails` / `polkit-unit-plus-spawn-pair-fails` | niri-flake unit enabled plus a spawned agent is flagged by both checks |
| `polkit-zero-agents-fails` | no agent at all is flagged |
| `polkit-unit-only-passes` | the niri-flake unit alone, nothing spawned, is accepted |
| `polkit-extra-hm-service-fails` / `polkit-extra-system-unit-fails` | a second agent via an HM service or another user unit is flagged |
| `xwayland-manual-spawn-fails` | a hand-spawned `xwayland-satellite` is flagged |
| `xwayland-builtin-disabled-fails` | disabling the built-in satellite is flagged |
| `display-in-niri-env-fails` / `display-in-spawn-fails` / `display-in-session-vars-fails` | `DISPLAY` set in the niri environment, passed as `DISPLAY=` in a spawn, or in a session-variable set is flagged |
