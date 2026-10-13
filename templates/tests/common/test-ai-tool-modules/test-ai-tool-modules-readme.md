# test-ai-tool-modules

Wiring contracts of the AI tool modules in `modules/common/programs/`: the headroom proxy (`headroom.nix`), the claude-code `cowork` toggle and `openrouterAliases` option (`claude-code.nix`) and the codex overlay (`codex.nix`). It does not test whether a host enables any of them: every variant forces its own toggles on `template-host-minimal`.

Why: headroom's address is spelled in two places (unit `ExecStart` and the `headroom-claude` script) and drifts silently; a `python3.withPackages` env would put a second `bin/python` into `home.packages` (collision with the school specialisation's python env); a user unit `After=network.target` is a no-op. `cowork` must stay opt-in, `claude-code.nix` must evaluate without the `users/krit` tree (it reads only its own `openrouterAliases` option, set by `claude-code-wrappers.nix`, never `myconfig.krit.*`), and `pkgs.codex` must come from the `codex-cli-nix` overlay rather than a second nixpkgs import.

That headroom, codex and the claude-code wrappers are off (and the `headroom-proxy` unit absent) in the `guest` and `secure-travel` specialisations is covered by `nixos-spec-contract` (`templates/tests/nixos/test-spec-contract/`), not repeated here.

## Run

From the repo root:

```bash
bash templates/tests/run-tests.sh --only common-ai-tool-modules
# or directly
bash templates/tests/common/test-ai-tool-modules/check-common-ai-tool-modules.sh
```

From inside the directory:

```bash
bash check-common-ai-tool-modules.sh
```

## How it works

`01-scenario-ai-tool-modules.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and builds `template-host-minimal.extendModules` twins, each with only the toggles a check needs (headroom on/off; claude-code on, on with `cowork = true`, off with `cowork = true`; codex on/off). A fifth variant (`shared/`) is a krit-tree-free host built with `denix.lib.configurations` from only the fake host `cc-bare`, `home-manager.nix`, the constants modules and `claude-code.nix`, once as is and once with `openrouterAliases = true`. A probe module exposes the host's final `pkgs.codex`. Results are attrsets of `"ok"` / `"FAIL: ..."` per group.

`check-common-ai-tool-modules.sh` evaluates each group (`headroom`, `cowork`, `codex`, `openrouter`) with one `nix eval --json --impure` and prints a PASS/FAIL line per check. Nothing is built: the headroom package is identified by the store path in `ExecStart` and checked through its `pythonModule` passthru (`toPythonApplication` sets it to `false`); the overlay origin is read from `meta.position`. Runtime about 15 s warm. On Darwin (no `nixosConfigurations`) every check reports `ok`.

## Checks

### headroom

| Check | Expected |
|-------|----------|
| check-unit-present | `headroom-proxy` user unit exists, `WantedBy = [ "default.target" ]` |
| check-unit-off-absent | no `headroom-proxy` unit with headroom disabled (control) |
| check-execstart-port | `ExecStart` is `<store>/bin/headroom proxy ...` with `--port 8787` |
| check-execstart-host-loopback | a `--host` in `ExecStart`, if any, is `127.0.0.1` |
| check-script-probe-address | `headroom-claude` probes `/dev/tcp/127.0.0.1/<ExecStart port>` |
| check-script-base-url | `headroom-claude` sets `ANTHROPIC_BASE_URL="http://127.0.0.1:<port>"`, never names `localhost` or `0.0.0.0` |
| check-unit-no-network-target | `Unit.After` does not contain `network.target` |
| check-package-is-application | the `ExecStart` package is in `home.packages` exactly once, `pname = "headroom-ai"`, `pythonModule = false` |
| check-no-python-env-added | packages headroom adds (on vs off twin) are non-empty and contain no `python3-*-env` |

### claude-code cowork toggle

| Check | Expected |
|-------|----------|
| check-cowork-option-default | declared default of `myconfig.programs.claude-code.cowork` is `false` |
| check-cowork-default-off | claude-code on, cowork unset: `cowork = false`, `services.claude-cowork.enable = false`, no `claude-cowork` user unit |
| check-cowork-drives-service | `cowork = true`: service enabled and the user unit exists |
| check-cowork-needs-claude-code | claude-code off with `cowork = true`: service off, no unit |

### claude-code openrouterAliases

| Check | Expected |
|-------|----------|
| check-option-default-off | declared default of `myconfig.programs.claude-code.openrouterAliases` is `false` |
| check-bare-tree-has-no-krit-options | the bare host really has no `myconfig.krit` (the scenario is the no-krit-tree case) |
| check-bare-no-openrouter-aliases | bare host, claude-code on: evaluates, no `cai-openrouter-*` alias, `caitempplugins` present (control) |
| check-option-alone-drives-aliases | bare host with the option forced true: `cai-openrouter-opus` and more appear |
| check-krit-wrappers-keep-aliases | `template-host-minimal` with `krit.programs.claude-code-wrappers` on: option true and `cai-openrouter-opus` present; with it off (default): option false |

### codex overlay

| Check | Expected |
|-------|----------|
| check-codex-from-overlay | codex on: host `pkgs.codex` `meta.position` lies in the `codex-cli-nix` input |
| check-codex-installed-is-overlay | that package (same drvPath) is in `environment.systemPackages` exactly once |
| check-codex-version-matches-input | its version equals `codex-cli-nix.packages.x86_64-linux.codex.version` |
| check-codex-control-plain-nixpkgs | codex off: `pkgs.codex` is plain nixpkgs (the position check discriminates) |
