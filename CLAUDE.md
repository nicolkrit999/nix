# NixOS Configuration — CLAUDE.md

## Overview

This repo manages multiple NixOS hosts using the [denix](https://github.com/yunfachi/denix) framework. Denix auto-discovers all `.nix` files under `hosts/`, `modules/`, `packages/`, and `users/` (see `flake.nix` `paths`), then wires them together via `delib.module` and `delib.host`.

Nixpkgs channel: `nixos-25.11`. Home-manager user: `krit`.

## Active Hosts

| Host | Arch | Description |
|------|------|-------------|
| `nixos-desktop` | `x86_64-linux` | Primary desktop (Hyprland/Niri/GNOME/KDE/COSMIC) |
| `nixos-arm-vm` | `aarch64-linux` | ARM VM |

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

  # Apply config when enabled (home-manager level):
  home.ifEnabled = { myconfig, ... }: {
    home.packages = [ ... ];
  };

  # Always apply (regardless of enable):
  myconfig.always = { cfg, ... }: { ... };
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
| `flake.nix` | Entry point; defines inputs, paths scanned, `mkConfigurations` |
| `modules/config/constants.nix` | Shared typed constants, accessible as `myconfig.constants.*` |
| `hosts/nixos-desktop/default.nix` | Full real-world `delib.host` example |
| `hosts/nixos-arm-vm/default.nix` | ARM host example |
| `modules/toplevel/hyprland.nix` | Minimal `delib.module` with `singleEnableOption` |
| `modules/programs/shells/shell-aliases.nix` | All shell aliases, reads constants at build time |
| `hosts/template-host-full/` | Template for new full-featured hosts |
| `hosts/template-host-minimal/` | Template for new minimal hosts |

## `./templates/`
This folder contains any nix files which is not written the `denix` way, they are not auto-discovered and are used to put common and user-specific .nix files which are not meant to use denix, such as specializations
