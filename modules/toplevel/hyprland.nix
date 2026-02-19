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
      myconfig,
      ...
    }:
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
    };
}
