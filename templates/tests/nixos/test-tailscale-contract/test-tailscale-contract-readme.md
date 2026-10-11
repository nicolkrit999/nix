# test-tailscale-contract

Verifies the tailscale wiring on the real hosts: operator flags, firewall, the `tailscale-autoconnect` unit introduced in 4ddd6ec1, the school exit-node-off ordering and the secure-travel privacy contract.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-tailscale-contract` (name as shown by `--list`); the direct command is below.

```bash
bash templates/tests/nixos/test-tailscale-contract/check-nixos-tailscale-contract.sh
```

Or from inside the directory:

```bash
bash check-nixos-tailscale-contract.sh
```

## How it works

`01-scenario-tailscale-contract.nix` evaluates the real flake (`nixosConfigurations.$HOST_UNDER_TEST`, including `specialisation.school` and `specialisation.secure-travel`) and exposes check results as strings (`"ok"` / `"FAIL: ..."`). Two `extendModules` controls prove checks can bite: tailscale disabled (no autoconnect unit) and `constants.user` overridden (operator flags must follow it). Loop budget numbers are parsed from the generated autoconnect script, nothing is hardcoded.

`check-nixos-tailscale-contract.sh` runs one `nix eval --json --impure` per host (desktop, laptop) and prints a PASS/FAIL line per check; exit 1 on any failure.

Design notes (I-02 / I-03 resolved): autoconnect stays `Type=exec` (non-blocking boot, 4ddd6ec1) with no `TimeoutStartSec` (it cannot bound a background loop); the retry loop bounds itself. School exit-node-off is `Type=exec` (never a blocking oneshot on multi-user.target) and retries `timeout N tailscale set --exit-node=` in a bounded loop (a prefs edit that works while logged out or offline, so no wait for `Running`). I-04 (extraUpFlags comment) changes nothing assertable. secure-travel really turns tailscale off because the NAS consumers that force it on are disabled there. Only real hosts are evaluated, so there is no synthetic host; host choices (whether a host enables tailscale) are not asserted.

## Checks

### Per host (nixos-desktop, nixos-laptop)
| Check | Expected |
|-------|----------|
| `operator-set-flag` / `operator-up-flag` | `--operator=<constants.user>` in `extraSetFlags` / `extraUpFlags` |
| `operator-flags-agree` | operator flags of set and up are identical and non-empty |
| `operator-control-follows-user` | with another `constants.user` the flags follow it |
| `firewall-trusted-iface` / `loose-rpfilter` / `udp-41641` | `tailscale0` trusted, `checkReversePath == "loose"`, UDP 41641 open |
| `autoconnect-unit-exists` | unit present |
| `autoconnect-control-absent-when-disabled` | unit absent with the module disabled |
| `autoconnect-type-exec` | `Type=exec` |
| `autoconnect-no-misleading-timeout` | no `TimeoutStartSec` on the exec unit |
| `autoconnect-wantedby-multiuser` | wantedBy `multi-user.target` |
| `autoconnect-after-tailscaled` | after `tailscaled.service` and `network-online.target` |
| `autoconnect-script-up-timeout` | script runs `tailscale up --timeout=20s` |
| `autoconnect-script-parsed` | loop count, up timeout and sleep parse |
| `autoconnect-retry-loop-bounded` | loops <= 100 and worst case <= 3600s |
| `autoconnect-gives-up` | script exits 1 after the loop |

### school specialisation
| Check | Expected |
|-------|----------|
| `school-has-autoconnect` | autoconnect unit exists |
| `school-exitoff-ordering-units` | exit-node-off After+Wants autoconnect, After tailscaled |
| `school-exitoff-wantedby` / `script` | multi-user.target, runs `tailscale set --exit-node=` |
| `school-exitoff-after-tailscaled-prefs-edit` | exit-off is After tailscaled.service and uses `tailscale set` (prefs edit), not `tailscale up` |
| `school-exitoff-not-blocking-oneshot` | not `Type=oneshot` while wanted by `multi-user.target` |
| `school-exitoff-type-exec` | `Type=exec` |
| `school-exitoff-loop-bounded` | loops <= 100 and loops*(set timeout+sleep) <= 900s, parsed from the script |
| `school-exitoff-gives-up` | exit-off exits 1 when retries are exhausted |
| `school-autoconnect-nonblocking` | school autoconnect `Type=exec` (boot hang regression guard, 4ddd6ec1) |

### secure-travel specialisation
| Check | Expected |
|-------|----------|
| `secure-travel-myconfig-tailscale-off` | myconfig wrapper off |
| `secure-travel-nixos-tailscale-off` | `services.tailscale.enable == false` (NAS consumers disabled in the spec) |
| `secure-travel-no-autoconnect` | no autoconnect unit |
| `secure-travel-tailscale0-untrusted` | `tailscale0` not in trusted interfaces |
