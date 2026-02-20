{
  pkgs,
  lib,
  nixos,
  ...
}:
{
  config = lib.mkIf (myconfig.constants.flatpak or false) {

    # Flatpak packages. Put them inside quotes """
    # 💡 HOW TO FIND PACKAGE NAMES:
    # 1. Go to https://flathub.org
    # 2. Search in the url after /apps/
    # Examples:
    # https://flathub.org/en/apps/com.spotify.Client --> "com.spotify.Client"
    services.flatpak.enable = true;
    services.flatpak.packages = [
      "com.actualbudget.actual"
      "me.iepure.devtoolbox"
      "com.github.unrud.VideoDownloader"
      "com.github.tchx84.Flatseal"
      "com.usebottles.bottles"
    ];

    services.flatpak.update.onActivation = false;

    services.flatpak.remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    services.flatpak.update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };

    systemd.services.flatpak-managed-install = {
      serviceConfig = {
        TimeoutStartSec = lib.mkForce "900";
        Restart = lib.mkForce "on-failure";
        RestartSec = lib.mkForce "10s";
      };
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
  };
}
