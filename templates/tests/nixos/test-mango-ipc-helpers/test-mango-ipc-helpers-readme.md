# test-mango-ipc-helpers

Runs the real `mango-scratch`, `mango-place` and `mango-pip` scripts of the `nixos-desktop` host against a stub `mmsg`.

## Run

From repo root:

```bash
bash templates/tests/nixos/test-mango-ipc-helpers/check-nixos-mango-ipc-helpers.sh
```

From inside the directory:

```bash
bash check-nixos-mango-ipc-helpers.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo; by default it is derived from the script location.

## How it works

`01-scenario-mango-ipc-helpers.nix` reads `nixosConfigurations.nixos-desktop` (home-manager user `krit`), finds the `mango-scratch` bind, the `mango-place` `exec_once` line and the `mango-pip` bind, and exposes each script path and its `.drv`. The script builds the derivations, drops the `export PATH=` line and runs the scripts with a stub `mmsg` first in `PATH` (plus a short `sleep` stub), in a temp `XDG_RUNTIME_DIR`.

The stub serves the all-monitors, all-clients and focusing-client JSON using the field names of mango 0.18.0 `src/ipc/ipc.c` (`appid`, `is_global`, `is_unglobal`, `is_floating`, `is_visible`, 1-based `tags`, special tag `0`) and logs every `dispatch`. For `mango-pip` the stub keeps the focused client's floating/global state and flips it on `togglefloating` / `toggleglobal`.

## Checks

### mango-scratch
| Check | Expected |
|-------|----------|
| no clients | `toggle_special_tag` dispatched, command exec'd |
| visible window on tag 0 of the active monitor | no toggle, command exec'd |
| `is_global` / `is_unglobal` window on tag 0 | not counted: toggle dispatched |
| invisible window, window on another monitor, window on a normal tag | not counted: toggle dispatched |
| `mmsg get all-clients` fails | active defaults to 0: toggle dispatched, command exec'd |

### mango-place
| Check | Expected |
|-------|----------|
| start | `focusmon,DP-1` dispatched |
| new matching window on DP-1 | no `tagmon` |
| new matching window on DP-2 | `tagmon,DP-1,1 client,7` |
| matching window that existed before launch | ignored |
| new non-matching window | never moved |

### mango-pip
| Check | Expected |
|-------|----------|
| tiled window, pin | floating + global, `resizewin,800,450`, no marker |
| tiled window, unpin | not global, tiled again |
| floating window, pin | stays floating, becomes global, marker left |
| floating window, unpin | not global, still floating, no `togglefloating`, marker removed |
| no focused client | no dispatch |
