{ inputs, pkgs, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  # sddm-pixie unconditionally accesses config.lib.stylix.colors in its let block,
  # so the stylix module must be loaded with a base16 scheme. No image/wallpaper
  # needed — these tests only care about assertion behavior, not theming.
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };
}
