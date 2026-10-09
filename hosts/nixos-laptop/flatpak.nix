{ delib
, inputs
, pkgs
, ...
}:
delib.module {
  name = "krit.services.laptop.flatpak";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  nixos.ifEnabled =
    let
      # nix-flatpak passes `bundle` to `flatpak install --bundle`, which needs a local file:
      # fetchurl downloads it (and enforces the hash); sha256 also triggers the reinstall on change.
      craftBundle = name: version: hash: rec {
        appId = "ai.storyteller.${name}";
        sha256 = hash;
        bundle = "${pkgs.fetchurl {
          url = "https://github.com/storytold/${name}/releases/download/v${version}/${name}-${version}-linux-x86_64.flatpak";
          inherit sha256;
        }}";
      };
    in
    {
      services.flatpak = {
        enable = true;
        packages = [
          "co.logonoff.awakeonlan" # AwakeOnLan, a tool to wake up computers on the network

          "com.actualbudget.actual" # Actual budget budgeting app
          "com.github.tchx84.Flatseal" # Flatseal, a permissions manager for Flatpak applications
          "com.github.unrud.VideoDownloader" # Video Downloader, a tool for downloading videos from various platforms
          "com.rtosta.zapzap" # Whatsapp client for Linux


          "dev.mariinkys.StarryDex" # Pokedex


          "io.github.philippkosarev.bmi" # Bmi calculator
          "io.github.shonebinu.Brief" # Brief, command lines cheatsheet application
          "io.github.AshBuk.FingerGo" # Typing trainer
          "io.github.lluciocc.Vish" # Gui bash script editor
          "io.github.iionel.Visu" # Algorithm visualizer

          "lol.siembra.tuxtypeplus" # Typing test games

          "me.iepure.devtoolbox" # DevToolbox, a collection of tools for developers

          # storytold "Craft" apps (github.com/storytold/<name>): not on Flathub, installed from the
          # release's linux-x86_64 .flatpak bundle (runtime comes from the flathub remote). update.auto does
          # not touch bundles - to update, bump the version and hash (hash = release SHA256SUMS.txt in SRI form).
          (craftBundle "vectorcraft" "0.7.0" "sha256-JCHGWfXmw7CLm0OnLOHaaNeRMDcY/LG6wUg13MIeLys=") # Illustrator-like vector editor
          (craftBundle "photocraft" "0.5.0" "sha256-lYKubS66svupb4Wa52AZvy8FLVWqlVKR9sUpcWUdfcw=") # Photoshop-like image editor
          (craftBundle "lightcraft" "0.4.0" "sha256-N3VpZ9MTPg2iEaans3OWdEiJ1C4vKgvVNS7wQcQo3Lg=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.4.0" "sha256-NpQidplaeLxHqoe/eZ2fDgwAqvT38f7wb+n56Rkj/tU=") # Acrobat-like PDF editor
          (craftBundle "deckcraft" "0.3.0" "sha256-6X6qsYArOk1cxEl8T8gvc2JSk5VP00bUI8j0HBsTM14=") # PowerPoint-like presentations
          (craftBundle "gridcraft" "0.3.0" "sha256-O67AHQtKSZKq64FZ44E8hnwYDkKYEV/jaiCWLwHPYDo=") # Excel-like spreadsheet
          (craftBundle "wordcraft" "0.3.0" "sha256-ehlzr4a3QPIiCUTzry/0IPUW0u5s803DexqxUbS+ZsI=") # Word-like word processor
          (craftBundle "filmcraft" "0.4.0" "sha256-Mq9YakI3J99G7pWFrjF+kkf1NBTJ5pocdg0b0AT5YXk=") # Premiere-like video editor
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
          # storytold Craft apps: extra grants on top of each bundle's own finish-args (checked against the pinned tags)
          "ai.storyteller.vectorcraft".Context.filesystems = [ "home" ]; # Linked images next to the document + default export folder ($HOME/Desktop)
          "ai.storyteller.photocraft".Context.filesystems = [ "xdg-download" ]; # Open/save in Downloads by path (bundle grants only Pictures/Documents)
          "ai.storyteller.lightcraft".Context.filesystems = [ "/run/media" ]; # Import from cards/USB drives (scans /run/media/$USER)
          "ai.storyteller.pdfcraft".Environment.TZ = "Europe/Zurich"; # Stamps/signing dates use chrono::Local; /etc/localtime isn't visible in Flatpak, so it would fall back to UTC
          "ai.storyteller.gridcraft".Context.filesystems = [ "xdg-pictures:ro" ]; # Insert Picture by typed path
        };
      };
    };
}
