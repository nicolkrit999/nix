{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "programs.niri";

  nixos.ifEnabled =
    {
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
