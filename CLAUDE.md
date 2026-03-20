# NixOS & nix-darwin Configuration — CLAUDE.md

## Overview

This repo manages multiple NixOS **and** nix-darwin hosts using the [denix](https://github.com/yunfachi/denix) framework. Denix auto-discovers all `.nix` files under the configured `paths` (see `flake.nix`), then wires them together via `delib.module` and `delib.host`.

Nixpkgs channel: `nixos-25.11`. Home-manager user: `krit`.

## Active Hosts

| Host | Arch | Platform | Description |
|------|------|----------|-------------|
| `nixos-desktop` | `x86_64-linux` | NixOS | Primary desktop (Hyprland/Niri/GNOME/KDE/COSMIC) |
| `nixos-arm-vm` | `aarch64-linux` | NixOS | ARM VM |
| `Krits-MacBook-Pro` | `aarch64-darwin` | nix-darwin | MacBook Pro (macOS) |

## Cross-Platform Architecture

This single repo supports **three architectures**: `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. The `flake.nix` uses platform-aware path separation to keep NixOS and nix-darwin configurations isolated:

- **NixOS builds** (`moduleSystem == "nixos"`): scan `./hosts`, `./modules`, `./packages`, `./users` — exclude darwin host dirs.
- **Darwin builds** (`moduleSystem == "darwin"`): scan **only** `./hosts/Krits-MacBook-Pro` and `./hosts/Krits-MacBook-Pro/modules` — self-contained, does not load shared `./modules/`.
- **Home builds** (`moduleSystem == "home"`): same as NixOS paths — exclude darwin hosts (darwin uses integrated home-manager via nix-darwin).

### IFD Guard for `nix flake check`

`nix flake check` evaluates ALL `nixosConfigurations` regardless of the current machine. Some flake inputs (notably `catppuccin-nix`) use Import From Derivation (IFD) — e.g., `lib.importTOML` from a built derivation — which requires building `aarch64-linux` packages. This is impossible on Darwin without remote builders.

**Solution in `flake.nix`:** The `isDarwin` guard uses `builtins.currentSystem` (only available in impure mode) to hide Linux-only outputs (`nixosConfigurations`, `homeConfigurations`, `topology`) when running on Darwin. The fallback `"not-darwin"` ensures outputs are always exposed in pure mode (the default on Linux).

```nix
isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [ "aarch64-darwin" "x86_64-darwin" ];
nixosConfigurations = if isDarwin then {} else generatedNixosConfigs;
```

**Verification commands by platform:**

| Platform | Flake check | Dry build |
|----------|-------------|-----------|
| **Linux** (NixOS) | `nix flake check` | `nh os test --dry --ask` or `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run` |
| **Darwin** (macOS) | `nix flake check --impure` | `nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run` |

> **Important:** On Darwin, `--impure` is **required** for `nix flake check` because `builtins.currentSystem` is not available in pure flake evaluation mode.

### Darwin Host Structure

The darwin host is self-contained under `hosts/Krits-MacBook-Pro/`:
- `default.nix` — `delib.host` definition with constants and module enablement
- `system.nix` — darwin system-level config (Homebrew, macOS defaults, sops secrets)
- `home.nix` — home-manager config (git signing, packages)
- `modules/` — darwin-specific modules (nix settings, user config, common config, constants override)
- Program modules shared with NixOS (bat, fish, git, starship, etc.) live in `modules/programs/` inside the darwin host directory, using `home.ifEnabled` blocks (same as NixOS shared modules)

### Module Block Types by Platform

| Block | NixOS | Darwin | Home-manager |
|-------|-------|--------|--------------|
| `nixos.ifEnabled` / `nixos.always` | System-level NixOS config | Ignored | Ignored |
| `darwin.ifEnabled` / `darwin.always` | Ignored | System-level darwin config | Ignored |
| `home.ifEnabled` / `home.always` | Sets `home-manager.users.<user>.*` | Sets `home-manager.users.<user>.*` | Sets config directly |

- `home.*` blocks work on **both** NixOS and Darwin — they target home-manager regardless of the host platform.
- `nixos.*` blocks are NixOS-only. **Never modify** these when fixing Darwin issues.
- `darwin.*` blocks are Darwin-only. Use these for `system.defaults`, `homebrew`, `users.users`, etc.

## Common Shell Aliases

Defined in `modules/programs/shells/shell-aliases.nix`. Key aliases:

| Alias | Command |
|-------|---------|
| `sw` | `cd ~/nixOS && nh os switch ~/nixOS` — rebuild and switch |
| `gsw` | `git add -A && nh os switch ~/nixOS` — stage all + switch |
| `upd` | `nh os switch --update ~/nixOS` — update flake + switch |
| `swboot` | `nh os boot --update ~/nixOS` — build for next boot only |
| `swdry` | `nh os test --dry --ask` — dry run |
| `swoff` | switch offline (no substitutes) |
| `cleanup` | `nh clean all` |
| `fmt` | `nix fmt -- **/*.nix` |
| `nfc` | `nix flake check` |
| `cdnix` | `cd ~/nixOS` |
| `sops-host` | Edit host-specific sops secrets |
| `sops-common` | Edit user common sops secrets |
| `merge_dev-main` | Merge develop → main, push, return to develop |

## Denix Framework Architecture

### Auto-Discovery

Denix scans the `paths` listed in `flake.nix` and loads every `.nix` file not in `exclude`. No manual imports needed.

### `delib.module` — Defining a Module

```nix
{ delib, ... }:
delib.module {
  name = "programs.myapp";          # Dot-separated name becomes the option path
  options = delib.singleEnableOption true;   # Creates myconfig.programs.myapp.enable (default: true)

  # Apply config when enabled (NixOS system level):
  nixos.ifEnabled = {
    programs.myapp.enable = true;
  };

  # Apply config when enabled (nix-darwin system level):
  darwin.ifEnabled = {
    # darwin-specific system config here
  };

  # Apply config when enabled (home-manager level — works on BOTH NixOS and Darwin):
  home.ifEnabled = { myconfig, ... }: {
    home.packages = [ ... ];
  };

  # Always apply (NixOS system level) (regardless of enable):
  # When using this any option regarding if the delib module is enabled/disabled must not be set as they do not make sense
  nixos.always = { cfg, ... }: { ... };

  # Always apply (nix-darwin system level) (regardless of enable):
  darwin.always = { cfg, ... }: { ... };

  # Always apply (home-manager level) (regardless of enable):
  # When using this any option regarding if the delib module is enabled/disabled must not be set as they do not make sense
  home.always = { cfg, ... }: { ... };
}
```

- A module can have both system and home-manager blocks enabled in the same file depending on the needs. If an import block is needed it must be inside a  `nixos.always` or a `home.always`, otherwise the rebuild fail
- Never write as options the names of the module again as it is not needed, instead using `options` or `moduleOptions` is enough
- `delib.singleEnableOption <default>` — creates a single `enable` boolean option. When a program only require this single option prefer using that
- `delib.moduleOptions { ... }` — creates multiple typed options (used in `constants.nix`)
- Option helpers: `strOption`, `boolOption`, `listOfOption`, `submodule`

### `delib.host` — Defining a Host

```nix
{ delib, ... }:
delib.host {
  name = "nixos-desktop";
  type = "desktop";                        # Arbitrary tag
  homeManagerSystem = "x86_64-linux";

  myconfig = { ... }: {
    # Set constants:
    constants = { hostname = "nixos-desktop"; user = "krit"; ... };

    # Enable/configure modules by their dot-path:
    bluetooth.enable = true;
    programs.hyprland.enable = true;
    services.audio.enable = true;
  };
}
```

The `myconfig` block is where all per-host module configuration lives.

## Constants System

**File:** `modules/config/constants.nix`

Defines shared options via `delib.moduleOptions { ... }`. All constants are accessible anywhere as `myconfig.constants.<name>`.

Key constants and their defaults:

| Constant | Default |
|----------|---------|
| `user` | `"nixos"` |
| `hostname` | `"nixos-host"` |
| `terminal` | `"alacritty"` |
| `shell` | `"bash"` |
| `browser` | `"chromium"` |
| `editor` | `"nano"` |
| `fileManager` | `"dolphin"` |
| `timeZone` | `"Etc/UTC"` |
| `theme.base16Theme` | `"catppuccin-mocha"` |
| `nixImpure` | `false` |
| `cachix.enable` | `false` |

Each host overrides these in its `myconfig.constants = { ... }` block. The `myconfig.always` hook in `constants.nix` exposes the resolved constants via `args.shared.constants = cfg`.

## Module Namespace Conventions

Modules are organized by dot-path prefix matching their filesystem path:

- `programs.*` — programs (bat, fzf, hyprland, niri, git, etc.)
- `services.*` — services (audio, sddm, impermanence, tailscale, etc.)
- `<user>.programs.*` — user-specific programs (kitty, neovim, yazi, etc.)
- `<user>.services.*` — user-specific services (nas, logitech, flatpak, etc.)
- `constants` — the constants block

## Theming

Uses [stylix](https://github.com/danth/stylix) + [catppuccin-nix](https://github.com/catppuccin/nix). Controlled via:
- `myconfig.constants.theme.base16Theme` — stylix base16 theme name
- `myconfig.constants.theme.catppuccin` — bool, whether catppuccin-nix is active
- `myconfig.constants.theme.catppuccinFlavor` / `catppuccinAccent`
- `myconfig.stylix.enable = true` + per-target overrides in `myconfig.stylix.targets.*`

## Secrets

Managed with sops-nix. Secrets files:
- Per-user: `users/<user>/sops/<user>-common-secrets-sops.yaml`
- Per-host: `hosts/<hostname>/<hostname>-secrets-sops.yaml`
- Config: `.sops.yaml` at repo root

## Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point; defines inputs, paths scanned, `mkConfigurations`, `isDarwin` guard |
| `modules/config/constants.nix` | Shared typed constants, accessible as `myconfig.constants.*` |
| `hosts/nixos-desktop/default.nix` | Full real-world NixOS `delib.host` example |
| `hosts/nixos-arm-vm/default.nix` | ARM NixOS host example |
| `hosts/Krits-MacBook-Pro/default.nix` | Darwin `delib.host` example with constants + module enablement |
| `hosts/Krits-MacBook-Pro/system.nix` | Darwin system config (Homebrew, macOS defaults, sops) |
| `hosts/Krits-MacBook-Pro/modules/` | Darwin-specific modules (nix, user, home, common config) |
| `modules/toplevel/hyprland.nix` | Minimal `delib.module` with `singleEnableOption` |
| `modules/programs/shells/shell-aliases.nix` | All shell aliases, reads constants at build time |
| `hosts/template-host-full/` | Template for new full-featured hosts |
| `hosts/template-host-minimal/` | Template for new minimal hosts |

## `./templates/`
This folder contains any nix files which is not written the `denix` way, they are not auto-discovered and are used to put common and user-specific .nix files which are not meant to use denix, such as specializations
