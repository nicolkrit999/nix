{ config, lib, ... }:
let
  user = config.myconfig.constants.user;
in
{
  home-manager.users.${user} = _: {
    home = {
      username = lib.mkForce user;
      homeDirectory = lib.mkForce "/home/${user}";
      stateVersion = "25.11";
    };
    programs.home-manager.enable = true;
  };
}
