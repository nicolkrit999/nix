{ delib
, ...
}:
delib.module {
  name = "krit.services.desktop.local-packages";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      users.users.${myconfig.constants.user}.packages = [ ];
    };
}
