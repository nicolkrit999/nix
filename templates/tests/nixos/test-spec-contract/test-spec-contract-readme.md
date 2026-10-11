# test-spec-contract

Verifies that every specialization's `lib.mkForce` overrides actually land in the evaluated config.

The fake host enables only the features that specializations override. Every check reads back the option value (or config artifact) from the specialization's configuration and asserts it matches the forced value. Nearly every check also has a built-in control: it FAILs if the base host (no specialization) already had the expected value, so an override that changes nothing can no longer pass (the `.xinitrc` content check is the exception). Whether the host itself enables a program is never asserted.

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

`01-scenario-spec-contract.nix` builds a fake host (see `shared/host-spec-contract.nix`; it enables only what the specialisations override) then exposes
check results as strings (`"ok"` / `"FAIL: ..."`).

`check-nixos-spec-contract.sh` calls `nix eval --raw --impure` for each attribute and reports pass/fail.

## Checks

### guest
| Check | Expected |
|-------|----------|
| `hyprland.enable` | `false` |
| `myconfig.stylix.enable` | `false` |
| `bluetooth.enable` | `false` |
| `services.hyprlock.enable` | `false` |
| `services.swaync.enable` | `false` |
| `services.hypridle.enable` | `false` |
| autostart `.desktop` | Exec ends in `/bin/guest-welcome`, `OnlyShowIn=XFCE;`, absent in base |

### safe-mode
| Check | Expected |
|-------|----------|
| `myconfig.stylix.enable` | `false` |
| `constants.shell` | `"bash"` (base `fish`) |
| `constants.terminal.name` | `"xterm"` |
| `hyprland.enable` | `false` |
| `fastfetch.enable` | `false` |
| `icewm.enable` | `true` |
| `startx.enable` | `true` |
| `.xinitrc` text | contains `icewm-session` |
| `shellAliases.start-icewm` | `"startx"` |

### secure-travel
| Check | Expected |
|-------|----------|
| `bluetooth.enable` | `false` |
| `hyprland.enable` | `false` |
| `services.tailscale.enable` | `false` |
| `programs.nix-ld.enable` | `false` |
| `programs.gnome.enable` | `true` |
| NM `dispatcherScripts` | non-empty (base empty) |

### entertainment
| Check | Expected |
|-------|----------|
| `programs.kde.enable` | `true` |
| `programs.hyprland.enable` | `false` |

### school
| Check | Expected |
|-------|----------|
| `constants.browser` | `"brave-school"` |
| `constants.editor` | `"nvim"` (base fixture `code`) |
| `school-distrobox-setup` | in `home.packages` (absent in base) |
| `school-distrobox-check` | in `home.packages` |
| `school-distrobox-clear` | in `home.packages` |

### home
| Check | Expected |
|-------|----------|
| `hyprland.monitors` | differs from base, non-empty, each entry has `output` and `mode` |
