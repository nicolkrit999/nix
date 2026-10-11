# test-secret-service

Regression suite for the single-Secret-Service design: gnome-keyring is the only `org.freedesktop.secrets` provider and the only SSH agent, KWallet is reduced to a frontend, and every Chromium/Electron app is pinned to libsecret. Eval only, no builds.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-secret-service` (name as shown by `--list`); the direct command is below.

From repo root:

```bash
bash templates/tests/nixos/test-secret-service/check-nixos-secret-service.sh
```

From inside the directory:

```bash
bash check-nixos-secret-service.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo (used for mutation checks); by default it is derived from the script location. Both hosts evaluate in parallel. Runs in the `nixos-b` CI group (`test.conf`); 126 s inside the full parallel suite run of 2026-10-11 (standalone is faster).

## How it works

`01-scenario-secret-service.nix` reads the real `nixosConfigurations.<HOST>` (`HOST` env var) and evaluates every check on the base config and on each `specialisation.*` config, so a regression in any session is caught. The `report` attribute is one `label<TAB>result` line per check; the result is `ok` or `FAIL: <config>: <detail>; ...` naming each failing config. `configs` lists what was covered.

The script runs it for `nixos-desktop` and `nixos-laptop` (the laptop is cheap and CI runs it) and prints one line per check and host. An eval error fails the whole host. PAM rules are followed through `include`/`substack`, because `sddm` and `sddm-autologin` only include `login`. The kwalletrc text is parsed as INI. Package pinning is detected by looking for the flag in the derivation attributes, so dropping it from an overlay fails the check.

## Checks

Per config (base and every specialisation):

| Check | Expected |
|-------|----------|
| gnome-keyring is enabled | `services.gnome.gnome-keyring.enable` |
| only org.freedesktop.secrets D-Bus package | exactly one gnome-keyring package on `dbus.packages`; no keepassxc/oo7/pass-secret/ksecret and no package name containing `secret` or `bitwarden`; `passSecretService` off |
| kwalletrc | when plasma6 is on or any dbus package name contains `kwallet`: `[Wallet] First Use=false, Enabled=true`, `[KSecretD] Enabled=false`, `[org.freedesktop.secrets] apiEnabled=false`, `[Migration] MigrateTo3rdParty=false` |
| ksecretd names | enabled HM D-Bus stubs with `Exec=.../bin/false` for `org.kde.kwalletd`, `org.kde.secretservicecompat`, `org.freedesktop.impl.portal.desktop.kwallet` |
| unmasked names | no stub for `org.kde.kwalletd6`, `org.kde.kwalletd5`, `org.freedesktop.secrets` |
| KWallet PAM pieces | under plasma6: `plasma-kwallet-pam` unit disabled, `pam_kwallet_init.desktop` has `Hidden=true` |
| PAM login and sddm | effective rules (after includes) contain `pam_gnome_keyring` |
| PAM sddm-autologin | when present, effective rules contain `pam_gnome_keyring` |
| kwallet PAM | no service has `kwallet.enable` or `pam_kwallet` |
| one SSH agent | gcr-ssh-agent on; `programs.gnupg.agent.enableSSHSupport`, `programs.ssh.startAgent`, HM gpg-agent SSH support and HM ssh-agent all off; `SSH_AUTH_SOCK` fallback to `gcr/ssh` in `extraInit` |
| Secret portal (system and HM) | every `xdg.portal.config.*` key has `org.freedesktop.impl.portal.Secret = gnome-keyring` exactly once |
| portal manifest | `gnome-keyring-portal-manifest` in system and HM `extraPortals` |
| installed browsers | every package whose name contains brave/chromium/google-chrome/vscode (excluding `*-school` launcher scripts that exec the pinned package) carries `--password-store=gnome-libsecret`; the set must be non-empty on the base config |
| FHS-wrapped apps | packages whose name contains claude-desktop or antigravity (substring match, so a `-fhs` rename cannot slip out of the set), when installed, carry the flag |
| HM chromium / helium | pinned when enabled |
| portal keys lowercase | every top-level key of system and HM `xdg.portal.config` equals its lowercase form (xdg-desktop-portal lowercases `XDG_CURRENT_DESKTOP`) |
| HM portal config == system | `home-manager.users.krit.xdg.portal.config` equals `xdg.portal.config` key by key (a divergence makes routing depend on which level wins). The mango flake adds `Inhibit`, `ScreenCast`, `Screenshot` at system level; `modules/nixos/toplevel/xdg-portal.nix` now binds the same `mkForce` values for `mango` in the shared portal config, so the two agree |
| stock portal manifests | system and HM `extraPortals` each contain xdg-desktop-portal-gtk and -kde, and none of gtk/kde/gnome carries the `UseIn=` postFixup patch (only wlr is patched; the permissive patch made kde.portal the deprecated-fallback winner in non-KDE sessions). Which backend xdp really picks is checked by `test-portal-routing` |
| pathsToLink | `environment.pathsToLink` has `/share/xdg-desktop-portal` |
| gnome-keyring.portal text | manifest build text starts with `[portal]`, no indented line, `DBusName=org.freedesktop.secrets`, `Interfaces=org.freedesktop.impl.portal.Secret` |
| gnome-keyring.portal UseIn | contains the desktop name of every WM the config enables (hyprland, mango, niri, kde, gnome, cosmic); which WMs are enabled is not asserted |
| single SSH_AUTH_SOCK source | not in `environment.variables`/`sessionVariables`, `systemd.globalEnvironment`, `systemd.user.settings.Manager`, HM `home.sessionVariables`/`systemd.user.sessionVariables`, nor in any HM config/data/home file text; exactly one `export SSH_AUTH_SOCK=` in `extraInit` |
| broader Electron set | ungoogled-chromium, vscode(-fhs), claude-desktop, antigravity, chromium, brave, google-chrome carry the flag when installed; which apps are installed is not asserted |
| self-test | `carries`, `includes`, `ini` and `secretRoute` accept good samples and reject bad ones (guards the helpers against silently passing everything) |
| portal entry per enabled WM | `xdg.portal.config` has a lowercase key for every WM the config enables (a deleted desktop entry is noticed; which WMs are enabled is not asserted) |
| duplicate HM gnome-keyring unit | `services.gnome-keyring` off, no `gnome-keyring*` HM user service, no `myconfig.programs.gnome-keyring` option |

