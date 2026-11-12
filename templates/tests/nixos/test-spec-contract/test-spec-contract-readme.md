# test-spec-contract

Verifies that every specialization's `lib.mkForce` overrides actually land in the evaluated config.

The fake host enables only the features that specializations override. `shared/nixos-extra-x86_64/guest-base.nix` imports the real sops-nix module (the impermanence module comes in through `services.impermanence`) and gives the base the values the guest specialisation overrides (ssh, avahi, docker, podman, `allowed-users`, PAT secret mode, a persisted linger dir). Every check reads back the option value (or config artifact) from the specialization's configuration and asserts it matches the forced value. Nearly every check also has a built-in control: it FAILs if the base host (no specialization) already had the expected value, so an override that changes nothing can no longer pass (the `.xinitrc` content check is the exception). Whether the host itself enables a program is never asserted.

The ryoku specialisation is checked on twins: `ryokuAllOn` is the same fixture with all 27 options of the explicit force-off list set ON (`mkOverride 60 true`), so a force-off missing from `modules/nixos/specializations/ryoku.nix` fails (the shared base cannot carry them, because the secure-travel and entertainment checks need gnome and kde OFF in the base). `ryokuProbeTwin` forces the "stays on" options false in the spec at priority 10 to prove each probe can see them go off; `sddmTwin` has sddm-astronaut on in the base.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-spec-contract` (name as shown by `--list`); the direct command is below.

```bash
bash templates/tests/nixos/test-spec-contract/check-nixos-spec-contract.sh
```

Or from inside the directory:

```bash
bash check-nixos-spec-contract.sh
```

## How it works

`01-scenario-spec-contract.nix` builds a fake host (see `shared/host-spec-contract.nix`; it enables only what the specialisations override, plus the real modules whose options the ryoku force-off list names (impermanence, audio, qt, starship, swayosd, vicinae, walker, skwd-wall, waybar-mango/-niri, auto-cpufreq, tlp) and the krit layers of guest and secure-travel (`users/krit/nixos/specializations/*.nix`, which hold the personal force-offs such as `claude-code-wrappers`) and the modules that merely declare the options `school.nix` sets: sops-secrets, ext-dotfiles, zen-browser, sddm-astronaut/pixie, rclone-mount, yazi-keymap with a `shared/nixos-extra-x86_64/yazi-enable-stub.nix` that only declares `krit.programs.yazi.enable`) then exposes
check results as strings (`"ok"` / `"FAIL: ..."`).

`check-nixos-spec-contract.sh` calls `nix eval --raw --impure` for each attribute and reports pass/fail.

## Checks

### guest
| Check | Expected |
|-------|----------|
| `hyprland.enable` | `false` |
| `myconfig.stylix.enable` | `false` |
| `bluetooth.enable` | `false` |
| `services.swaync.enable` | `false` |
| `services.hypridle.enable` | `false` |
| `services.coffee.enable` | `false` |
| `programs.claude-code.enable` | `false` |
| `programs.claude-desktop.enable` | `false` |
| `programs.codex.enable` | `false` |
| `programs.herdr.enable` | `false` |
| `programs.headroom.enable` | `false` |
| `headroom-proxy` user unit | absent (base present) |
| `krit.programs.claude-code-wrappers.enable` | `false` |
| autostart `.desktop` | Exec ends in `/bin/guest-welcome`, `OnlyShowIn=XFCE;`, absent in base |
| `myconfig.services.tailscale.enable`, `services.tailscale.enable` | `false` |
| `myconfig.services.localsend.enable`, `services.openssh.enable`, `services.avahi.enable` | `false` |
| `virtualisation.docker.enable`, `virtualisation.podman.enable` | `false` |
| `nix.settings.allowed-users` | `[ "krit" ]` (base `[ "@wheel" ]`) |
| sops `github_fg_pat_token_nix` mode | `"0400"` (base `"0444"`) |
| `environment.persistence."/persist".directories` | no `/var/lib/systemd/linger`, other entries kept (base has it) |
| `users.users.guest.extraGroups` | `audio`, `video` only |
| zenity | not in `environment.systemPackages` (the `guest-welcome` autostart still exists) |

### deep-focus
| Check | Expected |
|-------|----------|
| `services.swaync.enable` | `true` (twin whose base forces it off) |
| hyprland / niri / mango `execOnce` | contain `swaync-client -dn` (absent in base) |
| mango `execOnce` | no `zapfast`/`youtube` (base has both), non-empty |

### safe-mode
| Check | Expected |
|-------|----------|
| `myconfig.stylix.enable` | `false` |
| `constants.shell` | `"bash"` (base `fish`) |
| `constants.terminal.name` | `"xterm"` |
| `hyprland.enable` | `false` |
| `fastfetch.enable` | `false` |
| `services.xserver.enable` | `true` (base `false`) |
| tag | `safemode-tty` in `system.nixos.tags` (absent in base) |
| `icewm.enable` | `true` |
| `startx.enable` | `true` |
| `.xinitrc` text | contains `icewm-session` |
| `shellAliases.start-icewm` | `"startx"` |

### secure-travel
| Check | Expected |
|-------|----------|
| `hardware.bluetooth.powerOnBoot` | `false` (base `true`) |
| bluetooth + blueman | still enabled (control: guest has bluetooth off) |
| `hyprland.enable` | `false` |
| tailscale | `myconfig` and `services.tailscale` on (control: guest has it off) |
| `services.tailscale.openFirewall` | `false` (base `true`) |
| `networking.firewall.trustedInterfaces` | `[ "lo" ]` (loopback only, no `tailscale0`; base differs) |
| `services.localsend.enable` | `false` |
| `services.coffee.enable` | `false` |
| `programs.nix-ld.enable` | `false` |
| `programs.claude-code.enable` | `false` |
| `programs.claude-desktop.enable` | `false` |
| `programs.codex.enable` | `false` |
| `programs.herdr.enable` | `false` |
| `programs.headroom.enable` | `false` |
| `headroom-proxy` user unit | absent (base present) |
| `krit.programs.claude-code-wrappers.enable` | `false` |
| `programs.zen.browser.enable` | `false` |
| `constants.browser` | `"librewolf"` (base `"zen-beta"`) |
| `programs.gnome.enable` | `true` |
| `trayscale` in krit `home.packages` | present in secure-travel (the shared tailscale module only installs it under hyprland/niri/mango) |
| user service + timer `secure-travel-exitnode-warn` | exist, `OnActiveSec=45s`, `OnUnitActiveSec=2min` (absent in base) |
| NM `dispatcherScripts` | empty (control: NetworkManager settings of the spec are evaluated) |

### entertainment
| Check | Expected |
|-------|----------|
| `programs.kde.enable` | `true` |
| `programs.hyprland.enable` | `false` |

### school
| Check | Expected |
|-------|----------|
| `constants.browser` | `"zen-beta"` (base fixture `firefox`) |
| `constants.user` | `"krit-school"` (base fixture `krit`): the specialisation is its own account |
| `constants.editor` | `"nvim"` (base fixture `code`) |
| `school-distrobox-setup` | in `home.packages` (absent in base) |
| `school-distrobox-check` | in `home.packages` |
| `school-distrobox-clear` | in `home.packages` |

### home
| Check | Expected |
|-------|----------|
| `hyprland.monitors` | differs from base, non-empty, each entry has `output` and `mode` |

### ryoku
| Check | Expected |
|-------|----------|
| `programs.*` force-off (17: cosmic, gnome, hyprland, kde, mango, niri, caelestia, noctalia, skwdWall, vicinae, walker, swayosd, waybar-hyprland, waybar-mango, waybar-niri, fastfetch, starship) | `false` in the spec; control: the twin base has every one `true` |
| `services.*` force-off (7: auto-cpufreq, coffee, hypridle, sddm-astronaut, sddm-pixie, swaync, tlp) | `false` in the spec; control: twin base `true` |
| `qt`, `bluetooth` | `false` in the spec; control: twin base `true` (stylix is no longer forced off: the spec runs stylix-lite, see test-spec-ryoku) |
| `constants.theme.catppuccin` | `false` (twin base `true`) |
| `programs.ryoku.enable` | `true` in the spec only (control: declared, `false` in the base) |
| `constants.user` | `<base user>-ryoku`, differs from the base user |
| `programs.ryoku.defaultCompositor` | `"hyprland"` (base `null`) |
| stays on | `myconfig.services.audio`, `services.pipewire`, gnome-keyring, `security.polkit`, NetworkManager, sddm, `power-profiles-daemon`, `programs.gpu-screen-recorder` are `true` in the spec; control: forcing each off in the spec (priority 10) makes the same probe read `false` |
| sddm theme | `"ryoku"` in the spec; control: base twin (sddm-astronaut on) has another theme |
| power-profiles-daemon | `true` in the spec; control: the twin base (auto-cpufreq and tlp on) has it forced off |
| sessions | `ryoku-hyprland`, `ryoku-niri`, `ryoku-mango` provided in the spec; control: absent in the base |

## Store independence

The `stylix-stub.nix` fixture uses the inline scheme `templates/tests/lib/scheme-catppuccin-mocha.nix` (and re-pins it in the `guest` and `safemode` specialisations) instead of reading the base16-schemes package; the check script evaluates with `--option allow-import-from-derivation false`, so an IFD fails on a warm store too.

The school specialisation runs as its own user, so the scenario reads its home-manager config under `constants.user` of the specialisation (`specHm`), and `shared/nixos-extra-x86_64/home-base.nix` gives whatever `constants.user` is the home basics the real hosts get from the `homeUserFollowsConstants` flake extension.
