# test-spec-contract

Verifies that every specialization's `lib.mkForce` overrides actually land in the evaluated config.

The fake host enables only the features that specializations override. Every check reads back the option value (or config artifact) from the specialization's configuration and asserts it matches the forced value.

## Run

```bash
bash templates/tests/nixos/test-spec-contract/check-nixos-spec-contract.sh
```

Or from inside the directory:

```bash
bash check-nixos-spec-contract.sh
```

## How it works

`01-scenario-spec-contract.nix` builds a fake fully-featured host then exposes
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
| autostart `.desktop` Exec | points to `guest-welcome` wrapper |

### safe-mode
| Check | Expected |
|-------|----------|
| `myconfig.stylix.enable` | `false` |
| `constants.shell` | `"bash"` |
| `constants.terminal.name` | `"xterm"` |
| `hyprland.enable` | `false` |
| `icewm.enable` | `true` |
| `startx.enable` | `true` |
| `.xinitrc` text | contains `icewm-session` |
| `shellAliases.start-icewm` | `"startx"` |

### deep-focus
| Check | Expected |
|-------|----------|
| `services.swaync.enable` | `true` |

### secure-travel
| Check | Expected |
|-------|----------|
| `bluetooth.enable` | `false` |
| `hyprland.enable` | `false` |
| `services.tailscale.enable` | `false` |
| `programs.nix-ld.enable` | `false` |
| `programs.gnome.enable` | `true` |
| NM `dispatcherScripts` | non-empty |

### entertainment
| Check | Expected |
|-------|----------|
| `programs.kde.enable` | `true` |
| `programs.hyprland.enable` | `false` |

### school
| Check | Expected |
|-------|----------|
| `constants.browser` | `"brave-school"` |
| `constants.editor` | `"nvim"` |
| `school-distrobox-setup` | in `home.packages` |
| `school-distrobox-check` | in `home.packages` |
| `school-distrobox-clear` | in `home.packages` |

### home
| Check | Expected |
|-------|----------|
| `hyprland.monitors` | non-empty list |
