{
  pkgs,
  lib,
  vars,
  ...
}:
{
  # Only apply if flatpak is enabled in flake.nix
  config = lib.mkIf vars.flatpak {

    services.flatpak.enable = true;

    # Flatpak packages. Put them inside quotes """
    # 💡 HOW TO FIND PACKAGE NAMES:
    # 1. Go to https://flathub.org
    # 2. Search in the url after /apps/
    # Examples:
    # https://flathub.org/en/apps/com.spotify.Client --> "com.spotify.Client"
    services.flatpak.packages = [
      "me.iepure.devtoolbox"
    ];

    services.flatpak.remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Auto-update Flatpaks
    services.flatpak.update.onActivation = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };
  };
}
