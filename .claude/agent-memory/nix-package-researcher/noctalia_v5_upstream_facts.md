---
name: noctalia-v5-upstream-facts
description: noctalia 5.x (C++ rewrite) facts - bin, msg IPC, config.toml stack, HM built-in programs.noctalia, stylix target, pkgs.noctalia cached
metadata:
  type: project
---

Researched 2026-10-14 at input a0ef2d02 (5.2.1). Port plan: ~/momentary/codebase-audit/batches/06-waybar-shells/noctalia-port-research.md.

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
- Packaging:
  - The flake builds for x86_64-linux and aarch64-linux only (no darwin).
  - With `nixpkgs.follows` there is no cache hit, so it is a source compile (~18 min).
  - nixpkgs `pkgs.noctalia` 5.2.1 at locked rev 39ad350a is cached on cache.nixos.org.

- Flake input a0ef2d02 is NOT the v5.2.1 tag (6ef43e2b). It is 66 commits ahead (lock-screen PAM fixes, mango template, new options), but VERSION still says 5.2.1. Always run a `gh api compare` check before calling the two packages "identical". Build deps and wrapper match nixpkgs, and the lock screen uses the stock PAM `login` service, so no pam entry is needed.
- The GUI writes only to the state settings.toml and never to ~/.config (docs/user/configuration/index.mdx:115). Per-setting Reset falls back to the Nix value. Bars, calendar accounts and monitor tables declared in the config file cannot be deleted from the GUI.
- Caelestia contrast: its GUI (nexus) writes ~/.config/caelestia/shell.json through QSaveFile. A HM store symlink therefore makes every save fail, so it stays install-only. Follow-up: ~/momentary/codebase-audit/batches/06-waybar-shells/noctalia-followup-research.md

**Why:** the repo still had v4 `noctalia-shell ipc call` strings, and these facts took a full source read to establish.
**How to apply:** re-verify the version and cache status after flake.lock bumps before reusing this.
