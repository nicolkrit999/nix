{
  delib,
  pkgs,
  inputs,
  ...
}: # 🌟 THE FIX: Added inputs here
delib.module {
  name = "krit.services.desktop.flatpak";
  options.krit.services.desktop.flatpak.enable = delib.boolOption false;

  # 🌟 THE FIX: Import the flatpak schema globally so it exists for ALL hosts
  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  # Configuration strictly in the nixos hook
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
