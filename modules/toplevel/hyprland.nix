{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.hyprland";

  nixos.ifEnabled =
    {
      nixos,
      ...
    }:
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
    };
}
