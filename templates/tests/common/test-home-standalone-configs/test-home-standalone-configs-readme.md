# test-home-standalone-configs

Deep-evaluates the standalone `homeConfigurations` (`moduleSystem == "home"`), which `nix flake check` does not do, and locks in the home-mode (standalone) wiring contracts, including the program modules whose system-level install path does not exist in a home build (claude-code overlay and wrapper, codex, herdr, nltchNur, thunderbird accounts, the nh clean timer, sidra theme gating, zen stylix profile names). Host choices (which WMs/Qt/packages a host enables) are deliberately not asserted: the program checks force their own toggles on twins.

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

The `homePrograms` group builds two NAS `extendModules` twins with every toggle forced (`mkForce`): claude-code on with a dummy `mcpSecrets` entry (`test_mcp_secret`, a name only) and a dummy `mcpEnv` (`TEST_STATIC_MARKER`), `krit.programs.claude-code-wrappers` off, thunderbird on; codex, herdr and nltchNur (`packages = [ pkgs.hello ]`) on in one twin and off in the other, thunderbird `accounts` a dummy entry in the "on" twin and empty in the "off" twin. A probe module exposes the home build's final `pkgs.claude-code`, `pkgs.codex` and `pkgs.hello`. Overlay origin is read from `meta.position`; the claude wrapper is read from its `writeShellScriptBin` `.text`; nothing is built. Further twins: `template-host-minimal` (NixOS) with `myconfig.nh.enable` forced on; the NAS with sidra forced on and `customTheme` / `stylix.enable` varied; the NAS and the `krit@*` home builds with zen forced on (host choices are never asserted, only the module contract). The alias pair evaluates `template-host-minimal` with claude-code on and the wrappers on/off.

`check-common-home-standalone.sh` lists the host names from the scenario, runs one `drvPath` instantiation check per host (no build), then one `nix eval --raw --impure` per attribute, and evaluates `homePrograms` once as JSON (one PASS/FAIL line per check). Nothing is built; runtime is about 1-2 minutes. On Darwin the NixOS-comparison checks report `ok` (IFD guard hides `nixosConfigurations`, and `homeConfigurations` is empty there).

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

### home-build programs (`homePrograms`)
| Check | Expected |
|-------|----------|
| check-claude-code-overlay-source | home `pkgs.claude-code` `meta.position` lies in the `claude-code` input (overlay applied) |
| check-claude-code-version-matches-nixos | its version equals `template-host-minimal`'s `pkgs.claude-code.version` |
| check-claude-wrapper-execs-overlay | the home `claude` wrapper runs `exec <that package>/bin/claude` |
| check-claude-binary-in-package | `CLAUDE_BINARY` is `<that package>/bin/.claude-unwrapped` and its `installPhase` installs `$out/bin/.claude-unwrapped` |
| check-claude-wrapper-no-secret-exports | wrapper exports exactly the `mcpEnv` keys (`TEST_STATIC_MARKER`); no `$(cat`, `/run/secrets` or `mcpSecrets` sops path in it |
| check-openrouter-aliases-absent-without-wrappers | wrappers off: no `cai-openrouter-*` key in fish/zsh/bash aliases; `caitempplugins` present (control) |
| check-codex-installed-when-enabled | home `pkgs.codex` from the `codex-cli-nix` overlay; in `home.packages` with codex on, absent with it off |
| check-herdr-installed-when-enabled | herdr input package in `home.packages` [on, off] = [true, false] |
| check-nltch-nur-installed-when-enabled | `nltchNur.packages` entry in `home.packages` [on, off] = [true, false] |
| check-thunderbird-accounts-warning | "accounts is ignored in standalone home-manager builds" warning [accounts set, empty] = [true, false] |
| check-nh-home-timer | NAS: `programs.nh.enable`, `programs.nh.clean.enable`, user timer `nh-clean`; `programs.nh.flake` = `<homeDirectory>/<flakeDir constant>`; `clean.extraArgs` = `--keep-since <gcd> --keep <gcn>` |
| check-nh-no-duplicate-hm-timer-on-nixos | NixOS minimal host with nh on: system `programs.nh.clean.enable` true (control), integrated HM `programs.nh.enable` false and no `nh-clean` user timer (the `moduleSystem == "home"` gate) |
| check-sidra-theme-gating | NAS twin with sidra on: `.config/Sidra/custom-theme.json` exists with exactly the polarity key iff stylix on and `customTheme` on; absent for the other three combinations and with sidra off |
| check-zen-stylix-profile-names | zen off (NAS): `stylix.targets."zen-browser".profileNames = []` (control); zen forced on: `[ "default" ]` on the standalone minimal, `krit@nixos-laptop` and `krit@nixos-desktop` home builds and in the integrated NixOS HM, while the NixOS toplevel `stylix.targets` has no `zen-browser` |
| check-nixos-openrouter-aliases-follow-wrappers | NixOS minimal host, claude-code on: `cai-openrouter-opus` alias [wrappers on, off] = [true, false] |
| check-hyprland-stylix-target-off | `krit@nixos-laptop` and `krit@nixos-desktop` home builds: hyprland module active (control), `stylix.targets.hyprland.enable` is `false` (override lives in `myconfig.ifEnabled`); mutation: forcing `myconfig.stylix.targets.hyprland.enable = true` flips it to `true`, so the check can fail |
