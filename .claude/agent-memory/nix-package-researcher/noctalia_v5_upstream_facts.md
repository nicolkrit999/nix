---
name: noctalia-v5-upstream-facts
description: noctalia 5.x (C++ rewrite) facts - bin, msg IPC, config.toml stack, HM built-in programs.noctalia, stylix target, pkgs.noctalia cached
metadata:
  type: project
---

Researched 2026-10-14 (5.2.1, then via a flake input that has since been replaced by pkgs.noctalia). Port plan: ~/momentary/codebase-audit/batches/06-waybar-shells/noctalia-port-research.md.

- Binary is `noctalia` (mainProgram). IPC is `noctalia msg <cmd>`. It exits 1 when the shell is not running, using socket `$XDG_RUNTIME_DIR/noctalia-$WAYLAND_DISPLAY.sock`.
- Key commands:
  - `panel-toggle launcher|control-center|session`
  - `session lock` (idempotent; noctalia also locks on the logind Lock signal)
  - `volume-up`, `media toggle`
- The v4 `ipc call location set` has no IPC replacement. Use config `[location] address` plus `[weather] enabled = true`.
- Config:
  - Hand-written config is every `*.toml` in `~/.config/noctalia/` (`NOCTALIA_CONFIG_HOME`).
  - GUI changes go to `~/.local/state/noctalia/settings.toml`, which wins over the hand-written files.
  - There is no `--config` flag, and v4 config.json is not migrated.
- Home-manager already has a built-in `programs.noctalia` (settings, customPalettes, checkConfig runs `noctalia config validate`). Do not import the flake's homeModules.default, because it disables the built-in.
- The stylix `noctalia` HM target exists and is auto-enabled. It writes theme, palette, font and wallpaper. catppuccin-nix has no noctalia module.
- Packaging: the repo uses nixpkgs `pkgs.noctalia` (modules/nixos/programs/shells/noctalia-main.nix, gated to x86_64) via the HM built-in `programs.noctalia`; there is no noctalia flake input any more. Upstream flake builds linux only (no darwin).
- The GUI writes only to the state settings.toml and never to ~/.config (docs/user/configuration/index.mdx:115). Per-setting Reset falls back to the Nix value. Bars, calendar accounts and monitor tables declared in the config file cannot be deleted from the GUI.
- Caelestia contrast: its GUI (nexus) writes ~/.config/caelestia/shell.json through QSaveFile. A HM store symlink therefore makes every save fail, so it stays install-only. Follow-up: ~/momentary/codebase-audit/batches/06-waybar-shells/noctalia-followup-research.md

Local notes under ~/momentary/codebase-audit/ do not exist on this machine: check the folder exists first; if it is missing ask the user to copy it from the NAS.

**Why:** the repo still had v4 `noctalia-shell ipc call` strings, and these facts took a full source read to establish.
**How to apply:** re-verify the version after flake.lock bumps before reusing the IPC/config facts.
