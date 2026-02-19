{
  pkgs,
  lib,
  vars,
  ...
}:
let
  sddmTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "hyprland_kath";
    themeConfig = {
      HourFormat = "hh:mm AP";
    };
  };
in
{
  services.xserver.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    package = lib.mkForce pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";

    extraPackages = with pkgs; [
      kdePackages.qtsvg # Keep for the theme
      kdePackages.qtmultimedia # Keep for the theme
      #kdePackages.qtvirtualkeyboard
    ];
  };

  /*
    systemd.services.sddm.environment = {
      QT_IM_MODULE = "qtvirtualkeyboard";
      QT_VIRTUALKEYBOARD_DESKTOP_DISABLE = "0";
    };

    environment.etc."sddm.conf.d/virtual-keyboard.conf".text = ''
      [General]
      InputMethod=qtvirtualkeyboard
    '';
  */

  environment.systemPackages = [
    sddmTheme
    pkgs.bibata-cursors
  ];

  services.displayManager.autoLogin = {
    enable = false;
    user = vars.user;
  };

  services.getty.autologinUser = null;
}
