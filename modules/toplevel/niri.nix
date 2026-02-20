{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "niri";
  options.niri = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };
    };
}
