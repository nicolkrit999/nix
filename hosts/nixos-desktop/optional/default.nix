{ lib, vars, ... }:
{
  imports = [
    ./dev-environments
    ./host-packages
  ];

  home-manager.users.${vars.user} = {
    imports =
      [ ]
      ++ lib.optional (builtins.pathExists ./general-hm-modules/home.nix) ./general-hm-modules/home.nix

      ++ lib.optional (builtins.pathExists ./host-hm-modules) ./host-hm-modules;
  };
}
