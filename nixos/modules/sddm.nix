{
  pkgs,
  lib,
  vars,
  ...
}:
let
  # Reference for themes:
  # Files: https://github.com/Keyitdev/sddm-astronaut-theme/tree/master/themes
  sddmTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "hyprland_kath"; # do not include ".conf" at the end
    themeConfig = {
      # Clock format. The default is 24/h format. If opting for the default these "themConfig" block can be removed
      # "hh:mm AP" = 08:00 PM
      # "HH:mm"    = 20:00
      HourFormat = "hh:mm AP";
      #DateFormat = ""; # "Some theme may not support this. Commmented because i like the default but kept for reference
    };
  };
in
{
  services.xserver = {
    excludePackages = [ pkgs.xterm ];
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = lib.mkForce pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";

    # Dependencies go here so SDDM can load them
    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
    ];
  };

  # Theme goes here so it links to /run/current-system/sw/share/sddm/themes
  environment.systemPackages = [
    sddmTheme
    pkgs.bibata-cursors
  ];

  services.displayManager.autoLogin = {
    enable = false;
    user = vars.user;
  };

  services.displayManager.defaultSession = lib.mkIf vars.hyprland "hyprland-uwsm";
  services.getty.autologinUser = null;
}
