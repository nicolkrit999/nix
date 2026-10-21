# test-darwin-host-contract

Eval-only contract test for the REAL `darwinConfigurations.Krits-MacBook-Pro` (aarch64-darwin, evaluated from Linux). The Mac is CI-only and never built locally, so these invariants are the guard that the host still evaluates with the intended identity, sops wiring, homebrew guards, browser opt-out, dock paths, the tailscale cask/daemon split and the terminal choice.

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

`01-scenario-darwin-host-contract.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads `darwinConfigurations.Krits-MacBook-Pro` directly, so config fixes are verified without a rebuild. Each `check-*` attribute is `"ok"` or `"FAIL: ..."`. Values are compared against each other (e.g. `uid` vs `constants.uid`, HM home vs `users.users.<user>.home`) wherever possible.

`check-darwin-host-contract.sh` runs `nix eval --raw --impure` per check, prints a PASS/FAIL line each, and exits non-zero on any failure.

Two control checks prove the negative checks can bite: `host.extendModules` forces `constants.browser = "firefox"` and asserts firefox then lands in `systemPackages`; `tcpdump` must be present, proving `network-tools` is active before the Linux-only absence check. The `home-packages` name translation (`nvim` -> `neovim`) is mirrored in the scenario.

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

### sops

| Check | Expected |
|-------|----------|
| `SOPS_AGE_KEY_FILE` env, `sops.age.keyFile`, `sops.environment.SOPS_AGE_KEY_FILE` | all equal |
| `sops.age.keyFile` | under the user's home |
| `sops.age.sshKeyPaths`, `sops.gnupg.sshKeyPaths` | `[]` |
| `nix.extraOptions` | `!include <github_fg_pat_token_nix path>` |
| `sops.secrets.github_general_ssh_key` | path `/Users/<user>/.ssh/id_github`, mode `0400` |
| `krit.programs.claude-code-personal.mcpSecrets[].sopsSecret` | each is a `sops.secrets` key (Darwin derives its declarations from the same list) |

### homebrew

| Check | Expected |
|-------|----------|
| `homebrew.masApps` | `{}` (mas 7.0.0 guard) |
| `homebrew.onActivation.cleanup` | not `zap` |
| `homebrew.onActivation.upgrade` | `false` |

### browser opt-out (mechanism only; which programs the host enables is not asserted)

| Check | Expected |
|-------|----------|
| `environment.systemPackages` | no firefox / librewolf / chromium |
| control | browser forced to `firefox` adds firefox |

### dock / finder

| Check | Expected |
|-------|----------|
| `dock.persistent-apps` | every `/Applications/Nix Apps/<X>.app` / `~/Applications/Home Manager Apps/<X>.app` entry matches an installed package (`longName`/`pname` of `systemPackages` resp. HM `home.packages`) |
| `dock.persistent-apps` | no entry in the HM Firefox / VS Code dirs while those HM programs are disabled |
| control | injected dangling HM Firefox + VS Code entries are both flagged |
| `dock.autohide`, `finder.AppleShowAllExtensions` | `true` |

### tailscale

| Check | Expected |
|-------|----------|
| `homebrew.casks` | contains `tailscale-app` |
| `services.tailscale.enable` (nix-darwin daemon) | `false` |
| `myconfig.services.tailscale.darwinCaskPresent` | `true` |
| control | with `homebrew.casks = []`, `darwinCaskPresent` is `false` |

### terminal

| Check | Expected |
|-------|----------|
| `constants.terminal.name` | `myconfig.krit.programs.<name>.enable` is true |
| control | `terminal.name = "alacritty"` (disabled on the host) is flagged |

### packages and home-manager

| Check | Expected |
|-------|----------|
| terminal, fileManager, editor names | real `pkgs` attrs (no silent fallback) |
| control | `tcpdump` in `systemPackages` |
| Linux-only tools (ethtool, iw, ntopng, suricata, ptcpdump, rsyslog, wavemon, sane-airscan, traceroute, wireless-tools) | absent from `systemPackages` |
| kitty `macos_option_as_alt` | `yes` |
