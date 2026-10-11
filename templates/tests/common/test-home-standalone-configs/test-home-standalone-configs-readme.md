# test-home-standalone-configs

Deep-evaluates the standalone `homeConfigurations` (`moduleSystem == "home"`), which `nix flake check` does not do, and locks in the home-mode (standalone) wiring contracts. Host choices (which WMs/Qt/packages a host enables) are deliberately not asserted.

## Run

```bash
bash templates/tests/common/test-home-standalone-configs/check-common-home-standalone.sh
```

Or from inside the directory:

```bash
bash check-common-home-standalone.sh
```

## How it works

`01-scenario-home-standalone.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads the real `homeConfigurations`. The `pkgsStable` probe uses `extendModules` with a module taking `pkgsStable` and writing its source path into `home.file`. Substituter/key checks compare the home-mode lists with the NixOS minimal host's `nix.settings`, two independent code paths.

`check-common-home-standalone.sh` lists the host names from the scenario, runs one `drvPath` instantiation check per host (no build), then one `nix eval --raw --impure` per attribute. Nothing is built; runtime is about 1-2 minutes. On Darwin the NixOS-comparison checks report `ok` (IFD guard hides `nixosConfigurations`, and `homeConfigurations` is empty there).

## Checks

### instantiation
| Check | Expected |
|-------|----------|
| every `homeConfigurations.*`: `config.home.path.drvPath` and `activationPackage.drvPath` | evaluate to `.drv` store paths |

### home-mode imports
| Check | Expected |
|-------|----------|
| NAS `catppuccin.enable` / `autoEnable` | `true` / `false` |
| `pkgsStable.path` | equals the `nixpkgs-stable` input source |
| `pkgsStable` version vs `nixpkgs` | older |

### nix settings
| Check | Expected |
|-------|----------|
| NAS `nix.settings.extra-substituters` | equals NixOS host list |
| NAS `nix.settings.extra-trusted-public-keys` | equals NixOS host list |
| NAS `nix/nix.conf` | enabled in `xdg.configFile`, substituters non-empty |
