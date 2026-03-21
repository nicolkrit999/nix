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

This single repo supports **three architectures**: `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. The `flake.nix` uses a **3-way module split** to share common code while isolating platform-specific modules:

### Directory Structure

```
modules/
├── common/          # Shared modules (work on both NixOS and Darwin)
│   ├── config/      # constants.nix lives here
│   ├── programs/    # Shared program configs (bat, git, starship, etc.)
│   ├── services/    # (if any shared services)
│   ├── themes/      # Theme modules (catppuccin.nix - imports catppuccin for all platforms)
│   └── toplevel/    # cachix, home-manager, home-packages, nh
├── darwin/          # Darwin-only modules
│   ├── config/      # Darwin-specific config (currently empty)
│   ├── programs/    # Darwin-specific programs
│   ├── services/    # Darwin-specific services
│   └── toplevel/    # common-configuration-darwin, home-darwin, nix-darwin, stylix-darwin, user-darwin
└── nixos/           # NixOS-only modules
    ├── programs/    # DE/WM configs (hyprland, niri, kde, gnome, cosmic), Linux-only programs
    ├── services/    # Linux services (audio, sddm, hyprlock, swaync, tailscale, etc.)
    └── toplevel/    # boot, bluetooth, mime, common-configuration-nixos, home-nixos, nix-nixos, stylix-nixos, user-nixos

users/krit/
├── common/          # Shared user modules (neovim, yazi, firefox, kitty, etc.)
│   ├── programs/
│   └── sops/        # User secrets (krit-common-secrets-sops.yaml)
├── darwin/          # Darwin-only user modules
│   └── services/    # NAS services for Mac (owncloud, smb, ssh, borg-backup)
└── nixos/           # NixOS-only user modules
    ├── programs/    # cava, dolphin, zathura
    └── services/    # NAS services for Linux, logitech, progressive-web-apps
```

### Platform Path Selection in flake.nix

- **NixOS builds** (`moduleSystem == "nixos"`): `./hosts`, `./modules/common`, `./modules/nixos`, `./packages`, `./users/krit/common`, `./users/krit/nixos`
- **Darwin builds** (`moduleSystem == "darwin"`): `./hosts/Krits-MacBook-Pro`, `./modules/common`, `./modules/darwin`, `./users/krit/common`, `./users/krit/darwin`
- **Home builds** (`moduleSystem == "home"`): same as NixOS paths (darwin uses integrated home-manager via nix-darwin)

### Toplevel Module Split

Critical toplevel modules are duplicated with platform-specific implementations:

| Module | NixOS File | Darwin File |
|--------|------------|-------------|
| common-configuration | `modules/nixos/toplevel/common-configuration-nixos.nix` | `modules/darwin/toplevel/common-configuration-darwin.nix` |
| home | `modules/nixos/toplevel/home-nixos.nix` | `modules/darwin/toplevel/home-darwin.nix` |
| nix | `modules/nixos/toplevel/nix-nixos.nix` | `modules/darwin/toplevel/nix-darwin.nix` |
| stylix | `modules/nixos/toplevel/stylix-nixos.nix` | `modules/darwin/toplevel/stylix-darwin.nix` |
| user | `modules/nixos/toplevel/user-nixos.nix` | `modules/darwin/toplevel/user-darwin.nix` |

These share the same `delib.module { name = "..."; }` so they define the same options, but implementations differ per platform.

### IFD Guard for `nix flake check`

`nix flake check` evaluates ALL `nixosConfigurations` regardless of the current machine. Some flake inputs (notably `catppuccin-nix`) use Import From Derivation (IFD) — e.g., `lib.importTOML` from a built derivation — which requires building `aarch64-linux` packages. This is impossible on Darwin without remote builders.

**Solution in `flake.nix`:** The `isDarwin` guard uses `builtins.currentSystem` (only available in impure mode) to hide Linux-only outputs (`nixosConfigurations`, `homeConfigurations`, `topology`) when running on Darwin. The fallback `"not-darwin"` ensures outputs are always exposed in pure mode (the default on Linux).

```nix
isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [ "aarch64-darwin" "x86_64-darwin" ];
nixosConfigurations = if isDarwin then {} else generatedNixosConfigs;
```

**Verification commands by platform:**

After making any configuration changes, run the appropriate verification checks based on your current platform.

#### On Linux (NixOS):

Run ALL of these checks:

```bash
# 1. Flake check (validates all configurations)
nix flake check

