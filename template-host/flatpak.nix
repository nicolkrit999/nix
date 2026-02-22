{
  delib,
  pkgs,
  inputs,
  ...
}: # 🌟 THE FIX: Added inputs here
delib.module {
  name = "template-host.services.desktop.flatpak";
  options.template-host.services.desktop.flatpak.enable = delib.boolOption false;

  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      services.flatpak = {
        enable = true;
        packages = [
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
