# NixOS & nix-darwin Configuration - CLAUDE.md

## ⚠️ Specialized agents exist - use them, not the main loop

This repo has dedicated subagents covering nearly every recurring task: writing config, researching packages/options, checking cross-platform compat, verifying builds, debugging failures, linting, and writing tests. **If a task matches one of these agents, delegate to that agent instead of doing the work in the main conversation loop.** This is not optional. The main loop must never itself run package research, `nix flake check`/dry-builds, or failure debugging when an agent exists for it - these are exactly the token-heavy operations that should stay off the main context.

`nix-config-architect` is the hub: it authors/modifies config directly, but for anything with a more specific agent it delegates rather than doing that piece itself. The other agents delegate back to it or to each other in a fixed loop - know these links so you route work correctly instead of picking whichever agent sounds closest:

| Agent | Role | Delegates to | Never does |
|-------|------|---------------|-------------|
| `nix-config-architect` | **Hub / general.** Authors or modifies config: modules, DE/WM enablement, sops-nix secrets, hosts, per-host constants, package/service integration, stylix/catppuccin theming, disko, home-manager. Default for any config-writing task with no more specific agent. | `nix-checker` (verify), `nix-package-researcher` (lookups), `nix-debugger` (diagnose failures), `nix-compat-checker` (cross-arch), `nix-test-author` (tests), `nix-syntax-linter` (lint sweeps) | Package/option lookups, cross-arch verification, root-causing failures, running the test suite - hand these off instead of doing them inline. |
| `nix-package-researcher` | Pure read-only lookup: does package/attribute X exist, option paths, channel availability, binary-cache status, version history. | - | Making config changes - always hands findings back to `nix-config-architect`. |
| `nix-compat-checker` | Cross-platform/cross-arch compat: will it build on aarch64-darwin, is a Linux-only option safe in a shared module, correct module placement (common/nixos/darwin), IFD-guard correctness, specialisations. Runs per-arch dry-builds + the arch-compat test. | `nix-config-architect` (for fixes beyond a compat check) | Broad config authoring unrelated to compat. |
| `nix-checker` | Read-only verification: `nix flake check`, per-host dry-builds, templates/tests suite. Run after any change, or on "verify"/"check the build"/"does it evaluate"/"run flake check"/"dry build"/"run the tests". | `nix-debugger` (on failure needing root-cause), `nix-config-architect` (on failure needing a config fix) | Modifying config or diagnosing *why* something failed - it only reports pass/fail with exact errors. |
| `nix-debugger` | Root-causes a failing build/eval/rebuild: eval errors, type errors, "option does not exist", broken imports, IFD failures, sops decryption errors, module conflicts, renamed/removed attrs. Diagnoses **and** applies the fix. | `nix-checker` (always re-verifies after fixing) | Leaving a fix unverified - every fix loops back through `nix-checker`. |
| `nix-syntax-linter` | Fast read-only syntax/convention checks, no evaluation: parse errors, formatting drift, denix/repo anti-patterns. | `nix-config-architect` (applies the actual fixes) | Fixing anything itself - it only flags. |
| `nix-test-author` | Writes/improves tests and manages the `run-tests.sh` registry. | `nix-checker` (to actually *run* the suite) | Running the test suite - that's `nix-checker`'s job. |

**Rule of thumb:** before researching a package/option, verifying a build, debugging a failure, checking cross-arch compat, linting, or writing tests yourself, ask "is there an agent for this?" If yes, use it - don't do it in the main loop. This holds with no exceptions for the operations the table lists as agent-owned (`nix flake check`, dry-builds, package/option research, failure debugging, cross-arch checks, lint sweeps, test-suite runs) - there is no "but it's quick" or "but I already have the context" carve-out; a matching agent is always used, even for a single follow-up command after you already diagnosed the issue yourself. Only work directly when NO agent's role matches the operation at all: quick one-line answers, reading a single file to answer a question, or config-writing edits `nix-config-architect` would itself make inline (its own delegated-away pieces still don't count - see its "Never does" column).

## RTK (token optimization)

RTK is active via a `PreToolUse` hook - Bash commands are auto-rewritten (e.g. `git status` → `rtk git status`).
The hook does **not** cover built-in `Read`/`Grep`/`Glob` tools. Prefer shell equivalents (`cat`, `grep`, `find`) over built-in tools when the output would benefit from filtering, so RTK can intercept it.

## Overview