# 2. Dry build for nixos-desktop (x86_64-linux)
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --dry-run
# Or use the nh helper:
nh os test --dry --ask

# 3. Dry build for nixos-arm-vm (aarch64-linux)
nix build .#nixosConfigurations.nixos-arm-vm.config.system.build.toplevel --dry-run

# 4. Dry build for Darwin (cross-platform validation)
nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run
```

#### On macOS (nix-darwin):

Run ALL of these checks:

```bash
# 1. Flake check (--impure is REQUIRED on Darwin)
nix flake check --impure

# 2. Dry build for the Darwin host
nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run
```

> **Important:** On Darwin, `--impure` is **required** for `nix flake check` because `builtins.currentSystem` is not available in pure flake evaluation mode. Running `nix flake check` without `--impure` on Darwin will fail.

### Darwin Host Structure

The darwin host files live under `hosts/Krits-MacBook-Pro/`:
- `default.nix` — `delib.host` definition with constants and module enablement
- `system.nix` — darwin system-level config (Homebrew, macOS defaults, sops secrets)
- `home.nix` — home-manager config (git signing, packages)

Darwin-specific modules now live in `modules/darwin/` and `users/krit/darwin/` (not inside the host directory). Shared modules from `modules/common/` and `users/krit/common/` work on both platforms.

### Linux-Only Features Guard

Some home-manager options only work on Linux (e.g., `xdg.desktopEntries`, `xdg.mimeApps`). In shared modules under `common/`, guard these with:

```nix
{ moduleSystem, lib, ... }:
let
  isNixOS = moduleSystem == "nixos";
in
{
  xdg.desktopEntries.myapp = lib.mkIf isNixOS {
    name = "My App";
    # ...
  };
}
```

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

Defined in `modules/common/programs/shells/shell-aliases.nix`. Key aliases:

| Alias | Command |
|-------|---------|
| `sw` | `cd ~/nix && nh os switch ~/nix` — rebuild and switch |
| `gsw` | `git add -A && nh os switch ~/nix` — stage all + switch |
| `upd` | `nh os switch --update ~/nix` — update flake + switch |
| `swboot` | `nh os boot --update ~/nix` — build for next boot only |
| `swdry` | `nh os test --dry --ask` — dry run |
| `swoff` | switch offline (no substitutes) |
| `cleanup` | `nh clean all` |
| `fmt` | `nix fmt -- **/*.nix` |
| `nfc` | `nix flake check` |
| `cdnix` | `cd ~/nix` |
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

**File:** `modules/common/config/constants.nix`

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
- Per-user: `users/<user>/common/sops/<user>-common-secrets-sops.yaml`
- Per-host: `hosts/<hostname>/<hostname>-secrets-sops.yaml`
- Config: `.sops.yaml` at repo root

## Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point; defines inputs, paths scanned, `mkConfigurations`, `isDarwin` guard, 3-way split |
| `modules/common/config/constants.nix` | Shared typed constants, accessible as `myconfig.constants.*` |
| `modules/common/programs/shells/shell-aliases.nix` | All shell aliases, reads constants at build time |
| `modules/nixos/toplevel/` | NixOS-only toplevel modules (boot, bluetooth, stylix-nixos, etc.) |
| `modules/darwin/toplevel/` | Darwin-only toplevel modules (stylix-darwin, nix-darwin, etc.) |
| `hosts/nixos-desktop/default.nix` | Full real-world NixOS `delib.host` example |
| `hosts/nixos-arm-vm/default.nix` | ARM NixOS host example |
| `hosts/Krits-MacBook-Pro/default.nix` | Darwin `delib.host` example with constants + module enablement |
| `hosts/Krits-MacBook-Pro/system.nix` | Darwin system config (Homebrew, macOS defaults, sops) |
| `modules/nixos/toplevel/hyprland.nix` | Minimal `delib.module` with `singleEnableOption` |
| `hosts/template-host-full/` | Template for new full-featured hosts |
| `hosts/template-host-minimal/` | Template for new minimal hosts |

## `./templates/`
This folder contains any nix files which is not written the `denix` way, they are not auto-discovered and are used to put common and user-specific .nix files which are not meant to use denix, such as specializations
