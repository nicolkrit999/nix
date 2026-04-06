{ delib
, inputs
, ...
}:
delib.module {
  name = "krit.services.desktop.flatpak";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  nixos.ifEnabled =
    {
      services.flatpak = {
        enable = true;
        packages = [
          "com.actualbudget.actual" # Actual budget budgeting app
          "io.github.shonebinu.Brief" # Brief, command lines cheatsheet application
          "me.iepure.devtoolbox" # DevToolbox, a collection of tools for developers
          "com.github.unrud.VideoDownloader" # Video Downloader, a tool for downloading videos from various platforms
          "com.github.tchx84.Flatseal" # Flatseal, a permissions manager for Flatpak applications
          "com.rtosta.zapzap" # Whatsapp client for Linux
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

        overrides = {
          "com.rtosta.zapzap".Context.filesystems = [ "home" ]; # Download/save WhatsApp files
          "com.github.unrud.VideoDownloader".Context.filesystems = [ "xdg-download" ]; # Save downloaded videos
          "com.actualbudget.actual".Context.filesystems = [ "home" ]; # Import/export budget files
          "me.iepure.devtoolbox".Context.filesystems = [ "home" ]; # Open/save files for conversion tools
        };
      };
    };
}
