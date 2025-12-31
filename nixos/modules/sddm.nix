{
  pkgs,
  lib,
  vars,
  ...
}:
let
  sddmTheme = pkgs.sddm-astronaut.override {
    embeddedTheme = "jake_the_dog";
  };
in
{
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false; # keep x11 for stability
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
