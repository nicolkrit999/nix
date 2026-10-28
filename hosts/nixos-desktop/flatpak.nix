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
          (craftBundle "vectorcraft" "0.17.0" "sha256-NCPJjbzpovfmf6F7aFLF9vo3Opml8Kh3H8MY9C2FOYw=") # Illustrator-like vector editor
          (craftBundle "photocraft" "0.16.0" "sha256-uLhEpJUfaHci/Mrn5E82C72v3xEpER2NEB6JNJTqMgI=") # Photoshop-like image editor
          (craftBundle "lightcraft" "0.14.0" "sha256-lRRe71IzbTaIE1wvRc4NSkltA+IsE8Jr5A98LUcTWUQ=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.14.0" "sha256-fuS/VUufGFTa3wcRdPe2FuoFBdHbi5roUFLgtmPxj+U=") # Acrobat-like PDF editor
          (craftBundle "deckcraft" "0.11.1" "sha256-C/JmyIWsgPK8ad4Wo89BXbmneGmS3Y4IgzlLJnWBdtY=") # PowerPoint-like presentations
          (craftBundle "gridcraft" "0.12.1" "sha256-CGHCWpDKtIrZsgaJ3dJBe3+nFabGJfr1gAGolAnJ4ZA=") # Excel-like spreadsheet
          (craftBundle "wordcraft" "0.11.0" "sha256-Xsog5wzr5QJWYOrjUMOz50rp/DbvspPSY1d+I2lvsZM=") # Word-like word processor
          (craftBundle "filmcraft" "0.13.0" "sha256-yabHY7v2v06maiBPVkU5LOo5/punTwiLDAgUnEltoaA=") # Premiere-like video editor
          (craftBundle "designcraft" "0.13.0" "sha256-qyzf586+oBwOvqxQeJzQ1LBE6QuyP/uOSWE0Vr35xD8=") # InDesign-like page layout (magazines, books, print)
          (craftBundle "effectcraft" "0.17.0" "sha256-URuqEJ9sBshbQvYJC2QNvv6+B6eFzQCBwlnG4a4g3LA=") # After Effects-like motion graphics / VFX compositor
          (craftBundle "figcraft" "0.11.2" "sha256-+FseY+1e9rVJmE1XX3jjbI2GsSbUldwoYLJob1we+uk=") # Figma-like UI design
          (craftBundle "soundcraft" "0.13.1" "sha256-J/IgfRl25PfbtZ5EL+DMCdUIOFcV34e1ZJStKQlYxDk=") # Audio editor / DAW-like
          (craftBundle "cadcraft" "0.13.0" "sha256-otchecKAd5MDx9Lt6/jVwsh7/fTFpWkk8O3wInZsWk0=") # CAD / DXF drawing editor
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
