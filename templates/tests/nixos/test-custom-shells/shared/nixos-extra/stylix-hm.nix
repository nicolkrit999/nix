{ inputs, pkgs, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  # Provide a base16 scheme so lib.stylix.colors.* can be computed.
  # No image/wallpaper needed for eval — tests only need color values.
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };
}
