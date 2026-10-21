# Modules are self-sustainable

A module must install everything it needs to render or work correctly, instead of relying on some other module happening to ship it. Fonts are the canonical example.

## Rule

If a module names a font family (CSS `font-family`, hyprlock `font_family`, kitty `font_family`, an SDDM theme `Font`, a zathura `font`, ...), the module itself installs the package that provides that family:

- NixOS-level consumers (SDDM greeter, anything read from system fontconfig): `fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];` in the `nixos` block.
- Home-manager consumers (waybar, swaync, hyprlock, walker, vicinae, the krit kitty layer, zathura): `home.packages = [ pkgs.nerd-fonts.jetbrains-mono ]; fonts.fontconfig.enable = true;` in the `home` block. This works on NixOS, on Darwin and in standalone home builds (`moduleSystem == "home"`).

The only exception is a module that explicitly depends on another module that is guaranteed to ship the font. The always-on global list in `modules/nixos/toplevel/common-configuration-nixos.nix` counts as a provider on NixOS only; it is not loaded on Darwin or in standalone home builds, so it is not a substitute.

Duplicates across modules are harmless and intended; do not remove a module's own font package because another module also ships it. Modules that follow the stylix fonts (KDE, GNOME) need nothing, stylix installs the configured packages. The krit alacritty layer follows the stylix fonts too, except in catppuccin mode (stylix target off), where it falls back to its own JetBrainsMono Nerd Font and ships that package itself. The generic `programs.kitty` / `programs.alacritty` modules name no font and install none.

The same principle applies beyond fonts (icon themes, helper binaries, runtime libraries).
