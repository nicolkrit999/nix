# test-wallpaperd-runtime

Runs `modules/nixos/programs/de-wm/wallpaperd/wallpaperd.sh` for all three backends (mango, hyprland, niri) against stub compositor and wallpaper tools, and asserts the runtime behaviour: fallback (`*`) semantics, hot-plug, unplug, mirrored/disabled skipping, still vs video dispatch and the single-instance lock, event-stream reconnect, crashed-`mpvpaper` restart and failed-start retry.

## Run

From repo root:

```bash
bash templates/tests/nixos/test-wallpaperd-runtime/check-nixos-wallpaperd-runtime.sh
```

From inside the directory:

```bash
bash check-nixos-wallpaperd-runtime.sh
```

`WPD_SCRIPT=<path>` points the check at an alternative copy of `wallpaperd.sh`.

## How it works

The check prepends `set -euo pipefail` to a copy of `wallpaperd.sh` (what `writeShellApplication` does) and runs it in the background with stubs first on `PATH`: `mmsg`, `wlr-randr` (mango), `hyprctl` and `socat` (hyprland), `niri` (niri), plus `mpvpaper` and `awww`. If `jq` or `flock` are missing it re-executes itself under `nix shell`.

- The output list is a TSV model rendered to each backend's JSON shape (`wlr-randr --json`, `hyprctl monitors -j`, `niri msg -j outputs`).
- The daemon is started with fd 8 closed (`8>&-`). The event stream is a FIFO the check holds open read-write on fd 8; writing one backend-specific line (`monitoradded>>x`, `{"WorkspacesChanged":{}}`, any mmsg line) triggers a reconcile.
- `mpvpaper` and `awww img` stubs append to a log (`mpv-start`, `mpv-stop`, `img`, `fd9-leak`); assertions grep that log. Stubs flag an inherited lock fd 9.
- Specs: `DP-1=image`, `desc:Acme Panel S2=video` (on DP-2) and a `*` fallback, run once with a video fallback and once with an image fallback per backend (6 runs).
- Initial outputs: DP-1, DP-2, DP-3 (undeclared), DP-4 (disabled), and on hyprland DP-5 (mirrored). Then HDMI-A-1 is hot-plugged, DP-3 unplugged, DP-4 re-enabled, and the supervisor gets SIGTERM.
- Every stub exits 1 (logging `bad-args`) unless called with exactly the arguments the script should send.
- Stream drop: fd 8 is closed so the stub's `cat` sees EOF, then reopened once a second `stream-open` is logged.
- Crash: the DP-2 `mpvpaper` stub is sent SIGUSR1 (logs `mpv-crash`, exits).
- Failed start (image fallback runs): `awww img` fails 5 times for a hot-plugged DP-6, so the first start gives up.
- Lock check: after SIGTERM a second instance must not print `already running`. The second instance must also have listed outputs. The FIFO stays open, so a stream process (or the subshell around it) still holding the lock would be caught.

## Checks

Per run (backend x fallback kind):

| Check | Expected |
|-------|----------|
| declared name DP-1 gets its still via `awww img` | logged |
| `desc:` entry gets its video on DP-2 via `mpvpaper` | logged |
| undeclared DP-3 gets the fallback (video via mpvpaper / image via awww) | logged |
| fallback never lands on DP-1 or on the `desc:`-declared DP-2 | not logged |
| declared DP-1 never gets mpvpaper | not logged |
| disabled DP-4 is skipped | no start |
| mirrored DP-5 is skipped (hyprland only) | no start |
| no start targets `*` or `ALL` | none |
| DP-2 video started exactly once (also after hot-plug) | 1 |
| children (`mpvpaper`, `awww img`) do not inherit lock fd 9 | no `fd9-leak` |
| hot-plugged undeclared HDMI-A-1 gets the fallback | logged |
| unplugged DP-3 has its `mpvpaper` stopped, DP-2 untouched (video fallback) | `mpv-stop DP-3` only |
| re-enabled DP-4 gets the fallback | logged |
| every tool called with the expected arguments | no `bad-args` |
| event stream opened once at startup | 1 |
| failed still start (image fallback) is retried until it succeeds | `img DP-6` logged after `img-fail` |
| dropped event stream is reopened; daemon alive; no `mpv-stop DP-2`; DP-2 not restarted; events work again | true |
| crashed DP-2 `mpvpaper` is restarted; daemon alive | second `mpv-start DP-2` |
| supervisor exits on SIGTERM; remaining `mpvpaper` stopped (video fallback) | true |
| lock is free after SIGTERM | second instance not refused, and it listed outputs |

## mango config values

When `nix` is available the check also evaluates `wayland.windowManager.mango.settings` of every home-manager user on every `nixosConfigurations` host that enables mango. mango 0.18 reads each config value with `sscanf("%255[^\n]")` (`src/config/load.c`), drops everything after 255 chars without an error, and `mango -p` still passes.

| Check | Expected |
|-------|----------|
| at least one host enables mango | true |
| a wallpaper daemon is in some mango `exec_once` | true |
| every string value (`exec_once`, `window_rule`, `monitor_rule`, ...) is at most 255 chars | true |
| every `exec_once` / `exec`, cut at 255 chars the way mango reads it, is valid shell (`bash -n -c`) | true |

This catches a wallpaper daemon argv inlined into `exec_once` (321 chars with three video specs): mango spawned `sh -c` with an unterminated quote, so the daemon never started.
