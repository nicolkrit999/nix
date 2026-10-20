{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.desktop.local-packages";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      # Ventoy: precompiled blobs, insecure pin (nixpkgs#404663); update on bump, drop when knownVulnerabilities clears
      nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.18" ];

      nixpkgs.overlays = [
        (_final: prev: {
          gearlever = prev.gearlever.overrideAttrs (old: {
            makeWrapperArgs = lib.concatMap (lib.splitString " ") (
              lib.remove "\${gappsWrapperArgs[@]}" old.makeWrapperArgs
            );
            preFixup = (old.preFixup or "") + ''
              makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
            '';
          });
        })
      ];

      users.users.${myconfig.constants.user}.packages = with pkgs; [
        # Desktop applications
        censor # PDF document redaction for the GNOME desktop
        concessio # File permission viewer/calculator
        cpu-x # Hardware information visualizer application
        cryptomator # Client side encryptions for cloud drives
        czkawka # Find duplicates, empty folders, similar images etc.
        drawio # Diagramming application
        fresh-editor # Terminal-based text editor with LSP support and TypeScript plugins
        gallery-dl # Command-line program to download image-galleries and -collections from several image hosting sites
        gearlever # Manager for AppImages
        gitnuro # Git client
        google-chrome # Freeware web browser developed by Google
        gramps # Genealogy software
        gsimplecal # Simple calendar application
        jellyfin-desktop # Jellyfin media player client
        libreoffice-qt # Open source microsoft office alternative
        localsend # Simple file sharing over local network
        media-downloader # Qt/C++ GUI front end for yt-dlp and others
        obs-studio # Streaming/Recording
        proton-pass # Password manager by Proton
        shortwave # Find and listen to internet radio stations
        signal-desktop # Encrypted messaging application
        teams-for-linux # Unofficial Microsoft Teams client
        telegram-desktop # Messaging
        tor-browser # Privacy-focused web browser
        ventoy-full-qt # New Bootable USB Solution with GUI support
        vesktop # Discord client
        vlc # Media player
        vscode # Microsoft visual studio code IDE
        xmind # Mind mapping software
        yubikey-manager # Yubikey manager for configuring Yubikeys

        # CLI utilities
        cointop # Fastest and most interactive terminal based UI application for tracking cryptocurrencies
        distrobox-tui # TUI for DistroBox
        gh # GitHub CLI tool
        grex # Command-line tool for generating regular expressions
        hwinfo # Hardware detection tool from openSUSE
        jellyfin-tui # Jellyfin music streaming client for the terminal
        nchat # terminal-based chat client with support for telegram and whatsapp
        ratty # GPU-rendered terminal emulator with inline 3D graphics
        tealdeer # Fast implementation of tldr (simplified man pages)

        # Coding
        github-desktop # GitHub's official desktop client
        (python313.withPackages (
          ps: with ps; [
            faker # Generate fake data
            proton-keyring-linux # Proton keyring for Linux
          ]
        ))
        zeal # Offline documentation browser

        # Fun
        asciinema # Record and share terminal sessions
        cbonsai # Grow bonsai trees in your terminal
        neo-cowsay # Cowsay reborn (ASCII art with text)
        pipes # Terminal pipes animation

        # General
        efibootmgr
        fd
        htop
        inetutils
        killall
        nix-search-cli
        pay-respects
        ripgrep
        stow
        tree
        unzip
        upterm
        yt-dlp
        zip
        zlib
      ];
    };
}
