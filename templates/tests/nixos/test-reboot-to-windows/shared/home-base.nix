{ lib, ... }:
{
  home-manager.users.krit = _: {
    home = {
      username = lib.mkForce "krit";
      homeDirectory = lib.mkForce "/home/krit";
      stateVersion = "25.11";
    };
    programs.home-manager.enable = true;
  };
}
