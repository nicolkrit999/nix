# test-home-standalone-configs

Deep-evaluates the standalone `homeConfigurations` (`moduleSystem == "home"`), which `nix flake check` does not do, and locks in the home-mode (standalone) wiring contracts, including the program modules whose system-level install path does not exist in a home build (claude-code overlay and wrapper, codex, herdr, nltchNur, thunderbird accounts). Host choices (which WMs/Qt/packages a host enables) are deliberately not asserted: the program checks force their own toggles on twins.

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

The `homePrograms` group builds two NAS `extendModules` twins with every toggle forced (`mkForce`): claude-code on with a dummy `mcpSecrets` entry (`test_mcp_secret` / `TEST_MCP_SECRET_VAR`, a name only) and a dummy `mcpEnv` (`TEST_STATIC_MARKER`), `krit.programs.claude-code-wrappers` off, thunderbird on; codex, herdr and nltchNur (`packages = [ pkgs.hello ]`) on in one twin and off in the other, thunderbird `accounts` a dummy entry in the "on" twin and empty in the "off" twin. A probe module exposes the home build's final `pkgs.claude-code`, `pkgs.codex` and `pkgs.hello`. Overlay origin is read from `meta.position`; the claude wrapper is read from its `writeShellScriptBin` `.text`; nothing is built. The alias pair evaluates `template-host-minimal` with claude-code on and the wrappers on/off.

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
| check-nixos-openrouter-aliases-follow-wrappers | NixOS minimal host, claude-code on: `cai-openrouter-opus` alias [wrappers on, off] = [true, false] |
