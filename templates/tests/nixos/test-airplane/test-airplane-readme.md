# test-airplane

Tests airplane mode (`modules/nixos/services/airplane.nix` and `airplane/airplane.sh`):

- `airplane wifi` turns only Wi-Fi off, `airplane full` turns every radio off (NetworkManager plus rfkill), `airplane off` brings them back.
- Every mode reads the real state back and prints a confirmation: one line per radio with a check mark, cross or dash, and a verdict line.
- `airplane status` prints the one JSON line the waybar pill shows, one class per state: `online`, `wifi-off`, `airplane`.
- The module is on exactly where NetworkManager is on, and forcing it on without NetworkManager fails the build.

Two parts:

1. **Eval:** a minimal fake host with `extendModules` twins checks the module contract (gating, assertion, aliases, package text, runtime inputs).
2. **Runtime:** the real script runs against stateful stub `nmcli` / `rfkill` / `notify-send` / `logger` / `pkill` / `vicinae`. They log their argv, so the exact calls, the confirmation output, the exit codes, the notifications and the JSON can be asserted without touching the machine's radios.

Not covered here:

- The waybar pill (placement right after `battery`, signal 9 equal to the script's `AIRPLANE_SIGNAL`, store-path clicks for `status` / `toggle` / `pick`, `format-icons` keys equal to the script's mode names, the `#custom-airplane` CSS rule) is covered by `test-waybar-configs`; the colour of the three state icons by `test-waybar-contrast`.
- Whether a host enables the module is deliberately not asserted (it follows NetworkManager).

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-airplane` (name as shown by `--list`). The direct commands are below.

From repo root:

```bash
bash templates/tests/nixos/test-airplane/check-nixos-airplane-eval.sh
bash templates/tests/nixos/test-airplane/check-nixos-airplane-runtime.sh
```

From inside the directory:

```bash
bash check-nixos-airplane-eval.sh
bash check-nixos-airplane-runtime.sh
```

`AIRPLANE_SRC=<file>` points the runtime check at another copy of `airplane.sh`. Runtime: about 5 s for the eval part and 4 s for the runtime part, on the default `nixos` CI group.

## How it works

Eval: `01-scenario-airplane.nix` builds a fake host from `home-manager.nix`, both constants modules and `airplane.nix` only, and derives twins with `extendModules` (NetworkManager on or off, airplane forced on or off). `check-nixos-airplane-eval.sh` evaluates the `results` and `control` attrsets and reports every entry.

Runtime: `check-nixos-airplane-runtime.sh` prepends `set -euo pipefail` to `airplane.sh` (what `writeShellApplication` does) and runs it with `env -i`, a `PATH` holding only symlinks to bash, cat, dirname, mkdir, sort, grep and sleep, and the stubs in `AIRPLANE_PATH_PREFIX`. The stubs keep radio state in a temp dir (Wi-Fi, WWAN, one rfkill file per type, hardware-block files), log every mutating call, and can be switched into modes: `fail` (exit 1), `stuck` (exit 0 but nothing changes), `lag` (the change shows up after a few reads), `broken` (nmcli queries fail). `AIRPLANE_SCOPE_FILE`, `AIRPLANE_TRIES`, `AIRPLANE_POLL` and `AIRPLANE_COLOR` keep the run hermetic and fast; the picker tests add a `vicinae` stub, the "vicinae missing" test leaves it out of the `PATH`.

## Checks

### Eval (module contract)

| Check | Expected |
|-------|----------|
| option defaults to NetworkManager: off without it | `myconfig.services.airplane.enable` is false when `networking.networkmanager.enable` is false |
| option defaults to NetworkManager: on with it | true when NetworkManager is on |
| NetworkManager on: package and aliases installed | HM `home.packages` has `airplane`; `airplane-on` and `airplane-off` aliases exist |
| NetworkManager off: no package, no aliases | none of the above |
| explicitly disabled with NetworkManager on: no package, no aliases | none of the above |
| aliases map to full and off | `airplane-on = "airplane full"`, `airplane-off = "airplane off"` |
| forced on without NetworkManager: assertion fires | exactly one failing assertion naming `myconfig.services.airplane` |
| forced on with NetworkManager / default NetworkManager host | no failing airplane assertion |
| package text is the strict-mode header + airplane.sh | `errexit`, `nounset`, `pipefail` set and the script text embedded |
| runtime inputs on the script PATH | networkmanager, util-linux, libnotify and procps are in the `export PATH=` line |
| services.airplane.package is the installed airplane | same store path as the HM package (the waybar clicks use it) |
| script still calls every binary the runtime inputs are there for | `nmcli`, `rfkill`, `notify-send`, `logger`, `pkill` all appear in the script |

Controls: the present and absent detectors reject the wrong host, the failing-assertion filter bites, the strict-mode detector rejects a bare script, the PATH check rejects a missing runtime input, and the NetworkManager twin really flips the option.

### Runtime (script behaviour)

| Check | Expected |
|-------|----------|
| `airplane wifi` | the only mutating call is `nmcli radio wifi off`; scope file `wifi`; Wi-Fi row check mark, WWAN / Bluetooth / NFC rows dash "(not touched)"; wlan and wwan are not listed twice; verdict "done, state is now Wi-Fi off"; normal notification; waybar signalled with `RTMIN+9` |
| `airplane full` | calls `nmcli radio all off` then `rfkill block all`, nothing else; scope `full`; Wi-Fi, WWAN, Bluetooth and NFC rows all check marks, no cross or dash; verdict "airplane mode"; notification, waybar signal, journal line |
| `airplane off` | calls `nmcli radio all on` then `rfkill unblock all`; every row a check mark; verdict "online"; an existing scope file is unchanged and none is created |
| `airplane status` | valid one-line JSON with exactly `text` / `alt` / `class` / `tooltip` for online, wifi off (WWAN or Bluetooth or rfkill-radios still on, three variants), airplane (everything off) and "Wi-Fi on, rest off" (= online); a failing `nmcli` reads as online; the online tooltip names the saved scope; no mutating call, no notification, no waybar signal |
| `airplane toggle` | online applies the saved scope (none or garbage = full, `wifi` = wifi only); wifi-off and airplane states go back online and keep the scope |
| interactive menu | choices 1 / 2 / 3 run wifi / full / off and print the confirmation; the menu lists the three options; `q` and an empty line cancel with no call; an invalid choice exits 2 with no call; end of input exits 1 with no call |
| failures | failing `nmcli` or `rfkill`: exit 1, a `command failed:` cross line, the radio row cross "(wanted off)", FAILED verdict, critical notification, the other command still attempted; a command that succeeds but changes nothing: exit 1, cross rows, no "command failed" line; slow NetworkManager: the script polls again until it settles and succeeds; hardware-blocked Bluetooth counts as off for full and shows a cross when turning on |
| scope picker | `vicinae dmenu -n 'Airplane mode' -p 'Which radios?'` with the three entries in order; each entry runs its mode; escape, an empty pick: no call and exit 0; unknown entry exits 2; vicinae missing exits 1 with a critical notification and no call |
| arguments and colour | `help` prints usage; an unknown argument exits 2 with usage on stderr; `AIRPLANE_COLOR=always` wraps check marks in green and crosses in red, `never` emits no escape bytes |

Controls (mutated copies of the script): wrong nmcli arguments, a dropped `rfkill block all` (and its Bluetooth cross), a check mark printed for a failed radio, a wrong state decision in `status`, and a script that does not save the scope each make the matching check fail; the unmutated script passes the same checks.
