{ lib, ... }:
{
  home-manager.users.krit = _: {
    home = {
      username = lib.mkForce "krit";
      homeDirectory = lib.mkForce "/home/krit";
      stateVersion = "25.11";
    };
    programs.home-manager.enable = true;

    # catppuccin-nix Firefox and Starship modules use IFD at evaluation time.
    # Forcing enable=false keeps the let-bindings lazy so no aarch64 derivation
    # is actually built during eval.
    catppuccin.firefox.enable = lib.mkForce false;
    catppuccin.starship.enable = lib.mkForce false;
  };
}
