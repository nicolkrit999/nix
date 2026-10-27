# test-spec-real-hosts-security

Security and isolation contracts of the guest, secure-travel and entertainment specialisations, evaluated on the REAL `nixos-desktop` and `nixos-laptop` configurations, so interactions with host and NAS modules are visible. Every control (proof that the specialisation really turns something off) runs on a minimal fixture host instead, so it never depends on what the real hosts enable.

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

Needs `nix`, `jq`, `bash`. Eval-only (no builds); the scenarios evaluate in parallel, 74 s inside the full parallel suite run of 2026-10-11.

## How it works

`01-scenario-spec-real-hosts-security.nix` takes `{ host }`, loads `flake.nixosConfigurations.<host>` via `builtins.getFlake` (the runner exports `FLAKE_ROOT` = repo root of the script, overridable; the scenario throws if unset) and exposes `results`, an attrset of `label -> "ok" | "FAIL: ..."`. Each check is wrapped in `tryEval`, so a broken attribute fails only that check. 
`check-nixos-spec-real-hosts-security.sh` evaluates `results` once per host, prints a PASS/FAIL line per check
It exits non-zero on any failure.

Guest checks compare independent sources (uid vs gid vs tmpfs `uid=`/`gid=` options vs slice name; AccountsService session vs `defaultSession`) rather than hardcoded literals. The real-host `control:` rows are structural only (no guest user in the base, helper detects mismatch, detectors see entries, base has no exit node warn unit).

`02-scenario-spec-fixture-controls.nix` (no host argument, evaluated once as the pseudo-host `fixture`) builds `template-host-minimal` (via `lib/fixture-host.nix`) with `myconfig.specializations.guest` and `secure-travel` enabled and, in the base, everything those specialisations must turn off forced on: tailscale, localsend, openssh, avahi, docker, podman, every existing krit nas/cloud/mount module, openlogi, thunderbird, every DE, the tailscale firewall opened with `tailscale0` trusted, nh clean, snapper and autotrash units, a wide `allowed-users`, a world-readable PAT mode, an unlocked root, and a `/persist` list containing the excluded directories plus one kept directory. `control:` rows assert all of that is on in the fixture base and the specialisation rows assert it is off (or overridden) in the guest / secure-travel, so the disabling is shown to bite whatever the real hosts enable. For localsend two fixtures force the module on and off: the enabled one must open TCP and UDP 53317 and install `programs.localsend.package` system-wide, the disabled one must not.

Scope: only specialisation purpose contracts are asserted (guest isolation, secure-travel hardening and GNOME-only, entertainment). Which specialisations a host declares is a host choice and is not checked. The main checks use the real hosts; the controls use the fixture.

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
| persistence | real guest `/persist` directories lack linger, docker, containers, tailscale, flatpak and snapper dirs |
| background units | guest has no `flatpak-managed-install`, `nh-clean`, `snapperd`, snapper timers or `cleanup-trash` units and the openlogi and thunderbird modules are off (controls in the fixture table) |
| display manager | autoLogin enabled for `guest` (user exists), `defaultSession == xfce`, xfce enabled |
| groups | guest not in `wheel`; `extraGroups` are `audio` and `video` only |
| packages | no `zenity` in `systemPackages`; `guest-welcome` autostart still exists |
| AccountsService tmpfiles rule | contains escaped `[User]\nSession=xfce\n`, no real newline, session equals `defaultSession` |
| DEs | hyprland, niri, mango, gnome, kde, cosmic all `false` |
| stylix, bluetooth | `false` |
| tags / controls | tags contain `guest`; base has no guest user |

### secure-travel
| Check | Expected |
|-------|----------|
| sysctl | 23 hardening keys (kptr, dmesg, sysrq, perf, bpf, ptrace, redirects, source route, rp_filter, icmp echo broadcasts, syncookies, martians) have the documented values |
| root | `hashedPassword == "!"`, `hashedPasswordFile == null` |
| firewall | enabled, allowed TCP/UDP ports `[]`, `logRefusedPackets` |
| NetworkManager | wifi/ethernet `macAddress == "random"`, no dispatcher scripts |
| resolved | `DNSOverTLS == "opportunistic"` |
| docker | `virtualisation.docker.enable == false` |
| tailscale firewall | `services.tailscale.openFirewall == false`, `trustedInterfaces == [ "lo" ]` |
| bluetooth | `hardware.bluetooth.enable` and `services.blueman.enable` true, `powerOnBoot == false` |
| exit node warn | user service `secure-travel-exitnode-warn` exists and runs the warn script; timer `OnActiveSec=45s`, `OnUnitActiveSec=2min`, `WantedBy=graphical-session.target` (control: absent in base) |
| Proton VPN | no proton+vpn package in system or home packages, no proton autostart entry (controls: detector matches only vpn names, guest autostart detector sees entries) |
| resolved | `LLMNR == "false"`, `MulticastDNS == "false"`, `Domains` does not contain `~.` (inert without global `DNS=`; the `DNSOverTLS`/`LLMNR` checks on the same attrset are the controls) |
| GNOME sharing | `gnome-remote-desktop` and `gnome-user-share` disabled |
| tor-browser | in systemPackages on x86_64 |
| trayscale | `trayscale` in the krit `home.packages` (exit node picker, GNOME session has no WM-gated copy) |
| tailscale | `myconfig.services.tailscale.enable == true`, `services.tailscale.enable == true`, `tailscale0` not trusted |
| DEs | gnome only |
| localsend | `myconfig.services.localsend.enable == false`, `programs.localsend.enable == false` |
| controls | helper detects mismatch |

### Fixture controls (`template-host-minimal` with guest and secure-travel, base forces everything on)
| Check | Expected |
|-------|----------|
| base exposure | control: tailscale, localsend, openssh, avahi, docker, podman on in the base; guest has them all off |
| base openlogi / thunderbird | control: both on in the base; off in guest |
| base DEs | control: all six DEs on in the base; none in guest |
| base krit modules | control: every existing krit nas/cloud/mount module on in the base; none in guest |
| background units | control: base has `nh-clean`, `snapperd`, snapper timers and `cleanup-trash`; guest has none |
| persistence | control: base persists the excluded dirs; guest `/persist` is exactly the kept directory |
| allowed-users | control: base differs from `[ user ]`; guest equals `[ user ]` |
| PAT mode | control: base `0444`; guest `0400` |
| root | control: base root not locked; secure-travel `hashedPassword == "!"` |
| tailscale firewall | control: base `openFirewall` true and `tailscale0` trusted; secure-travel closed with only `lo` trusted |
| secure-travel off-switches | docker, localsend, openssh, avahi on in the base and off in secure-travel; gnome the only DE while the base has all |
| localsend | enabled fixture sets `programs.localsend.enable`, opens TCP and UDP 53317 and installs the package; control: disabled fixture has 53317 closed and the program off |

### entertainment (only where the host declares it: the desktop, not the laptop)
| Check | Expected |
|-------|----------|
| DEs | only kde enabled |
| tags | contain `entertainment` |
