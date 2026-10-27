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

`01-scenario-spec-real-hosts-security.nix` takes `{ host }`, loads `flake.nixosConfigurations.<host>` via `builtins.getFlake` (the runner exports `FLAKE_ROOT` = repo root of the script, overridable; the scenario throws if unset) and exposes `results`, an attrset of `label -> "ok" | "FAIL: ..."`. Each check is wrapped in `tryEval`, so a broken attribute fails only that check. 
`check-nixos-spec-real-hosts-security.sh` evaluates `results` once per host, prints a PASS/FAIL line per check
It exits non-zero on any failure.

The guest persistence checks use an `extendModules` twin that persists the excluded directories (linger, docker, containers, tailscale, flatpak, snapper), so the filter is exercised on both hosts. Guest checks compare independent sources (uid vs gid vs tmpfs `uid=`/`gid=` options vs firewall `--uid-owner` vs slice name; AccountsService session vs `defaultSession`) rather than hardcoded literals. `control:` checks prove the main checks can fail: on the real base config (no guest user, a non-locked root, `allowed-users` and groups differ) and, for everything that depends on what a host chooses to enable, on one `extendModules` exposure twin per host. The twin forces (`mkOverride 75`, between the host's own value and the specialisations' `mkForce`) every exposure service (tailscale, localsend, openssh, avahi, docker, podman), every existing krit nas/cloud/mount module, openlogi, thunderbird, every DE, the tailscale firewall opened and `tailscale0` trusted. Its `control:` rows assert all of that is on in the twin base, and the `guest (twin)` / `secure-travel (twin)` rows assert the specialisations turn it off again, so the guest and secure-travel disabling is shown to bite whatever the real base enables. For localsend the scenario builds two `extendModules` twins of the real host with `myconfig.services.localsend.enable` forced on and off: the enabled twin must open TCP and UDP 53317 and install `programs.localsend.package` system-wide, the disabled twin must not open 53317. That proves the port the secure-travel `allowed*Ports == []` check removes really comes from the module, without asserting whether a host enables localsend.

Scope: only specialisation purpose contracts are asserted (guest isolation, secure-travel hardening and GNOME-only, entertainment). Which specialisations a host declares is a host choice and is not checked. The hosts are the real ones, so no fake host is involved.

secure-travel keeps tailscale on (it is the VPN, an exit node is picked by hand) but outbound only: `openFirewall` off, no trusted interfaces, firewall port lists `mkForce [ ]` (sshd, avahi and localsend are off too), NAS consumers off, mango disabled, bluetooth available with the radio off at boot. ProtonVPN and the root NetworkManager dispatcher kill switch were removed; a user timer warns while no exit node is active.

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
| network services | `myconfig.services.tailscale`, `services.tailscale`, `myconfig.services.localsend`, openssh, avahi, docker, podman all `false` |
| krit modules | claude-code-wrappers, cloud (googleDrive, onedrivePersonal, pcloud, protonDrive), nas (desktop/laptop borg backup, opencloud-mount, smb, sshfs), windows-mount all `enable == false` (one row per path) |
| nix | `nix.settings.allowed-users == [ <main user> ]`; sops `github_fg_pat_token_nix` mode `0400` |
| persistence | guest `/persist` directories lack linger, docker, containers, tailscale, flatpak and snapper dirs and keep the others (twin host that persists them) |
| background units | guest has no `flatpak-managed-install`, `nh-clean`, `snapperd`, snapper timers or `cleanup-trash` units and the openlogi and thunderbird modules are off (control: base has `nh-clean` and `snapperd`) |
| exposure twin (guest) | twin base has every exposure service, every krit nas/cloud/mount module, openlogi, thunderbird and every DE on (controls); the twin's guest has all of them off |
| display manager | autoLogin enabled for `guest` (user exists), `defaultSession == xfce`, xfce enabled |
| groups | guest not in `wheel`; `extraGroups` are `audio` and `video` only |
| packages | no `zenity` in `systemPackages`; `guest-welcome` autostart still exists |
| AccountsService tmpfiles rule | contains escaped `[User]\nSession=xfce\n`, no real newline, session equals `defaultSession` |
| DEs | hyprland, niri, mango, gnome, kde, cosmic all `false` |
| stylix, bluetooth | `false` |
| tags / controls | tags contain `guest`; base has no guest user, a world-readable base PAT mode that the guest still forces to `0400` / `allowed-users`, `networkmanager` in the main user's groups; twin persists linger |

### secure-travel
| Check | Expected |
|-------|----------|
| sysctl | 23 hardening keys (kptr, dmesg, sysrq, perf, bpf, ptrace, redirects, source route, rp_filter, icmp echo broadcasts, syncookies, martians) have the documented values |
| root | `hashedPassword == "!"`, `hashedPasswordFile == null` |
| firewall | enabled, allowed TCP/UDP ports `[]`, `logRefusedPackets` |
| NetworkManager | wifi/ethernet `macAddress == "random"`, no dispatcher scripts |
| resolved | `DNSOverTLS == "opportunistic"` |
| docker | `virtualisation.docker.enable == false` |
| tailscale firewall | `services.tailscale.openFirewall == false`, `trustedInterfaces == [ "lo" ]` (controls: the exposure twin's base opens it and trusts `tailscale0`; twin secure-travel has it closed with only `lo` trusted) |
| bluetooth | `hardware.bluetooth.enable` and `services.blueman.enable` true, `powerOnBoot == false` |
| exit node warn | user service `secure-travel-exitnode-warn` exists and runs the warn script; timer `OnActiveSec=45s`, `OnUnitActiveSec=2min`, `WantedBy=graphical-session.target` (control: absent in base) |
| Proton VPN | no proton+vpn package in system or home packages, no proton autostart entry (controls: detector matches only vpn names, guest autostart detector sees entries) |
| resolved | `LLMNR == "false"`, `MulticastDNS == "false"`, `Domains` does not contain `~.` (inert without global `DNS=`; the `DNSOverTLS`/`LLMNR` checks on the same attrset are the controls) |
| GNOME sharing | `gnome-remote-desktop` and `gnome-user-share` disabled |
| tor-browser | in systemPackages on x86_64 |
| trayscale | `trayscale` in the krit `home.packages` (exit node picker, GNOME session has no WM-gated copy) |
| tailscale | `myconfig.services.tailscale.enable == true`, `services.tailscale.enable == true`, `tailscale0` not trusted |
| DEs | gnome only |
| exposure twin | with docker, localsend and every DE on in the twin base, secure-travel has docker and localsend off and gnome as the only DE |
| localsend | `myconfig.services.localsend.enable == false`, `programs.localsend.enable == false` |
| controls | root not locked in base, helper detects mismatch |

### localsend module (twins of the real host)
| Check | Expected |
|-------|----------|
| enabled module sets programs.localsend.enable | `programs.localsend.enable == true` |
| enabled module opens TCP 53317 / UDP 53317 | 53317 in `allowedTCPPorts` and in `allowedUDPPorts` |
| enabled module installs the localsend package system-wide | `programs.localsend.package` (by pname) in `environment.systemPackages` |
| control: localsend disabled | 53317 in neither port list, `programs.localsend` not wired |

### entertainment (only where the host declares it: the desktop, not the laptop)
| Check | Expected |
|-------|----------|
| DEs | only kde enabled |
| tags | contain `entertainment` |
