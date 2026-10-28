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
          (craftBundle "vectorcraft" "0.18.0" "sha256-RYFIizM+A751of8OaPLekQLgCwY6DX25k/jsKpQUbdY=") # Illustrator-like vector editor
          (craftBundle "photocraft" "0.17.0" "sha256-yW3AzBDLHbJp2sog1KJUm/aVDFFL59aLjcJtVXRAFjc=") # Photoshop-like image editor
          (craftBundle "lightcraft" "0.15.0" "sha256-hE73O5DO3PDFjo9szAOXlVAByF33mKdcUuG/LLvlnPA=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.15.0" "sha256-RvKBx9t8mkIjUD7UmwE3G9Ls7W+cyXycFRfcQdBQKeY=") # Acrobat-like PDF editor
          (craftBundle "deckcraft" "0.12.0" "sha256-T0+4EViLy1H9IPKydfeVdHhEe+ln/7I4q5D3pvc90QQ=") # PowerPoint-like presentations
          (craftBundle "gridcraft" "0.13.0" "sha256-9AQS1bxPOcV30qeyAqxXB+BkgVDwGWl2SdQDHU2wLbg=") # Excel-like spreadsheet
          (craftBundle "wordcraft" "0.12.0" "sha256-Gaft0AT63sjuCF5rmduZI4x6wWBOmPAik+BLHs0461E=") # Word-like word processor
          (craftBundle "filmcraft" "0.14.0" "sha256-fHZDD4vNZlwcPzXdZOtsOiMuooXcxiaNilylilVNVtw=") # Premiere-like video editor
          (craftBundle "designcraft" "0.14.0" "sha256-5QAo/b4j3X7IQGwHA2Gm0cM/1szr2k4RaDcCG9tDvQM=") # InDesign-like page layout (magazines, books, print)
          (craftBundle "effectcraft" "0.18.0" "sha256-baceeHWfAqpcl7BHKJc+szTNYHDNPJYdV2/6hmTcxF4=") # After Effects-like motion graphics / VFX compositor
          (craftBundle "figcraft" "0.12.1" "sha256-z+3U7iqHh5FyGGQGP/qvC1DVEpj8YuMt4W/G2qzDtIs=") # Figma-like UI design
          (craftBundle "soundcraft" "0.14.0" "sha256-nTHsWX/KjmRmJVOy43ioRP3jVLSdLonKYa2h5ypSWXs=") # Audio editor / DAW-like
          (craftBundle "cadcraft" "0.14.0" "sha256-iWP+u4VXHz1EmoK5GJCmwB3sKkw7gJ9fuu1D/GnZza0=") # CAD / DXF drawing editor
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
