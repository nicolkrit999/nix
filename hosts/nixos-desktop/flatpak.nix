{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.flatpak";

  # 🌟 This option name must match the path used in your default.nix myconfig block
  options.krit.services.flatpak = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      # This block only runs if you set krit.services.flatpak.enable = true; in default.nix
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

      systemd.services.flatpak-managed-install = {
        serviceConfig = {
          TimeoutStartSec = "900";
          Restart = "on-failure";
          RestartSec = "10s";
        };
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };
    };
}
