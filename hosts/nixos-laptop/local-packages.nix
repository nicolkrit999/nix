{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.laptop.local-packages";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      users.users.${myconfig.constants.user}.packages = with pkgs; [
        grex # Command-line tool for generating regular expressions
      ];
    };
}
