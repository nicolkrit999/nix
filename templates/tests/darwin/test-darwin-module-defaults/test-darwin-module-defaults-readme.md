# test-darwin-module-defaults

Eval-only test of the module-derived defaults of the darwin toplevel modules (`stylix-darwin`, `common-configuration-darwin`, `nix-darwin`, `user-darwin`, `home-packages-darwin`) on the REAL `Krits-MacBook-Pro`.

Covers gap #8 (B10). Does not duplicate `test-darwin-host-contract` (primaryUser, uid, dock/finder, nixbld, gc, masApps, resolved pkgs) or `test-minimal-defaults` (bare constants-only host). Which programs the host enables is not asserted; only how the modules turn constants into settings.

## Run

From the repo root:

```bash
bash templates/tests/darwin/test-darwin-module-defaults/check-darwin-module-defaults.sh
```

Or through the runner: `bash templates/tests/run-tests.sh --only darwin-module-defaults`.

From inside the directory:

```bash
bash check-darwin-module-defaults.sh
```

Runtime is well under a minute (lazy eval, no builds).

## How it works

`01-scenario-darwin-module-defaults.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads `darwinConfigurations.Krits-MacBook-Pro`, so config fixes are verified without a rebuild. Each `check-*` attribute is `"ok"` or `"FAIL: ..."`. `check-darwin-module-defaults.sh` runs `nix eval --raw --impure` per check and exits non-zero on any failure.

Each derived value is compared with the constant it comes from (polarity, hostname, darwinStateVersion, catppuccin, shell, editor), or checked against a forced variant of the host built with `extendModules` (light polarity, stylix off, zsh/bash, helix editor, alacritty terminal, bogus fileManager). `system.stateVersion` is only read and compared, never changed.

## Checks

### stylix-darwin

| Check | Expected |
|-------|----------|
| `check-stylix-enabled` | stylix.enable (myconfig.stylix.enable default) |
| `check-stylix-off-control` | control: myconfig.stylix.enable = false turns stylix.enable off |
| `check-stylix-polarity` | stylix.polarity follows constants.theme.polarity |
| `check-stylix-scheme` | stylix.base16Scheme is <base16-schemes>/share/themes/<base16Theme>.yaml |
| `check-stylix-fonts` | stylix monospace/sansSerif/serif all JetBrainsMono Nerd Font family |
| `check-stylix-font-sizes` | stylix font sizes terminal 14 / desktop 12 / popups 10 |

### HM stylix targets

| Check | Expected |
|-------|----------|
| `check-hm-targets-always-off` | HM stylix.targets neovim/rofi/gtksourceview are disabled |
| `check-hm-targets-follow-catppuccin` | HM stylix bat/lazygit/starship/tmux targets == !constants.theme.catppuccin |
| `check-hm-targets-override-control` | control: myconfig.stylix.targets.bat.enable = false overrides the default |

### appearance defaults

| Check | Expected |
|-------|----------|
| `check-dark-style-dark` | NSGlobalDomain.AppleInterfaceStyle for polarity dark |
| `check-light-style-null` | control: polarity light leaves AppleInterfaceStyle unset (null) |
| `check-polarity-is-dark` | this host's polarity (guards the dark branch above) |

### common-configuration-darwin and nix-darwin

| Check | Expected |
|-------|----------|
| `check-touchid` | sudo_local touchIdAuth + reattach |
| `check-allow-unfree` | nixpkgs.config.allowUnfree |
| `check-state-version` | system.stateVersion == constants.darwinStateVersion |
| `check-hostnames` | networking.hostName == computerName == constants.hostname |
| `check-hm-backup-ext` | home-manager.backupFileExtension |
| `check-login-shells` | programs.zsh and programs.fish enabled system-wide |
| `check-nix-index` | programs.nix-index.enable (nix-index-database darwin module imported) |
| `check-nix-path` | nix.nixPath |
| `check-auto-optimise` | nix.settings.auto-optimise-store |

### user-darwin shell mapping

| Check | Expected |
|-------|----------|
| `check-shell-fish` | constants.shell fish -> user shell pname |
| `check-shell-zsh` | control: constants.shell zsh -> user shell pname |
| `check-shell-bash` | control: constants.shell bash -> bashInteractive |

### home-packages-darwin roles

| Check | Expected |
|-------|----------|
| `check-role-enabled-program-not-doubled` | terminal kitty is an enabled program, so home-packages adds no system kitty |
| `check-role-terminal-control` | control: a terminal whose program is disabled (alacritty) lands in systemPackages |
| `check-role-editor-control` | control: constants.editor = helix installs the helix package |
| `check-role-editor-translation` | editor nvim is translated to pkgs.neovim (no 'nvim' attr warning) |
| `check-role-no-warnings` | no home-packages warning on the real host (empty browser is a silent opt-out) |
| `check-role-warning-control` | control: a role naming a non-package emits the home-packages warning |
