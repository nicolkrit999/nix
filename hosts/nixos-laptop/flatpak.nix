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

          "com.github.tchx84.Flatseal" # Flatseal, a permissions manager for Flatpak applications
          "com.github.unrud.VideoDownloader" # Video Downloader, a tool for downloading videos from various platforms

          "dev.mariinkys.StarryDex" # Pokedex

          "io.github.iionel.Visu" # Algorithm visualizer
          "io.github.lluciocc.Vish" # Gui bash script editor
          "io.github.shonebinu.Brief" # Brief, command lines cheatsheet application

          "lol.siembra.tuxtypeplus" # Typing test games
          "me.iepure.devtoolbox" # DevToolbox, a collection of tools for developers

          # storytold "Craft" apps (github.com/storytold/<name>): not on Flathub, installed from the
          # release's linux-x86_64 .flatpak bundle (runtime comes from the flathub remote). update.auto does
          # not touch bundles - to update, bump the version and hash (hash = release SHA256SUMS.txt in SRI form).
          (craftBundle "cadcraft" "0.20.1" "sha256-nRwHGyxhcA/swXcCJMEhNnkkeET7nvQg9C/Ts0iCqrc=") # CAD / DXF drawing editor
          (craftBundle "craft-anything" "0.6.1" "sha256-1gMrHCUr0rMTItSqnmHsLmAPWkGRi78BualrdMqt1yI=") # Understand how any software works, and craft your own
          (craftBundle "deckcraft" "0.18.1" "sha256-CAzYpNL3TKnvVUElR25tKqgOuNxy6rXUEkensX8tbC0=") # PowerPoint-like presentations
          (craftBundle "designcraft" "0.20.1" "sha256-xigZIXR3b9R2bvNC1cRJXoeHtT4mpPATbEi9RsE7raQ=") # InDesign-like page layout (magazines, books, print)
          (craftBundle "effectcraft" "0.24.1" "sha256-ovfR/giaPlgK1MhOH43Zg+Bx4S4EESLyWoIKUb+zHwo=") # After Effects-like motion graphics / VFX compositor
          (craftBundle "figcraft" "0.18.1" "sha256-K9O5CA30sJiWTrAsJfvC72gLMqaqg+OjN0OJB3kEO8M=") # Figma-like UI design
          (craftBundle "filmcraft" "0.20.1" "sha256-ZG7mJ7Obk/5px+y0RyX8lk/UNmDvjPKISz+0jnWawPg=") # Premiere-like video editor
          (craftBundle "gridcraft" "0.19.1" "sha256-U1KJBHw4keWiOP6qGGCWyjwMKDzf3h4P/3IkD19HXQI=") # Excel-like spreadsheet
          (craftBundle "lightcraft" "0.21.1" "sha256-OprriW37e4uh9shudzORL7eu3ymxqZ7uj+lYOZUfdpw=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.21.1" "sha256-TxJv9xjoUbpU7gIHxLbOnuvd/dctESRTHSFcwPiTfa8=") # Acrobat-like PDF editor
          (craftBundle "photocraft" "0.23.1" "sha256-XJ3rWPB71U8yOl2YW+0pW0xbFXieAmUeLyA9Xo7yEaU=") # Photoshop-like image editor
          (craftBundle "soundcraft" "0.20.1" "sha256-2a1CRmnwyXjcRoHfcdIPb8gCN1IgeNYxrwY9y7PFlJQ=") # Audio editor / DAW-like
          (craftBundle "texturecraft" "0.6.1" "sha256-mZYX2fytRWmpB+KNFUiV2rJgMg06qYy3WqAMRMyH0go=") # 3D texture painting
          (craftBundle "vectorcraft" "0.24.1" "sha256-mNtENX8euQaTJe+cM8TbFUvKgL5rkaNA00OrhaeUDc4=") # Illustrator-like vector editor
          (craftBundle "wordcraft" "0.18.1" "sha256-fzkj81N8AgUhMYMHQoIR2AhIzZzLBVJlsj1hOSFmFqk=") # Word-like word processor
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
          "com.github.unrud.VideoDownloader".Context.filesystems = [ "xdg-download" ]; # Save downloaded videos
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
