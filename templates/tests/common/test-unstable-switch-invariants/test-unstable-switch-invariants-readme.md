# test-unstable-switch-invariants

Locks in the facts introduced by the switch to nixos-unstable: the permanent `nixpkgs-stable` input and `pkgsStable` module argument, the catppuccin `enable`/`autoEnable` pair, the vicinae font override, the atuin keybindings, and the absence of removed `pkgs-unstable` / `nixpkgs-unstable` names.

## Run

```bash
bash templates/tests/common/test-unstable-switch-invariants/check-common-unstable-switch.sh
```

Or from inside the directory:

```bash
bash check-common-unstable-switch.sh
```

## How it works

`01-scenario-unstable-switch.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and evaluates the real `template-host-minimal` NixOS host and the real `Krits-MacBook-Pro` Darwin host. No stubs are involved, so the checks see the production modules. The vicinae checks explicitly enable `myconfig.programs.vicinae` so they test module output, not a default. Module-argument checks use `extendModules` with a probe module that takes `pkgsStable` and writes it into an option; atuin checks enable `myconfig.programs.atuin` and force `constants.shell` per shell. Every check returns `"ok"` or `"FAIL: ..."`.

`check-common-unstable-switch.sh` calls `nix eval --raw --impure` per attribute, then runs two `grep` sweeps over `flake.nix`, `modules`, `hosts`, `users` and `packages` (`*.nix` only, comment-only lines ignored; `templates/` dev flakes and `flake.lock` are intentionally not scanned).

On a Darwin machine `nixosConfigurations` is hidden by the IFD guard, so the NixOS-side checks report `ok` without evaluating anything. The Darwin checks only evaluate module arguments and option values; Darwin was never built on a Mac.

## Checks

### flake inputs
| Check | Expected |
|-------|----------|
| `inputs ? nixpkgs-stable` | `true` |
| `inputs ? nixpkgs-unstable` | `false` |
| `nixpkgs-stable.lib.version` vs `nixpkgs.lib.version` | stable is older |

### pkgsStable module argument
| Check | Expected |
|-------|----------|
| NixOS system module argument `pkgsStable` | `pkgsStable.path` is the `nixpkgs-stable` input and not the main `nixpkgs` input; `.stdenv.hostPlatform.system == "x86_64-linux"` |
| NixOS home-manager module argument `pkgsStable` | same path identity check; `"x86_64-linux"` |
| Darwin system module argument `pkgsStable` | same path identity check; `"aarch64-darwin"` |
| Darwin home-manager module argument `pkgsStable` | same path identity check; `"aarch64-darwin"` |

### catppuccin
| Check | Expected |
|-------|----------|
| NixOS `catppuccin.enable` / `autoEnable` | `true` / `false` |
| NixOS home-manager `catppuccin.enable` / `autoEnable` | `true` / `false` |
| Darwin home-manager `catppuccin.enable` / `autoEnable` | `true` / `false` |

### vicinae
| Check | Expected |
|-------|----------|
| `programs.vicinae.settings.font.normal.family` | `"JetBrainsMono Nerd Font"` |
| `programs.vicinae.settings.font.normal.size` | `12` |
| `myconfig.stylix.targets.vicinae.fonts.enable` and `stylix.targets.vicinae.fonts.enable` | `false` |

### atuin
| Check | Expected |
|-------|----------|
| `programs.atuin.flags` | `[ "--disable-ctrl-r" ]` |
| bash `initExtra` | a line exactly `atuin-bind -m emacs '\C-o' atuin-search-emacs` (commented-out lines do not count) |
| zsh `initContent` | a line exactly `bindkey -M emacs '^o' atuin-search` |
| fish `interactiveShellInit` | a line exactly `bind ctrl-o _atuin_search` |
| fish `interactiveShellInit` | a line exactly `bind -M insert ctrl-o _atuin_search` |
| atuin disabled (control) | no `atuin-search` in bash/zsh/fish init |

### removed names
| Check | Expected |
|-------|----------|
| `pkgs-unstable` in config `.nix` files | no matches |
| `nixpkgs-unstable` in config `.nix` files | no matches |
