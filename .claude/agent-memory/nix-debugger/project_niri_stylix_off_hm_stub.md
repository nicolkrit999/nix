---
name: niri-stylix-off-hm-stub
description: niri-flake injects homeModules.stylix whenever NixOS `options ? stylix` (always here) but stylix HM autoImport needs stylix.enable; stylix-off + niri-on needs an HM stylix.enable stub, which collides with any second declaration
metadata:
  type: project
---
niri-flake's nixosModule adds `homeModules.stylix` to `home-manager.sharedModules` whenever the NixOS option set has `stylix`, and this repo always imports the stylix NixOS module. Stylix's own HM auto-import is gated on NixOS `stylix.enable`. So with stylix off, the HM side has no `stylix.enable` option, and niri's `mkIf (config.stylix.enable && ...)` throws `attribute 'enable' missing` once `programs.niri.settings` gets forced, which only happens when niri is enabled.

modules/nixos/toplevel/niri.nix `nixos.ifEnabled` adds a keyed (`niri-stylix-off-enable-stub`) HM stub `options.stylix.enable` (default false) when `!config.stylix.enable`. The safe-mode and guest specs declare the same stub but turn niri off, so the two never meet.

**Why:** a second plain `options.stylix.enable` declaration while niri is on fails with "already declared in nixos/common.nix". The theming-guards stylixOff twin hit this until its own declaration was removed.

**How to apply:** for a new stylix-off context with niri on, don't declare the HM stub. With niri off, the stub is still needed for other HM readers. The specs (guest.nix, safe-mode.nix) force stylix off but still feed a catppuccin-mocha base16Scheme. kitty.nix now guards its palette read (`hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success`), so the old unguarded-kitty leak no longer applies; other stylix-palette readers may still need the dummy scheme. Related: [[test-stylix-stub-targets]], [[catppuccin-global-enable-gate]].