Per host:

| Check | Expected |
|-------|----------|
| overlay pins | brave, chromium, google-chrome, vscode, signal-desktop, vesktop, teams-for-linux, proton-pass, drawio, xmind, whatsapp-electron, github-desktop, insomnia all carry the flag |
| coverage | base plus at least one specialisation evaluated |

## Mutation checks (verified once)

| Mutation (scratch copy) | Failing check |
|-------------------------|---------------|
| `[KSecretD] Enabled=true` in `kde.nix` | kwalletrc |
| `gnome-keyring` HM module re-added | duplicate HM gnome-keyring unit |
| brave line removed from `libsecret-pinning.nix` | installed browsers, overlay pins |

## Is a NixOS VM runtime test worth adding?

Not now, possibly later for one narrow case. A VM test (login, keyring unlocked, `secret-tool store/lookup` roundtrip) would prove what eval cannot: that `pam_gnome_keyring` really unlocks the login collection, and that no second provider wins the bus name at runtime. But:

- It cannot reproduce the real risks. Those depend on Plasma/mango/uwsm session ordering, the real user's existing `login.keyring` and its password, SDDM, the setcap wrapper and the user-level D-Bus environment, none of which a minimal VM models faithfully.
- Costs are high: a KVM-capable runner (the GitHub runners for this repo are not guaranteed to expose KVM), building a VM closure, minutes per run, and an autologin/PAM setup that differs from the real hosts (the guest case has no password, so the keyring cannot unlock there by design).
- Eval-level checks already cover the config that makes it work (PAM rules, stubs, kwalletrc, portal route, pinning).

Worth adding only if a regression slips through that is specific to the PAM unlock chain. In that case, build a small test on `login` only (not a full desktop): create a user with a password, run a PAM login through `pam_gnome_keyring` and do the `secret-tool` roundtrip on the session bus, plus assert `busctl --user` shows only gnome-keyring owning `org.freedesktop.secrets`. Keep it out of the default suite and run it manually or on a schedule.
