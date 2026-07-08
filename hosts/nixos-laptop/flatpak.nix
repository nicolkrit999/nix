{ delib
, inputs
, ...
}:
delib.module {
  name = "krit.services.laptop.flatpak";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  nixos.ifEnabled =
    {
      services.flatpak = {
        enable = true;
        packages = [
          "io.github.philippkosarev.bmi" # Bmi calculator
          "io.github.lluciocc.Vish" # Gui bash script editor
          "io.github.iionel.Visu" # Algorithm visualizer
          "com.actualbudget.actual" # Actual budget budgeting app
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
          "com.rtosta.zapzap".Environment.TZ = "Europe/Zurich"; # /etc is reserved by Flatpak (can't bind-mount /etc/localtime), so set TZ directly to stop Electron falling back to UTC
          "com.github.unrud.VideoDownloader".Context.filesystems = [ "xdg-download" ]; # Save downloaded videos
          "com.actualbudget.actual".Context.filesystems = [ "home" ]; # Import/export budget files
          "com.actualbudget.actual".Environment.TZ = "Europe/Zurich"; # /etc is reserved by Flatpak (can't bind-mount /etc/localtime), so set TZ directly to stop Electron falling back to UTC
          "me.iepure.devtoolbox".Context.filesystems = [ "home" ]; # Open/save files for conversion tools
        };
      };
    };
}
