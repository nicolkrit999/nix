{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "hyprland";
  options.hyprland = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
      constants,
      ...
    }:
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };
    };
}
