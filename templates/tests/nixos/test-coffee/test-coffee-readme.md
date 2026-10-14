# test-coffee

Tests coffee mode (`modules/nixos/services/power/coffee.nix` and the `coffee-on` / `coffee-off` / `coffee-status` / `coffee-toggle` scripts in `coffee/`) against the rules in `Documentation/usage/power/coffee-mode.md`:

- Coffee blocks only automatic things: a weak sleep lock plus a full `idle:handle-lid-switch` lock.
- Manual suspend, the suspend/hibernate keys, the power button, shutdown and reboot keep working.
- Coffee installs only with a tiling WM, and is forced off in guest and secure-travel.
- The scripts never lock, blank, suspend or power off anything themselves.
- `coffee-off` restores and verifies.

Two parts:

1. **Eval:** a minimal fake host checks the module contract.
2. **Runtime:** the real scripts run against stub `systemctl` / `systemd-run` / `systemd-inhibit` / `loginctl`, so the step log, exit codes, idempotency, linger handling and the absence of dangerous commands are checked without touching the machine.

Not covered here:

- The waybar pill (placement right after `battery`, signal 8, `coffee.service` probe, always shown with an `off` class, left-click = `coffee-toggle` by store path) is covered by `test-waybar-configs`; its `off`/`active` contrast by `test-waybar-contrast`.
- The guest/secure-travel `services.coffee.enable == false` flag (with a base-host control) is covered by `test-spec-contract`.
- The "no WM => no coffee" case on a defaults-only host is covered by `test-minimal-defaults`.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-coffee` (name as shown by `--list`). The direct commands are below.

From repo root:

```bash
bash templates/tests/nixos/test-coffee/check-nixos-coffee-eval.sh
bash templates/tests/nixos/test-coffee/check-nixos-coffee-runtime.sh
```

From inside the directory:

```bash
bash check-nixos-coffee-eval.sh
bash check-nixos-coffee-runtime.sh
```

`COFFEE_SRC=<dir>` points the runtime check at another copy of the five `coffee-*.sh` files (used for mutation testing). Runtime: about 15 s for the eval part and 8 s for the runtime part, on the default `nixos` CI group.

## How it works

### Eval (`01-scenario-coffee.nix`, `check-nixos-coffee-eval.sh`)

The fake host `coffee-host` (`shared/host-coffee.nix`) loads only:

- home-manager, the constants modules, the three WM toplevels (hyprland, niri, mango), `hypridle`, `coffee`, and the real `guest` / `secure-travel` specialisation modules (both enabled);
- `shared/nixos-extra-x86_64/option-sinks.nix`, which declares as plain bool/raw options the `myconfig.*` and `stylix.*` options that those two specialisations set, so their modules are not loaded.

Hyprland is on by default; nothing sets `services.coffee.enable`. Variants are `extendModules` twins of that host:

- each WM alone;
- no WM;
- coffee disabled;
- guest/secure-travel with mango forced back on inside the specialisation (`mkOverride 10`);
- the same with coffee also forced back on (control).

The scenario returns one attrset of `"ok"` / `"FAIL: ..."` strings (`results`) plus `control`. The script evaluates each attrset once as JSON and prints one line per entry. It also fails if fewer entries than expected come back.

What "coffee present" means: `coffee-on`, `coffee-off`, `coffee-status` and `coffee-toggle` are in the HM `home.packages`, and `services.logind.settings.Login` has `SuspendKeyIgnoreInhibited = "yes"` and `HibernateKeyIgnoreInhibited = "yes"`. "Absent" means none of these is there.

Why the leaked-WM twins exist: guest and secure-travel already force every WM off, so a plain "coffee absent in guest" check would still pass if `coffee.enable = lib.mkForce false` were removed. With mango leaked back in (as happened for safe-mode), only the coffee force-off keeps coffee out.

### Runtime (`check-nixos-coffee-runtime.sh`)

How the scripts are run:

- Each script is built as `set -euo pipefail` + `coffee-lib.sh` + `coffee-<name>.sh`, matching the `writeShellApplication` text; the eval check `each package text is ...` ties this to the real package.
- `coffee-toggle` finds `coffee-on` / `coffee-off` by name; in the stub directory these are wrappers that log `exec coffee-<name>` and run the built test copy (the real package gets them from its `runtimeInputs`, checked by the eval part).
- They run with `COFFEE_PATH_PREFIX` (stubs first), `COFFEE_STATE_DIR` (per scenario), `COFFEE_TRIES=1`, `COFFEE_POLL=0`, `COFFEE_BOOT_ID=boot-A` and `COFFEE_USER=tester`.

The stubs model this state in files:

- `coffee.service` (none / active / failed);
- the inhibitor list, which also holds three locks of other apps: a delay lock, a block lock, and a `coffeemaker` block-weak decoy that must not count as coffee's;
- `Linger`, hypridle (active / inactive / absent), `graphical-session.target`, `LidClosed`, whether waybar is running.

How the stubs behave:

- `systemd-run` saves its argv. Like real `systemd-inhibit`, it turns every nested `systemd-inhibit --what= --mode= --who=` into a listed lock.
- Each stub accepts only the exact argument shapes the scripts should send, and logs anything else as `bad-args`.
- `systemctl suspend|hibernate|poweroff|reboot|halt|...`, `loginctl lock-*|terminate-*|kill-*`, and the binaries `hyprctl`, `hyprlock`, `swaylock`, `poweroff`, `reboot`, `shutdown`, `halt`, `brightnessctl`, `wlopm`, `xset`, `systemd-sleep` and `wlr-randr` are logged as `FORBIDDEN`.
- `logger -t coffee -p user.<prio> -- <line>` writes to a journal file, and `notify-send` and `pkill` are logged.

Knobs make `systemd-run` refuse, make it start without the locks appearing (SSH: logind refuses), make `stop` fail, and make `enable-linger` or `notify-send` fail.

TTY output runs through `script(1)` (`SHELL=/bin/sh`). The plain runs write to a file.

On failure the script outputs are saved as evidence (`keep_evidence`).

## Checks

### Eval: contract

| Check | Expected |
|-------|----------|
| option `services.coffee.enable` defaults to true | option default `true` and the fake host (which does not set it) has `true` |
| hyprland only / niri only / mango only (3 checks) | coffee present (4 scripts, both logind keys `"yes"`) |
| no WM | coffee absent |
| coffee disabled, WM on | coffee absent |
| guest; secure-travel (2 checks) | coffee absent in the specialisation |
| guest / secure-travel with a WM leaked back in (2 checks) | coffee still absent |
| control: guest / secure-travel with a leaked WM and coffee re-enabled (2 checks) | coffee present (the probe works inside a specialisation) |
| coffee declares no system unit | `systemd.services` names equal with and without coffee |
| coffee declares no user unit (no lid watcher) | HM `systemd.user.services` names equal with and without coffee |
| coffee changes logind only by the two `*KeyIgnoreInhibited` keys | `services.logind.settings` with coffee == without coffee + `Login.{Suspend,Hibernate}KeyIgnoreInhibited = "yes"` (no `HandleLidSwitch`, no `PowerKeyIgnoreInhibited`) |
| each package text is the strict-mode header + `coffee-lib.sh` + its own script | `set -o errexit/nounset/pipefail` and `readFile lib + readFile <name>` inside the package `.text`, for all four |
| coffee-toggle has the installed coffee-on and coffee-off on its PATH | the `export PATH=` line of the `coffee-toggle` text contains `<coffee-on>/bin` and `<coffee-off>/bin` of the installed packages |
| `services.coffee.togglePackage` (waybar on-click) is the installed coffee-toggle | the read-only option's `outPath` equals the installed `coffee-toggle` |
| hypridle is enabled with a generated config | `services.hypridle.enable` and `hypr/hypridle.conf` contains `lock_cmd` |
| hypridle does not set `ignore_systemd_inhibit` | not `true` in `settings.general`, not `= true/1/yes/on` in the generated config |

### Eval: controls

| Check | Expected |
|-------|----------|
| unit diff detects an added unit | `coffee-lid` found in a sample |
| `ignore_systemd_inhibit` detector bites (settings, config text) and accepts `false` (3 checks) | true |
| absent detector rejects installed coffee | the hyprland variant is not "absent" |
| present detector rejects missing coffee | the no-WM variant is not "present" |
| toggle PATH detector rejects a PATH without coffee-off | true |
| strict-mode detector rejects a bare script | true |

### Runtime: static script text

| Check | Expected |
|-------|----------|
| no `handle-power-key` / `handle-suspend-key` / `handle-hibernate-key` | none in lib/on/off/status/toggle |
| inhibitor types defined once | `COFFEE_WHAT_WEAK="sleep"`, `COFFEE_WHAT_BLOCK="idle:handle-lid-switch"` |
| every `--what=` uses those two variables | exactly `--what="$COFFEE_WHAT_BLOCK"` and `--what="$COFFEE_WHAT_WEAK"` |
| no suspend/poweroff/reboot/lock/dpms/brightness command outside messages and comments | scan (quoted strings and comments stripped) finds nothing |
| control: the scan catches `systemctl suspend`, `loginctl lock-session`, `hyprctl dispatch dpms off` | 3 hits |
| control: the scan ignores quoted prose and comments | no hit |

### Runtime: lifecycle (`on`, `on` again, `status`, `off`, `off` again, `status`)

| Check | Expected |
|-------|----------|
| `coffee-on` exit / format / steps | exit 0; every line `[ OK ]`/`[WARN]`/`[FAIL]` then a summary; 7 `[ OK ]`, no WARN/FAIL; `coffee-on: done, coffee is ON (7 ok, 0 warn, 0 fail)` |
| `systemd-run` | called once with `--user`, `--unit=coffee`, `--collect`; nested inhibitors exactly `sleep block-weak` wrapping `idle:handle-lid-switch block`, both `--who=coffee`; command `sleep infinity` |
| state after `coffee-on` | 2 coffee locks listed, `coffee.service` active, `enable-linger tester` once and `Linger=yes`, marker = boot id, `hypridle-before` = `active` |
| side effects of `coffee-on` | `pkill --signal RTMIN+8 -x 'waybar\|\.waybar-wrapped'` once, `notify-send "Coffee mode on"` once |
| journal | every output line appears in the journal with priority info/warning/err by tag |
| no colour codes when stdout is not a TTY | no ESC byte |
| second `coffee-on` | exit 0, "already holds", no WARN/FAIL, no second `systemd-run` / lock / notification / `enable-linger`, "linger: already enabled by coffee", marker and hypridle record kept |
| `coffee-status` (on) | exit 0, `coffee: ON`, `linger: yes (enabled by coffee)`, "still works: manual suspend, suspend/hibernate keys, power button, shutdown, reboot", lists both coffee locks and the other app's block lock, not the delay lock |
| `coffee-off` exit / format / summary | exit 0, no WARN/FAIL, well-formed steps, `coffee-off: done, coffee is OFF`, no lid line (lid open) |
| `coffee-off` restore + verify | `systemctl --user stop coffee.service`, no unit left, no coffee lock listed (other 3 locks untouched), `disable-linger` called and `Linger=no` and marker removed, hypridle verified active and record removed |
| side effects of `coffee-off` | pill refreshed (3rd `pkill`), `notify-send "Coffee mode off"`, journal mirrors output |
| second `coffee-off` | exit 0, "already off", no WARN/FAIL, no extra stop / `disable-linger` / notification, summary OFF |
| `coffee-status` (off) | exit 3, `coffee: OFF` |
| no forbidden command, every stub called with expected arguments | no `FORBIDDEN` / `bad-args` in the call log |

### Runtime: coffee-toggle

| Check | Expected |
|-------|----------|
| toggle from off | exit 0; first line `coffee-toggle: coffee is OFF, running coffee-on`; `coffee-on` run once, `coffee-off` never; unit active, 2 coffee locks; last line `coffee-on: done, coffee is ON (7 ok, 0 warn, 0 fail)`; `notify-send "Coffee mode on"` once, pill refreshed once; every output line (the toggle line included) in the journal |
| toggle from on | exit 0; `coffee is ON, running coffee-off`; `coffee-off` run once; no unit, no coffee lock, `Linger=no`; `notify-send "Coffee mode off"` once, pill refreshed again |
| third toggle | coffee on again (`coffee-on` run twice in total) |
| half on (unit active, no lock) | `coffee is INCONSISTENT, running coffee-off`, exit 0, no unit left, `coffee-on` never run |
| `coffee-on` fails under the toggle (`systemd-run` refuses) | the toggle's exit code is non-zero and equal to a direct `coffee-on`'s; `coffee-on: FAILED, coffee is OFF`; no unit, no lock, no notification |
| no forbidden command (each toggle scenario) | clean call log: no suspend / lock / DPMS / poweroff stub called |

### Runtime: linger semantics

| Check | Expected |
|-------|----------|
| user-enabled linger: `coffee-on` | "already enabled (not by coffee, coffee-off leaves it on)", no `enable-linger`, no marker |
| user-enabled linger: `coffee-off` | "left as is (yes, not enabled by coffee)", no `disable-linger`, `Linger` still yes |
| stale marker (other boot id): `coffee-on` then `coffee-off` | marker dropped, linger treated as not coffee's, never disabled |
| stale marker, `coffee-off` only | marker removed, linger left as is |
| no forbidden command (per section) | clean call log |

### Runtime: FAIL and WARN paths

| Check | Expected |
|-------|----------|
| `systemd-run` refuses | exit != 0; `[FAIL] inhibitor: systemd-run could not start ...  fix: systemctl --user reset-failed coffee.service`; every WARN/FAIL has `fix:`; `coffee-on: FAILED, coffee is OFF`; no unit, no lock; no linger change, no notification; FAIL in journal at `err` |
| lock refused (SSH: no desktop, locks never appear) | exit != 0; `[WARN] desktop: no graphical session ...  fix: coffee-on`; `[FAIL] inhibitor: logind refused the lock ...  fix: coffee-on`; the half-started unit is stopped, none left; no linger change, no notification |
| KDE + `enable-linger` and `notify-send` fail | exit 0; WARN desktop (`fix: kcmshell6 kcm_powerdevilprofilesconfig`), WARN linger (`fix: loginctl enable-linger tester`), WARN notification (`fix: notify-send 'Coffee mode on'`); `done with warnings, coffee is ON (4 ok, 3 warn, 0 fail)`; 3 journal lines at `warning`; no marker; the later `coffee-off` never calls `disable-linger` |
| `coffee-off` with the lid closed | exit 0; `[WARN] lid: closed ...  fix: coffee-on`; lock still released; `done with warnings, coffee is OFF` |
| `coffee-off` cannot stop the unit | exit != 0; `[FAIL] inhibitor unit: could not stop ...  fix: systemctl --user stop coffee.service`; `[FAIL] verify: a coffee lock is still listed  fix: pkill -f -- '--who=coffee'`; `coffee-off: FAILED, coffee is STILL ON` |
| hypridle stopped during coffee | `coffee-off` runs `systemctl --user start hypridle.service`, "started again and verified active" |
| control: hypridle not running before `coffee-on` (no graphical session) | not started by `coffee-off` |
| no forbidden command (per section) | clean call log |

### Runtime: colour

| Check | Expected |
|-------|----------|
| control: `script(1)` gives a TTY | `test -t 1` true inside |
| TTY, `COFFEE_COLOR` unset | ESC codes present; the journal still has none |
| TTY, `COFFEE_COLOR=never`; TTY, `NO_COLOR=1` | no ESC codes |
| pipe, `COFFEE_COLOR` unset | no ESC codes |
| pipe, `COFFEE_COLOR=always` | ESC codes present |

### Runtime: stub controls

| Check | Expected |
|-------|----------|
| suspend/poweroff/lock/dpms stub calls | logged `FORBIDDEN` (4) |
| a direct `systemd-inhibit --what=shutdown` lock | logged `bad-args` |
| the clean-call-log check fails on that log | true |
| a `[WARN]` without `fix:` / a non-step line | rejected by the fix-hint and format checks |
| a full (non-weak) sleep lock / an added `shutdown` lock in the `systemd-run` argv | rejected by the argv check |
