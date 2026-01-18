{ lib, vars, ... }:
{
  imports = [
    ./dev-environments
    ./host-packages
    ./various
  ];

  home-manager.users.${vars.user} = {
    imports =
      [ ]
      ++ lib.optional (builtins.pathExists ./general-hm-modules) ./general-hm-modules

      ++ lib.optional (builtins.pathExists ./host-hm-modules) ./host-hm-modules;
  };
}
