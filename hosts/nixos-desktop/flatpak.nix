{
  delib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "krit.services.desktop.flatpak";
  options.krit.services.desktop.flatpak.enable = delib.boolOption false;

  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  nixos.ifEnabled =
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
