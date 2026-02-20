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
      nixos,
      ...
    }:
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };
    };
}
