{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.laptop.local-packages";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      # Ventoy: precompiled blobs, insecure pin (nixpkgs#404663); update on bump, drop when knownVulnerabilities clears
      nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.18" ];

      users.users.${myconfig.constants.user}.packages = with pkgs; [
        # Desktop applications
        censor # PDF document redaction for the GNOME desktop
        czkawka # Find duplicates, empty folders, similar images etc.
        drawio # Diagramming application
        gallery-dl # Command-line program to download image-galleries and -collections from several image hosting sites
        gearlever # Manager for AppImages
        google-chrome # Freeware web browser developed by Google
        gramps # Genealogy software
        jellyfin-desktop # Jellyfin media player client
        libreoffice-qt # Open source microsoft office alternative
        obs-studio # Streaming/Recording
        proton-pass # Password manager by Proton
        shortwave # Find and listen to internet radio stations
        teams-for-linux # Unofficial Microsoft Teams client
        tor-browser # Privacy-focused web browser
        ventoy-full-qt # New Bootable USB Solution with GUI support
        vscode # Microsoft visual studio code IDE

        # CLI utilities
        grex # Command-line tool for generating regular expressions
        tealdeer # Fast implementation of tldr (simplified man pages)

        # Coding
        (python313.withPackages (
          ps: with ps; [
            faker # Generate fake data
          ]
        ))
        zeal # Offline documentation browser

        # Fun
        asciinema # Record and share terminal sessions
        neo-cowsay # Cowsay reborn (ASCII art with text)
        pipes # Terminal pipes animation

        # General
        pay-respects
      ];
    };
}
