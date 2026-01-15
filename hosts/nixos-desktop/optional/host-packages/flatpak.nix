{
  pkgs,
  lib,
  vars,
  ...
}:
{
  config = lib.mkIf vars.flatpak {

    services.flatpak.enable = true;
    services.flatpak.packages = [ "me.iepure.devtoolbox" ];
    services.flatpak.update.onActivation = true;

    services.flatpak.remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };
  };
}
