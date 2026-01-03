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

      "dbus-update-activation-environment --systemd XDG_SCREENSHOTS_DIR"

      "sh -lc 'sleep 1; XDG_SCREENSHOTS_DIR=${vars.screenshots} caelestia-shell -d'"

    ];
  };
}
