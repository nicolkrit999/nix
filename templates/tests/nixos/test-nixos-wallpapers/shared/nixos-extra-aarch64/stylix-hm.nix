{ inputs, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix = {
    enable = true;
    base16Scheme = import ../../../../lib/scheme-catppuccin-mocha.nix;
  };
}