This repo manages multiple NixOS **and** nix-darwin hosts using the [denix](https://github.com/yunfachi/denix) framework. Denix auto-discovers all `.nix` files under the configured `paths` (see `flake.nix`), then wires them together via `delib.module` and `delib.host`.

Nixpkgs channel: `nixos-26.05`. Home-manager user: `krit`.

## ⛔ `stateVersion` is NEVER bumped

`system.stateVersion`, `home.stateVersion`, and the `myconfig.constants.homeStateVersion` / `stateVersion` defaults are **frozen at the release each host was first installed under**. Most hosts in this repo are pinned at `"25.11"`. **Do not change these values when bumping nixpkgs channels.** No exceptions, no "I'll just bump it on this one host", no search-and-replace.

`stateVersion` is *not* a "current channel" marker (that's `config.system.nixos.release`, read-only). It is a backward-compatibility contract that pins the **defaults of stateful modules** to the release at install time. Bumping it silently changes runtime behavior. Concrete hazards:

- **PostgreSQL major version**: `services.postgresql.package` is defaulted from stateVersion. A bump swaps Postgres majors at the next rebuild; the on-disk cluster in `/var/lib/postgresql/<old>/` is incompatible with the new binary and the service refuses to start until you manually run `pg_upgrade`. Same trap historically for MySQL/MariaDB defaults.
- **Home-manager program defaults**: most of the warnings we silenced during the 25.11 → 26.05 migration (`gtk.gtk4.theme`, `programs.yazi.shellWrapperName`, `wayland.windowManager.hyprland.configType`, `programs.neovim.withRuby`/`withPython3`, `xdg.userDirs.setSessionVariables`) are gated on `home.stateVersion < "26.05"`. Bumping `home.stateVersion` would flip **all of them simultaneously with no warning**, mid-session, with no straightforward way to flip them back.
- **systemd-tmpfiles, /etc, /var layouts, ZFS/Btrfs pool feature flags**: various modules migrate state or change file ownership only when stateVersion crosses a cutoff. Those migrations are one-way.
- **It is one-way.** Reverting the value back to `"25.11"` does NOT undo any migration that already ran.
- **It is per-host.** Each host has its own stateVersion because each was installed under a different release. A repo-wide search-and-replace is always wrong.

The NixOS manual is explicit on this - `options.system.stateVersion` description: "Most users should never change this value after the initial install." Same warning lives in the home-manager manual for `home.stateVersion`.

If you genuinely need to "modernize" a host (adopt the new defaults), do it **one option at a time, explicitly**, in the per-host or per-module Nix code. Never by touching stateVersion.

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

`nix flake check` evaluates ALL `nixosConfigurations` regardless of the current machine. Some flake inputs (notably `catppuccin-nix`) use Import From Derivation (IFD) which requires building `aarch64-linux` packages - impossible on Darwin without remote builders.

**Solution:** The `isDarwin` guard uses `builtins.currentSystem` (only available in impure mode) to hide Linux-only outputs when running on Darwin. The fallback `"not-darwin"` ensures outputs are always exposed in pure mode on Linux.

```nix
isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [ "aarch64-darwin" "x86_64-darwin" ];
nixosConfigurations = if isDarwin then {} else generatedNixosConfigs;
```

**Verification commands by platform:**

After making any configuration changes, run the appropriate verification checks based on your current platform.

> **Critical - stage new/renamed files first:** Nix flakes only evaluate git-tracked files. Untracked files are invisible to the evaluator and will cause confusing "option does not exist" or missing-module errors. Before running any verification command, always check for and stage untracked files:
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

- `home.*` blocks work on **both** NixOS and Darwin - they target home-manager regardless of the host platform.
- `nixos.*` blocks are NixOS-only. **Never modify** these when fixing Darwin issues.
- `darwin.*` blocks are Darwin-only. Use these for `system.defaults`, `homebrew`, `users.users`, etc.

## Denix Framework Architecture

### Auto-Discovery

Denix scans the `paths` listed in `flake.nix` and loads every `.nix` file not in `exclude`. No manual imports needed.

### Key API

- `delib.singleEnableOption <default>` - creates a single `enable` boolean option. Prefer this when a module only needs an on/off toggle.
- `delib.moduleOptions { ... }` - creates multiple typed options (used in `constants.nix`). Declare related options as **flat siblings** - never group them under `submodule`. Use `submodule` only for list elements (e.g. `listOfOption (submodule { ... })`).
- Option helpers: `strOption`, `boolOption`, `listOfOption`, `submodule`
- `imports` blocks must be inside a `nixos.always` or `home.always` block, otherwise the rebuild will fail.
- Never redeclare the module name as an option - `options` or `moduleOptions` is sufficient.

## Constants System

Defines shared typed options via `delib.moduleOptions`. All constants are accessible anywhere as `myconfig.constants.<name>`. Each host overrides them in its `myconfig.constants = { ... }` block.

## Theming

Uses stylix + catppuccin-nix. Controlled via `myconfig.constants.theme.base16Theme`, `myconfig.constants.theme.catppuccin`, `myconfig.constants.theme.catppuccinFlavor` / `catppuccinAccent`, and `myconfig.stylix.enable` + per-target overrides in `myconfig.stylix.targets.*`.

## Secrets

Managed with sops-nix + age encryption. Per-user secrets and per-host secrets are kept in separate yaml files under `users/` and `hosts/` respectively. Config at `.sops.yaml`. Never hardcode sensitive values - the repo is public.

## `./templates/`

Contains `.nix` files not written in the denix style. Not auto-discovered; must be imported manually in the desired host (either directly or via a `default.nix` with an `imports` block).
