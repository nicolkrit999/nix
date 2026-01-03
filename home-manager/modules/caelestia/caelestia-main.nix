{
  pkgs,
  lib,
  vars,
  inputs,
  ...
}:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  config = lib.mkIf ((vars.hyprland or false) && (vars.caelestia or false)) {
    programs.caelestia = {
      enable = true;
      cli.enable = true;
      systemd.enable = false;

      settings = {
        background.enabled = false;
        paths.wallpaperDir = "~/Pictures/Wallpapers";
        recorder.path = "~/Videos";

        # Dynamic hosts settings
        services.useFahrenheit = vars.caelestiaUseFahrenheit or false;
      };
    };

    home.packages = [
      inputs.caelestia-shell.packages.${pkgs.system}.with-cli
    ];

    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "dbus-update-activation-environment --systemd XDG_SCREENSHOTS_DIR"
      "sh -lc 'sleep 1; env PATH=/run/wrappers/bin:$PATH XDG_SCREENSHOTS_DIR=${vars.screenshots} caelestia-shell -d'"
    ];
  };
}
