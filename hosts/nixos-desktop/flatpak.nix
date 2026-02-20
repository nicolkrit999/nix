{ ... }:
{ }

# TODO: Wait for fix for "services.flatpak.packages does not exist"

/*
  { delib, pkgs, ... }:
  delib.module {
    name = "krit.services.flatpak";
    options.krit.services.flatpak.enable = delib.boolOption false;

    # 🌟 THE FIX: Keep configuration strictly in the nixos hook
    nixos.ifEnabled =
      { cfg, myconfig, ... }:
      {
        services.flatpak = {
          enable = true;
          packages = [
            "com.actualbudget.actual"
            "me.iepure.devtoolbox"
            "com.github.unrud.VideoDownloader"
            "com.github.tchx84.Flatseal"
            "com.usebottles.bottles"
          ];
          update.onActivation = false;
          remotes = [
            {
              name = "flathub";
              location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            }
          ];
          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.common.default = "gtk";
        };
      };
  }
*/
