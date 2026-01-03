{
  pkgs,
  lib,
  vars,
  inputs,
  ...
}:
let
  caelestiaShell = inputs.caelestia-shell.packages.${pkgs.system}.with-cli;
in
{
  config = lib.mkIf ((vars.hyprland or false) && (vars.caelestia or false)) {
    home.packages = [
      caelestiaShell
    ];

    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "sh -lc 'sleep 1; caelestia-shell -d'"
    ];
  };
}
