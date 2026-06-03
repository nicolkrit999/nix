{ delib, ... }:
# Declares myconfig.stylix.{enable,targets} so modules that route stylix
# targets through nixos.ifEnabled (hyprland-main.nix sets
# myconfig.stylix.targets.hyprland.enable = false) can evaluate.
# The real stylix-nixos.nix is excluded because it fetches wallpapers;
# stylix-hm.nix provides the actual stylix color config for lib.stylix.colors.*.
delib.module {
  name = "stylix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    targets = attrsOption { };
  };
}
