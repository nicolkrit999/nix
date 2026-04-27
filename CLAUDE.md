# NixOS & nix-darwin Configuration — CLAUDE.md

## Overview

This repo manages multiple NixOS **and** nix-darwin hosts using the [denix](https://github.com/yunfachi/denix) framework. Denix auto-discovers all `.nix` files under the configured `paths` (see `flake.nix`), then wires them together via `delib.module` and `delib.host`.

Nixpkgs channel: `nixos-25.11`. Home-manager user: `krit`.

## Active Hosts

| Host | Arch | Platform |
|------|------|----------|
| `nixos-desktop` | `x86_64-linux` | NixOS |
| `Krits-MacBook-Pro` | `aarch64-darwin` | nix-darwin |

## Cross-Platform Architecture

The `flake.nix` uses a **3-way module split**: `modules/common/` and `users/krit/common/` are loaded by both platforms; `modules/nixos/` and `users/krit/nixos/` are NixOS-only; `modules/darwin/` and `users/krit/darwin/` are Darwin-only.

### Platform Path Selection

- **NixOS builds** (`moduleSystem == "nixos"`): `./hosts`, `./modules/common`, `./modules/nixos`, `./packages`, `./users/krit/common`, `./users/krit/nixos`
- **Darwin builds** (`moduleSystem == "darwin"`): `./hosts/Krits-MacBook-Pro`, `./modules/common`, `./modules/darwin`, `./users/krit/common`, `./users/krit/darwin`
- **Home builds** (`moduleSystem == "home"`): same as NixOS paths (darwin uses integrated home-manager via nix-darwin)

### IFD Guard for `nix flake check`

`nix flake check` evaluates ALL `nixosConfigurations` regardless of the current machine. Some flake inputs (notably `catppuccin-nix`) use Import From Derivation (IFD) which requires building `aarch64-linux` packages — impossible on Darwin without remote builders.

**Solution:** The `isDarwin` guard uses `builtins.currentSystem` (only available in impure mode) to hide Linux-only outputs when running on Darwin. The fallback `"not-darwin"` ensures outputs are always exposed in pure mode on Linux.

```nix
isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [ "aarch64-darwin" "x86_64-darwin" ];
nixosConfigurations = if isDarwin then {} else generatedNixosConfigs;
```

**Verification commands by platform:**

After making any configuration changes, run the appropriate verification checks based on your current platform.

> **Critical — stage new/renamed files first:** Nix flakes only evaluate git-tracked files. Untracked files are invisible to the evaluator and will cause confusing "option does not exist" or missing-module errors. Before running any verification command, always check for and stage untracked files:
> ```bash
> git status --short   # look for ?? entries
> git add <any-untracked-files>
> ```

#### On Linux (NixOS):

```bash
# 1. Flake check (validates all configurations)
nix flake check

# 2. Dry build for nixos-desktop (x86_64-linux)
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --dry-run
# Or use the nh helper:
nh os test --dry --ask

# 3. Dry build for Darwin (cross-platform validation)
nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run
```

#### On macOS (nix-darwin):

```bash
# 1. Flake check (--impure is REQUIRED on Darwin)
nix flake check --impure

# 2. Dry build for the Darwin host
nix build .#darwinConfigurations.Krits-MacBook-Pro.system --dry-run
```

> **Important:** On Darwin, `--impure` is **required** for `nix flake check` because `builtins.currentSystem` is not available in pure flake evaluation mode.

### Module Block Types by Platform

| Block | NixOS | Darwin | Home-manager |
|-------|-------|--------|--------------|
| `nixos.ifEnabled` / `nixos.always` | System-level NixOS config | Ignored | Ignored |
| `darwin.ifEnabled` / `darwin.always` | Ignored | System-level darwin config | Ignored |
| `home.ifEnabled` / `home.always` | Sets `home-manager.users.<user>.*` | Sets `home-manager.users.<user>.*` | Sets config directly |

- `home.*` blocks work on **both** NixOS and Darwin — they target home-manager regardless of the host platform.
- `nixos.*` blocks are NixOS-only. **Never modify** these when fixing Darwin issues.
- `darwin.*` blocks are Darwin-only. Use these for `system.defaults`, `homebrew`, `users.users`, etc.

## Denix Framework Architecture

### Auto-Discovery

Denix scans the `paths` listed in `flake.nix` and loads every `.nix` file not in `exclude`. No manual imports needed.

### Key API

- `delib.singleEnableOption <default>` — creates a single `enable` boolean option. Prefer this when a module only needs an on/off toggle.
- `delib.moduleOptions { ... }` — creates multiple typed options (used in `constants.nix`). Declare related options as **flat siblings** — never group them under `submodule`. Use `submodule` only for list elements (e.g. `listOfOption (submodule { ... })`).
- Option helpers: `strOption`, `boolOption`, `listOfOption`, `submodule`
- `imports` blocks must be inside a `nixos.always` or `home.always` block, otherwise the rebuild will fail.
- Never redeclare the module name as an option — `options` or `moduleOptions` is sufficient.

## Constants System

Defines shared typed options via `delib.moduleOptions`. All constants are accessible anywhere as `myconfig.constants.<name>`. Each host overrides them in its `myconfig.constants = { ... }` block.

## Theming

Uses stylix + catppuccin-nix. Controlled via `myconfig.constants.theme.base16Theme`, `myconfig.constants.theme.catppuccin`, `myconfig.constants.theme.catppuccinFlavor` / `catppuccinAccent`, and `myconfig.stylix.enable` + per-target overrides in `myconfig.stylix.targets.*`.

## Secrets

Managed with sops-nix + age encryption. Per-user secrets and per-host secrets are kept in separate yaml files under `users/` and `hosts/` respectively. Config at `.sops.yaml`. Never hardcode sensitive values — the repo is public.

## `./templates/`

Contains `.nix` files not written in the denix style. Not auto-discovered; must be imported manually in the desired host (either directly or via a `default.nix` with an `imports` block).
