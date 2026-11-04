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
          (craftBundle "cadcraft" "0.17.0" "sha256-ljfKCMuRFB/GeXENYS9VHhck0p9uqmG2O0s8qSlVO38=") # CAD / DXF drawing editor
          (craftBundle "craft-anything" "0.3.0" "sha256-aujUizcOyP7TxyNvxd6zSU1aXaR5TvI4IFx59duhLhQ=") # Understand how any software works, and craft your own
          (craftBundle "deckcraft" "0.15.0" "sha256-SXtk3BSsbNICYKLPspssg7ed8zNucChoH9nxEu0i/as=") # PowerPoint-like presentations
          (craftBundle "designcraft" "0.17.1" "sha256-c72GdKakxddHmaKt3DZTGOjVPyIcGUwTATg6YiClkGY=") # InDesign-like page layout (magazines, books, print)
          (craftBundle "effectcraft" "0.21.0" "sha256-MBvci2aBq6ydqiKWxU2OnRaNdgL+NfCDrHPKJmcWUfQ=") # After Effects-like motion graphics / VFX compositor
          (craftBundle "figcraft" "0.15.0" "sha256-FGO3WHAoQtqKCqbc8VyE97PmhhWIGTmMj7wkoO0hSqA=") # Figma-like UI design
          (craftBundle "filmcraft" "0.17.0" "sha256-eI129lzA5Eprrx4utQl6jhy5MB+N1ITifU+v7r/NNS8=") # Premiere-like video editor
          (craftBundle "gridcraft" "0.16.0" "sha256-D+LI42uAgJJVnpX7clASC5sCLll6f7FUDjZq7ppNH7E=") # Excel-like spreadsheet
          (craftBundle "lightcraft" "0.18.0" "sha256-ntb0tHqA/x9isQui/0LuFHegS3E9qH/4xM4j/ZouLKo=") # Lightroom-like photo editor
          (craftBundle "pdfcraft" "0.18.1" "sha256-11x3ETAT6GmO7e3wx/+3OVArXD/AXWOlBhIktb1GhSA=") # Acrobat-like PDF editor
          (craftBundle "photocraft" "0.20.1" "sha256-oXh0i595z2GbA1jWX1vDeKZ917eC6czZCwMtfF+FiRI=") # Photoshop-like image editor
          (craftBundle "soundcraft" "0.17.0" "sha256-zrQtU56a7AzEgYh06S5kBXFjNbBX2eJAqKWVmP7zS64=") # Audio editor / DAW-like
          (craftBundle "texturecraft" "0.3.1" "sha256-BhFnFm6/AVv+8b8jB+uWPozQ+uP25WypDb/IR2sjihE=") # 3D texture painting
          (craftBundle "vectorcraft" "0.21.0" "sha256-q0jUDrWYgTGPRC8Fc77sgvn5SZVoPhVvKlaSfDu9Pk8=") # Illustrator-like vector editor
          (craftBundle "wordcraft" "0.15.1" "sha256-JDJ9UtKWUYYubVh35iJaDoQYXSxcYRn/ju7fDJSluN0=") # Word-like word processor
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
