---
name: niri-stylix-off-hm-stub
description: niri-flake injects homeModules.stylix whenever NixOS `options ? stylix` (always here) but stylix HM autoImport needs stylix.enable; stylix-off + niri-on needs an HM stylix.enable stub, which collides with any second declaration
metadata:
  type: project
---
niri-flake's nixosModule adds `homeModules.stylix` to `home-manager.sharedModules` whenever the NixOS option set has `stylix`, and this repo always imports the stylix NixOS module. Stylix's own HM auto-import is gated on NixOS `stylix.enable`. So with stylix off, the HM side has no `stylix.enable` option, and niri's `mkIf (config.stylix.enable && ...)` throws `attribute 'enable' missing` once `programs.niri.settings` gets forced, which only happens when niri is enabled.

2026-10-14 (batch 5, G8): modules/nixos/toplevel/niri.nix `nixos.ifEnabled` adds a keyed HM stub `options.stylix.enable` (default false) when `!config.stylix.enable`. The safe-mode and guest specs declare the same stub but turn niri off, so the two never meet.

**Why:** a second plain `options.stylix.enable` declaration while niri is on fails with "already declared in nixos/common.nix". The theming-guards stylixOff twin hit this until its own declaration was removed.

**How to apply:** for a new stylix-off context with niri on, don't declare the HM stub. With niri off, the stub is still needed for other HM readers. Separate leak: with stylix off, users/krit/common/programs/terminal-emulators/kitty.nix still reads the stylix palette unguarded ("one of stylix.image or stylix.base16Scheme must be set"). The specs avoid that by feeding a dummy base16Scheme/image. Related: [[test-stylix-stub-targets]], [[catppuccin-global-enable-gate]].
