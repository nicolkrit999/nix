{ delib
, pkgs
, inputs
, ...
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
          "it.mijorus.gearlever" # Appimages manager
          "page.kramo.Cartridges" # Cartridges, a tool for managing and running game emulators
          "com.actualbudget.actual" # Actual budget budgeting app
         "io.github.shonebinu.Brief" # Brief, command lines cheatsheet application
         "app.curocalc.calculator" # Loan calculator
          "me.iepure.devtoolbox" # DevToolbox, a collection of tools for developers
          "com.github.unrud.VideoDownloader" # Video Downloader, a tool for downloading videos from various platforms
          "com.github.tchx84.Flatseal" # Flatseal, a permissions manager for Flatpak applications
          "com.usebottles.bottles" # Bottles, a tool for managing Wine prefixes and running Windows applications on Linux
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
