{ delib
, inputs
, pkgs
, ...
}:
delib.module {
  name = "krit.services.desktop.flatpak";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  };

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      tz = myconfig.constants.timeZone;

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
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isx86_64;
          message = "krit.services.desktop.flatpak: the Craft bundles are linux-x86_64 only";
        }
      ];

      services.flatpak = {
        enable = true;
        packages = [
          "co.logonoff.awakeonlan" # AwakeOnLan, a tool to wake up computers on the network

          "com.actualbudget.actual" # Actual budget budgeting app
          "com.github.tchx84.Flatseal" # Flatseal, a permissions manager for Flatpak applications
          "com.github.unrud.VideoDownloader" # Video Downloader, a tool for downloading videos from various platforms
          "com.rtosta.zapzap" # Whatsapp client for Linux

          "io.github.iionel.Visu" # Algorithm visualizer
          "io.github.lluciocc.Vish" # Gui bash script editor
          "io.github.shonebinu.Brief" # Brief, command lines cheatsheet application

          "lol.siembra.tuxtypeplus" # Typing test games
          "me.iepure.devtoolbox" # DevToolbox, a collection of tools for developers

          # storytold "Craft" apps (github.com/storytold/<name>): not on Flathub, installed from the
          # release's linux-x86_64 .flatpak bundle (runtime comes from the flathub remote). update.auto does
          # not touch bundles - to update, bump the version and hash (hash = release SHA256SUMS.txt in SRI form).
          (craftBundle "cadcraft" "0.16.0" "sha256-LLen1eRgEj0Zz55e5Br5uI3+2Jdis80pD+r+aTvX5YE=") # CAD / DXF drawing editor
          (craftBundle "craft-anything" "0.2.0" "sha256-SulvOUfvM+UOpZTckj3KvT+658l+oIAK5s2spsFAsFA=") # Understand how any software works, and craft your own
          (craftBundle "deckcraft" "0.14.1" "sha256-pSY1phJuxKAOJb6kbZFs9FG+f3O7F/VjgZ54leNdI5M=") # PowerPoint-like presentations
          (craftBundle "designcraft" "0.16.0" "sha256-HgBH7Mc10nfauCMmMM9/uqEAQUWMGvMS3qx6aiK93pY=") # InDesign-like page layout (magazines, books, print)
          (craftBundle "effectcraft" "0.20.0" "sha256-6wMhLneWOCgs2YYQoQepPLZqDTwzEcI0zmD/EpR55T4=") # After Effects-like motion graphics / VFX compositor
          (craftBundle "figcraft" "0.14.0" "sha256-1EB6Ep9xZfWW82SRA5alj44mGxz+9C0hvzL+XGBUq58=") # Figma-like UI design
          (craftBundle "filmcraft" "0.16.0" "sha256-+h+HxtdUfPPne2EeAL7HXIbcXlb1bIW1JvPal9TaM3k=") # Premiere-like video editor
          (craftBundle "gridcraft" "0.15.0" "sha256-XqRmO5u5KzIoB9YsmIBB1poxVcf8CpCO8c7Fsy8iEhg=") # Excel-like spreadsheet
          (craftBundle "lightcraft" "0.17.0" "sha256-p7JjyErn5tOOq4Dse8Ea+aTq11De/zGMALRPaEUPRfU=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.17.0" "sha256-duLUkbNVTIfm5CCzKQNwQ/m5QaRZZa6PwWpqQur49Ws=") # Acrobat-like PDF editor
          (craftBundle "photocraft" "0.19.0" "sha256-cGXkEBDzdQxM9bYS/wJJ5vSl67UFAbdv2ViRISGG6QE=") # Photoshop-like image editor
          (craftBundle "soundcraft" "0.16.0" "sha256-46uikU2aeFVmIvQvJORucEtt2sK6suWIYuyeBXnUPpQ=") # Audio editor / DAW-like
          (craftBundle "texturecraft" "0.2.0" "sha256-pRzkMPE6wXk8JAlefIOkHpi/Y0HLghe3H4HFlk5l3eY=") # 3D texture painting
          (craftBundle "vectorcraft" "0.20.0" "sha256-6LOXo4iScGmZWDIQ9tGb/io8Nx3J42/v8sQNjEq1YRQ=") # Illustrator-like vector editor
          (craftBundle "wordcraft" "0.14.0" "sha256-yAyvbTYsPfEscgmu/TVibcPd+/4XT21SdAqewoHE8yc=") # Word-like word processor
        ];
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
          "com.rtosta.zapzap" = {
            Context.filesystems = [ "home" ]; # Download/save WhatsApp files
            Environment.TZ = tz; # /etc is reserved by Flatpak (can't bind-mount /etc/localtime), so set TZ directly to stop Electron falling back to UTC
          };
          "com.github.unrud.VideoDownloader".Context.filesystems = [ "xdg-download" ]; # Save downloaded videos
          "com.actualbudget.actual" = {
            Context.filesystems = [ "home" ]; # Import/export budget files
            Environment.TZ = tz; # /etc is reserved by Flatpak (can't bind-mount /etc/localtime), so set TZ directly to stop Electron falling back to UTC
          };
          "me.iepure.devtoolbox".Context.filesystems = [ "home" ]; # Open/save files for conversion tools
          # storytold Craft apps: extra grants on top of each bundle's own finish-args (checked against the pinned tags)
          "ai.storyteller.vectorcraft".Context.filesystems = [ "home" ]; # Linked images next to the document + default export folder ($HOME/Desktop)
          "ai.storyteller.photocraft".Context.filesystems = [ "xdg-download" ]; # Open/save in Downloads by path (bundle grants only Pictures/Documents)
          "ai.storyteller.lightcraft".Context.filesystems = [ "/run/media" ]; # Import from cards/USB drives (scans /run/media/$USER)
          "ai.storyteller.pdfcraft".Environment.TZ = tz; # Stamps/signing dates use chrono::Local; /etc/localtime isn't visible in Flatpak, so it would fall back to UTC
          "ai.storyteller.gridcraft".Context.filesystems = [ "xdg-pictures:ro" ]; # Insert Picture by typed path
        };
      };
    };
}
