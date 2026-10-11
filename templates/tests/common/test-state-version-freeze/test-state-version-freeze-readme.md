# test-state-version-freeze

Pins `system.stateVersion` / `home.stateVersion` of every real host and checks that the independent sources of `home.stateVersion` agree. A bump is one-way (Postgres majors, HM defaults) and is forbidden by CLAUDE.md.

## Run

```bash
bash templates/tests/common/test-state-version-freeze/check-common-state-version-freeze.sh
```

Or from inside the directory:

```bash
bash check-common-state-version-freeze.sh
```

## How it works

`01-scenario-state-version-freeze.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads attributes of the real `nixosConfigurations`, `darwinConfigurations` and `homeConfigurations`. Each check returns `"ok"` or `"FAIL: ..."`. `home.stateVersion` is also hard-coded in both `krit.home.base` modules (`users/krit/{nixos/shared,darwin}/home/home-base.nix`); the scenario parses those literals from the source files and compares them to the per-host constants. The controls extend the desktop config with different `homeStateVersion` values to prove the contract bites.

`check-common-state-version-freeze.sh` runs `nix eval --raw --impure` per check, prints PASS/FAIL, exits non-zero on any failure. Eval only, about 30 s.

## Checks

### nixos-desktop, nixos-laptop
| Check | Expected |
|-------|----------|
| `system.stateVersion` | `"25.11"` |
| `constants.homeStateVersion` | `"25.11"` |
| HM `home.stateVersion` | `"25.11"` |
| HM `home.stateVersion` vs constant | equal |

### template-host-minimal
| Check | Expected |
|-------|----------|
| `system.stateVersion` | `"25.11"` |
| HM `home.stateVersion` | `"26.05"` |
| HM vs `constants.homeStateVersion` | equal |

### Krits-MacBook-Pro
| Check | Expected |
|-------|----------|
| `system.stateVersion` | `4` |
| `constants.darwinStateVersion` | `4` |
| HM `home.stateVersion` | `"25.11"` |
| HM vs `constants.homeStateVersion` | equal |

### krit@Nicol-NAS
| Check | Expected |
|-------|----------|
| `home.stateVersion` | `"26.05"` |
| vs `constants.homeStateVersion` | equal |
| `krit.home.base.enable` | `false` (its hard-coded 25.11 would conflict with 26.05) |

### home-base literals
| Check | Expected |
|-------|----------|
| literal parsed from nixos / darwin `home-base.nix` | found |
| nixos literal vs desktop and laptop constants | equal |
| darwin literal vs darwin constant | equal |

### Controls
| Check | Expected |
|-------|----------|
| `homeStateVersion = null` | eval fails (no-default contract) |
| `homeStateVersion = "25.11"` | eval succeeds |
| `homeStateVersion = "99.99"` | eval fails (conflicts with home-base literal) |
