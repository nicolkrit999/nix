{ delib, ... }:
delib.module {
  name = "nh";
  options.nh = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 30d --keep 20";
        flake = "/home/${myconfig.constants.user}/nixOS";
      };
    };
}
