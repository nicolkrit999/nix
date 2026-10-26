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
        concessio # File permission viewer/calculator
        cryptomator # Client side encryptions for cloud drives
        czkawka # Find duplicates, empty folders, similar images etc.
        drawio # Diagramming application
        gallery-dl # Command-line program to download image-galleries and -collections from several image hosting sites
        google-chrome # Freeware web browser developed by Google
        jellyfin-desktop # Jellyfin media player client
        libreoffice-qt # Open source microsoft office alternative
        localsend # Simple file sharing over local network
        media-downloader # Qt/C++ GUI front end for yt-dlp and others
        obs-studio # Streaming/Recording
        proton-pass # Password manager by Proton
        shortwave # Find and listen to internet radio stations
        signal-desktop # Encrypted messaging application
        teams-for-linux # Unofficial Microsoft Teams client
        tor-browser # Privacy-focused web browser
        ventoy-full-qt # New Bootable USB Solution with GUI support
        vesktop # Discord client
        vlc # Media player
        vscode # Microsoft visual studio code IDE

        # CLI utilities
        distrobox-tui # TUI for DistroBox
        gh # GitHub CLI tool
        grex # Command-line tool for generating regular expressions
        hwinfo # Hardware detection tool from openSUSE
        nchat # terminal-based chat client with support for telegram and whatsapp
        tealdeer # Fast implementation of tldr (simplified man pages)

        # Coding
        github-desktop # GitHub's official desktop client
        (python313.withPackages (
          ps: with ps; [
            faker # Generate fake data
          ]
        ))
        zeal # Offline documentation browser

        # Fun
        asciinema # Record and share terminal sessions
        cbonsai # Grow bonsai trees in your terminal
        neo-cowsay # Cowsay reborn (ASCII art with text)
        pipes # Terminal pipes animation

        # General
        fd
        killall
        pay-respects
        ripgrep
        tree
        unzip
        upterm
        yt-dlp
        zip
        zlib
      ];
    };
}
