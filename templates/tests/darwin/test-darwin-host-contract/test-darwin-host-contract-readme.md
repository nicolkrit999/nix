# test-darwin-host-contract

Eval-only test with two parts. (1) Genuine host contract of the REAL `darwinConfigurations.Krits-MacBook-Pro` (aarch64-darwin, evaluated from Linux): identity, sops wiring, homebrew guards, dock path consistency, no double Tailscale provider, terminal constant resolving to an enabled program. The Mac is CI-only and never built locally, so these invariants guard that it still evaluates with the intended safety values. (2) Module checks (browser opt-out, network-tools, claude-code mcp secrets, tailscale flag, kitty) on a minimal `minimal-darwin` fixture that enables only the module under test, so they do not depend on which programs or packages the Mac installs.

## Run

From the repo root:

```bash
bash templates/tests/darwin/test-darwin-host-contract/check-darwin-host-contract.sh
```

From inside the directory:

```bash
bash check-darwin-host-contract.sh
```

Runtime is about 30 s (lazy eval, no builds).

## How it works

`01-scenario-darwin-host-contract.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`). Real-host checks read `darwinConfigurations.Krits-MacBook-Pro` directly; values are compared against each other (e.g. `uid` vs `constants.uid`) wherever possible. Fixture checks use `templates/tests/lib/fixture-host-darwin.nix` (`fx.mkDarwin { paths; modules; }`, modules off unless enabled). Each `check-*` attribute is `"ok"` or `"FAIL: ..."`.

`check-darwin-host-contract.sh` runs `nix eval --raw --impure` per check, prints PASS/FAIL, and exits non-zero on any failure.

Controls: real-host variants via `host.extendModules` (cask plus daemon forced on, unknown terminal name) and injected dangling dock entries with invented app names; fixture variants (default browser, `mcpSecrets` overridden, personal module disabled, tailscale cask present/absent, kitty disabled). None of the controls relies on what the Mac enables.

## Checks

### users

| Check | Expected |
|-------|----------|
| `system.primaryUser` | `== constants.user` |
| `constants.user` | `krit` |
| `users.users.<user>.uid` | `== constants.uid` |
| `constants.uid` | `501` |
| `users.knownUsers` | contains the user |
| `users.users.<user>.home` | `/Users/<user>` |
| HM `home.homeDirectory` | `== users.users.<user>.home` |
| `environment.shells` | contains the user's shell at `/run/current-system/sw` |

### system

| Check | Expected |
|-------|----------|
| `ids.gids.nixbld` | `350` |
| `nix.gc.automatic` | `false` |
| `nix.settings.experimental-features` | includes `flakes`, `nix-command` |
| `nixpkgs.hostPlatform.system` | `aarch64-darwin` |
| `config.assertions` | none failing |

### sops (real host)

| Check | Expected |
|-------|----------|
| `SOPS_AGE_KEY_FILE` env, `sops.age.keyFile`, `sops.environment.SOPS_AGE_KEY_FILE` | all equal |
| `sops.age.keyFile` | under the user's home |
| `sops.age.sshKeyPaths`, `sops.gnupg.sshKeyPaths` | `[]` |
| `nix.extraOptions` | `!include <github_fg_pat_token_nix path>` |
| `sops.secrets.github_general_ssh_key` | path `/Users/<user>/.ssh/id_github`, mode `0400` |

### homebrew (real host)

| Check | Expected |
|-------|----------|
| `homebrew.masApps` | `{}` (mas 7.0.0 guard) |
| `homebrew.onActivation.cleanup` | not `zap` |
| `homebrew.onActivation.upgrade` | `false` |

### packages (real host)

| Check | Expected |
|-------|----------|
| terminal, fileManager, editor names | real `pkgs` attrs (no silent fallback) |

### dock / finder (real host)

| Check | Expected |
|-------|----------|
| `dock.persistent-apps` | every `/Applications/Nix Apps/<X>.app` / `~/Applications/Home Manager Apps/<X>.app` entry matches an installed package (`longName`/`pname` of `systemPackages` resp. HM `home.packages`) |
| control | injected dangling HM and Nix Apps entries (invented app name) are both flagged |
| `dock.autohide`, `finder.AppleShowAllExtensions` | `true` |

### tailscale (real host)

| Check | Expected |
|-------|----------|
| `darwinCaskPresent` and `services.tailscale.enable` | never both true (one provider) |
| control | cask forced plus daemon enabled is flagged |

### terminal (real host)

| Check | Expected |
|-------|----------|
| `constants.terminal.name` | `myconfig.krit.programs.<name>.enable` is true |
| control | `terminal.name = "no-such-terminal-xyz"` is flagged |

### home-packages browser opt-out (fixture)

| Check | Expected |
|-------|----------|
| `constants.browser = ""` | no firefox / librewolf / chromium in `systemPackages` |
| control | default `constants.browser` adds firefox |

### network-tools (fixture)

| Check | Expected |
|-------|----------|
| control | `tcpdump` in `systemPackages` |
| Linux-only tools (ethtool, iw, ntopng, suricata, ptcpdump, rsyslog, wavemon, sane-airscan, traceroute, wireless-tools) | absent from `systemPackages` |

### claude-code mcp secrets (fixture)

| Check | Expected |
|-------|----------|
| `claude-code-personal.mcpSecrets[].sopsSecret` | list non-empty (module default), each is a `sops.secrets` key |
| control | overriding `mcpSecrets` replaces the declared secrets |
| control | personal module disabled declares no mcp secret |

### tailscale flag (fixture)

| Check | Expected |
|-------|----------|
| `darwinCaskPresent` | `true` with the `tailscale-app` cask |
| control | without the cask it is `false` |

### kitty (fixture)

| Check | Expected |
|-------|----------|
| kitty `macos_option_as_alt` | `yes` |
| control | kitty disabled: not set |
