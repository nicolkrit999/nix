{ lib, ... }:
{
  home-manager.users.krit = { ... }: {
    home.username = lib.mkForce "krit";
    home.homeDirectory = lib.mkForce "/home/krit";
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
