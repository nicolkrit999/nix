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
          message = "krit.services.laptop.flatpak: the Craft bundles are linux-x86_64 only";
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

          "dev.mariinkys.StarryDex" # Pokedex

          "io.github.iionel.Visu" # Algorithm visualizer
          "io.github.lluciocc.Vish" # Gui bash script editor
          "io.github.shonebinu.Brief" # Brief, command lines cheatsheet application

          "lol.siembra.tuxtypeplus" # Typing test games
          "me.iepure.devtoolbox" # DevToolbox, a collection of tools for developers

          # storytold "Craft" apps (github.com/storytold/<name>): not on Flathub, installed from the
          # release's linux-x86_64 .flatpak bundle (runtime comes from the flathub remote). update.auto does
          # not touch bundles - to update, bump the version and hash (hash = release SHA256SUMS.txt in SRI form).
          (craftBundle "vectorcraft" "0.14.0" "sha256-kdFYbIIjLhgL54OQlZfuBo4bhmuPMCkLpEaKB1f6s2M=") # Illustrator-like vector editor
          (craftBundle "photocraft" "0.12.0" "sha256-2nJOgF8LZQUoUY9vkTAcgH7o5vLKDcGpY+QocS2GiQI=") # Photoshop-like image editor
          (craftBundle "lightcraft" "0.11.0" "sha256-ZeefpcriFlUgBHDcJmT/1o1OWXD12Xq8jGOX+6MPgFI=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.11.0" "sha256-cYhzwiCGw9uUsFyKzXTSonqjUbUOr75epNQpsA7EaL8=") # Acrobat-like PDF editor
          (craftBundle "deckcraft" "0.9.0" "sha256-4pGtMSthAx/lpFuf90DdUHpB4o267T1chn7B38Nh6AU=") # PowerPoint-like presentations
          (craftBundle "gridcraft" "0.10.0" "sha256-TZUHGmGTZKVWiTDs3ZhNfIS9xx/twmqJPLezM4zq81o=") # Excel-like spreadsheet
          (craftBundle "wordcraft" "0.9.0" "sha256-ryk1005pPfu3tnlGt3GqI6GWglC4lGP5WIOgO6FNj48=") # Word-like word processor
          (craftBundle "filmcraft" "0.10.0" "sha256-6Ze9Vbs+kZy0O2uu7Q6vJo2acm+wishOjmL44pp1iK0=") # Premiere-like video editor
          (craftBundle "designcraft" "0.11.0" "sha256-ZXmE62zqF94F+XULwrFhuZzn8kt8DPGaZS9Vcv3Yzwg=") # InDesign-like page layout (magazines, books, print)
          (craftBundle "effectcraft" "0.14.0" "sha256-fNHTCf9VEK1xBPo6KdQebhiBIfw2Int/MeBAYKkM82M=") # After Effects-like motion graphics / VFX compositor
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
