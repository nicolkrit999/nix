# test-spec-real-hosts-security

Security and isolation contracts of the guest, secure-travel and entertainment specialisations, evaluated on the REAL `nixos-desktop` and `nixos-laptop` configurations (not a fake host), so interactions with host and NAS modules are visible.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-spec-real-hosts-security` (name as shown by `--list`); the direct command is below.

From the repo root:

```bash
bash templates/tests/nixos/test-spec-real-hosts-security/check-nixos-spec-real-hosts-security.sh
```

Or from inside the directory:

```bash
bash check-nixos-spec-real-hosts-security.sh
```

Needs `nix`, `jq`, `bash`. Eval-only (no builds); both hosts evaluate in parallel, 74 s inside the full parallel suite run of 2026-10-11.

## How it works

`01-scenario-spec-real-hosts-security.nix` takes `{ host }`, loads `flake.nixosConfigurations.<host>` via `builtins.getFlake` (the runner exports `FLAKE_ROOT` = repo root of the script, overridable; the scenario throws if unset) and exposes `results`, an attrset of `label -> "ok" | "FAIL: ..."`. Each check is wrapped in `tryEval`, so a broken attribute fails only that check. It also exposes `killswitch`, the text of the NetworkManager dispatcher script.

`check-nixos-spec-real-hosts-security.sh` evaluates `results` once per host, prints a PASS/FAIL line per check, then runs `bash -n` on the killswitch text. It exits non-zero on any failure.

Guest checks compare independent sources (uid vs gid vs tmpfs `uid=`/`gid=` options vs firewall `--uid-owner` vs slice name; AccountsService session vs `defaultSession`) rather than hardcoded literals. `control:` checks prove the main checks can fail (the base config has tailscale on, no guest user, a DE enabled, and a non-locked root).

Scope: only specialisation purpose contracts are asserted (guest isolation, secure-travel hardening and GNOME-only, entertainment). Which specialisations a host declares is a host choice and is not checked. The hosts are the real ones, so no fake host is involved.

Three secure-travel gaps this test was written against are fixed in `modules/nixos/specializations/secure-travel.nix` and now pass: the NAS consumers are disabled so `services.tailscale.enable` really ends up false, the firewall port lists are `mkForce [ ]` (sshd, avahi and localsend are off too), and mango is disabled.

## Checks

### Both hosts
| Check | Expected |
|-------|----------|
| each declared specialisation | no failing `assertions` (the set of specialisation names is a host choice and is not asserted) |

### guest
| Check | Expected |
|-------|----------|
| uid / gid | `users.users.guest.uid == 2000`, `users.groups.guest.gid == uid` |
| `/home/guest` | tmpfs, `uid=`/`gid=` match user/group, `mode=700`, `nosuid`, `nodev` |
| `systemd.slices` | has `user-<uid>` |
| firewall | REJECT rules for the guest uid to `tailscale0` and `100.64.0.0/10` |
| display manager | autoLogin enabled for `guest` (user exists), `defaultSession == xfce`, xfce enabled |
| groups | guest not in `wheel` |
| AccountsService tmpfiles rule | contains escaped `[User]\nSession=xfce\n`, no real newline, session equals `defaultSession` |
| DEs | hyprland, niri, mango, gnome, kde, cosmic all `false` |
| stylix, bluetooth | `false` |
| tags / controls | tags contain `guest`; base has no guest user and has a DE enabled |

### secure-travel
| Check | Expected |
|-------|----------|
| sysctl | 23 hardening keys (kptr, dmesg, sysrq, perf, bpf, ptrace, redirects, source route, rp_filter, icmp echo broadcasts, syncookies, martians) have the documented values |
| root | `hashedPassword == "!"`, `hashedPasswordFile == null` |
| firewall | enabled, allowed TCP/UDP ports `[]`, `logRefusedPackets` |
| NetworkManager | wifi/ethernet `macAddress == "random"`, one dispatcher script |
| resolved | `DNSOverTLS == "opportunistic"` |
| docker | `virtualisation.docker.enable == false` |
| resolved | `LLMNR == "false"`, `MulticastDNS == "false"` |
| GNOME sharing | `gnome-remote-desktop` and `gnome-user-share` disabled |
| tor-browser | in systemPackages on x86_64 |
| tailscale | `myconfig.services.tailscale.enable == false`, `services.tailscale.enable == false`, `tailscale0` not trusted |
| DEs | gnome only |
| killswitch | script text passes `bash -n` |
| controls | base tailscale on, root not locked in base, helper detects mismatch |

### entertainment (only where the host declares it: the desktop, not the laptop)
| Check | Expected |
|-------|----------|
| DEs | only kde enabled |
| tags | contain `entertainment` |
