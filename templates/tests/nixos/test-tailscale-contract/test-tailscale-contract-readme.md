# test-tailscale-contract

Verifies the tailscale wiring on the real hosts: operator flags, firewall, login through the upstream `tailscaled-autoconnect` unit (`authKeyFile` set) with the removed repo unit `tailscale-autoconnect` staying gone, forbidden up/set flags, the school exit-node-off ordering and the secure-travel contract (tailscale is the VPN, outbound only).

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

`01-scenario-tailscale-contract.nix` evaluates the real flake (`nixosConfigurations.$HOST_UNDER_TEST`, including `specialisation.school` and `specialisation.secure-travel`) and exposes check results as strings (`"ok"` / `"FAIL: ..."`). Two `extendModules` controls prove checks can bite: tailscale disabled (no `tailscaled-autoconnect`) and `constants.user` overridden (operator flags must follow it). The flag detectors get their own control on literal sample lists. Loop budget numbers are parsed from the generated exit-node-off script, nothing is hardcoded.

`check-nixos-tailscale-contract.sh` runs one `nix eval --json --impure` per host (desktop, laptop) and prints a PASS/FAIL line per check; exit 1 on any failure.

Design notes:
- Login is upstream nixpkgs `tailscaled-autoconnect`, which exists only when `services.tailscale.authKeyFile` is set (both hosts, via `templates/krit/sops/service-wiring.nix`). The repo unit `tailscale-autoconnect` was removed (audit B3-01): its `tailscale up --timeout=20s` was refused on every boot because `up` with any flag must restate every non-default pref.
- `--accept-dns=false` (in any Go bool spelling, `-`/`--`) must never appear in `extraUpFlags`/`extraSetFlags` on the base host or the school spec: tailnet DNS outages are fixed in the tailnet console, not by turning MagicDNS off. `--accept-routes` (enabled) must not appear either (B3-03): the NAS advertises the home LAN subnet, so it would route the desktop's own LAN through the NAS on the next re-login.
- School exit-node-off is `Type=exec` (never a blocking oneshot on multi-user.target) and retries `timeout N tailscale set --exit-node=` in a bounded loop (a prefs edit that works while logged out or offline). Every unit it orders after or wants must exist in the spec, and its `path` uses `services.tailscale.package`.
- secure-travel keeps tailscale ON (it is the VPN; an exit node is picked by hand and a user timer warns while none is active), with `openFirewall = false` and no trusted `tailscale0`: outbound only. The upstream `tailscaled-autoconnect` is allowed there; the removed repo unit stays gone. The NAS consumers are still disabled in the spec.
- Only real hosts are evaluated, so there is no synthetic host; host choices (whether a host enables tailscale) are not asserted.

## Checks

### Per host (nixos-desktop, nixos-laptop)
| Check | Expected |
|-------|----------|
| `operator-set-flag` / `operator-up-flag` | `--operator=<constants.user>` in `extraSetFlags` / `extraUpFlags` |
| `operator-flags-agree` | operator flags of set and up are identical and non-empty |
| `operator-control-follows-user` | with another `constants.user` the flags follow it |
| `firewall-trusted-iface` / `loose-rpfilter` / `udp-41641` | `tailscale0` trusted, `checkReversePath == "loose"`, UDP 41641 open |
| `authkeyfile-set` | `services.tailscale.authKeyFile != null` |
| `upstream-autoconnect-exists` | `systemd.services.tailscaled-autoconnect` present |
| `upstream-autoconnect-control-absent-when-disabled` | no `tailscaled-autoconnect` with the module disabled |
| `no-repo-autoconnect-unit` | no `systemd.services.tailscale-autoconnect` |
| `no-accept-dns-false` | no `accept-dns` flag with a false value in up/set flags (base and school) |
| `no-accept-routes` | no enabled `accept-routes` flag in up/set flags (base and school) |
| `flag-detectors-control` | detectors catch `--accept-dns=false`, `-accept-dns=0`, `--accept-routes`, `--accept-routes=true`, and ignore `--accept-dns`, `--accept-dns=true`, `--accept-routes=false` |

### school specialisation
| Check | Expected |
|-------|----------|
| `school-no-repo-autoconnect-unit` | no `tailscale-autoconnect` unit |
| `school-has-upstream-autoconnect` | `tailscaled-autoconnect` exists |
| `school-exitoff-ordering-units` | exit-node-off After `tailscaled.service`, never After/Wants `tailscale-autoconnect.service`, every `.service` it orders after or wants exists |
| `school-exitoff-path-service-package` | unit `path` contains `services.tailscale.package` |
| `school-exitoff-wantedby` / `script` | multi-user.target, runs `tailscale set --exit-node=` |
| `school-exitoff-after-tailscaled-prefs-edit` | exit-off is After tailscaled.service and uses `tailscale set` (prefs edit), not `tailscale up` |
| `school-exitoff-not-blocking-oneshot` | not `Type=oneshot` while wanted by `multi-user.target` |
| `school-exitoff-type-exec` | `Type=exec` |
| `school-exitoff-loop-bounded` | loops <= 100 and loops*(set timeout+sleep) <= 900s, parsed from the script |
| `school-exitoff-gives-up` | exit-off exits 1 when retries are exhausted |

### secure-travel specialisation
| Check | Expected |
|-------|----------|
| `secure-travel-tailscale-on` | myconfig wrapper on and `services.tailscale.enable == true` |
| `secure-travel-autoconnect-allowed` | upstream `tailscaled-autoconnect` present, repo `tailscale-autoconnect` absent |
| `secure-travel-no-open-firewall` | `services.tailscale.openFirewall == false` and UDP 41641 not in `allowedUDPPorts` |
| `secure-travel-control-base-opens-firewall` | base host has `openFirewall == true` (control for the check above) |
| `secure-travel-tailscale0-untrusted` | `tailscale0` not in trusted interfaces |
