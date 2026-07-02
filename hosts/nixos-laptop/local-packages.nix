{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "krit.services.laptop.local-packages";
  options = delib.singleEnableOption false;


  nixos.ifEnabled =
    { myconfig, ... }:
    let
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in

    {
      users.users.${myconfig.constants.user}.packages =
        (with pkgs; [
          # -----------------------------------------------------------------------
          # 🖥️ DESKTOP APPLICATIONS
          # -----------------------------------------------------------------------
          concessio # File permission viewer/calculator
          cryptomator # Client side encryptions for cloud drives
          cpu-x # Hardware information visualizer application
          drawio # Diagramming application
          jellyfin-desktop # Media server
          libreoffice-qt # Open source microsoft office alternative
          localsend # Simple file sharing over local network
          obs-studio # Streaming/Recording
          proton-pass # Password manager by Proton
          signal-desktop # Encrypted messaging application
          telegram-desktop # Messaging
          teams-for-linux # Unofficial Microsoft Teams client
          tor-browser # Privacy-focused web browser
          vscode # Microsoft visual studio code IDE
          vesktop # Discord client
          vlc # Media player
          xmind # Mind mapping software

          # -----------------------------------------------------------------------------------
          # 🖥️ CLI UTILITIES
          # -----------------------------------------------------------------------------------
          distrobox-tui # TUI for DistroBox
          hwinfo # Hardware detection tool from openSUSE
          cointop # Fastest and most interactive terminal based UI application for tracking cryptocurrencies
          jellyfin-tui # Jellyfin music streaming client for the terminal
          grex # Command-line tool for generating regular expressions
          nchat # terminal-based chat client with support for telegram and whatsapp
          ratty # GPU-rendered terminal emulator with inline 3D graphics
          tealdeer # Fast implementation of tldr (simplified man pages)

          # -----------------------------------------------------------------------------------
          # 🧑🏽‍💻 CODING
          # -----------------------------------------------------------------------------------
          github-desktop # GitHub's official desktop client
          zeal # Offline documentation browser

          (pkgs.python313.withPackages (
            ps: with ps; [
              faker # Generate fake data
              proton-keyring-linux # Proton keyring for Linux
            ]
          ))

          # -----------------------------------------------------------------------------------
          # 😂 FUN PACKAGES
          # -----------------------------------------------------------------------------------
          asciinema # Record and share terminal sessions
          cbonsai # Grow bonsai trees in your terminal
          neo-cowsay # Cowsay reborn (ASCII art with text)
          pipes # Terminal pipes animation

          # -----------------------------------------------------------------------------------
          # 🏠 GENERAL (moved from home-base)
          # -----------------------------------------------------------------------------------
          efibootmgr
          fastfetch
          fd
          gh
          htop
          inetutils
          killall
          nix-search-cli
          pay-respects
          pokemon-colorscripts
          ripgrep
          stow
          tmate
          tree
          unzip
          yt-dlp
          zip
          zlib

          # -----------------------------------------------------------------------
          # ❓ OTHER
          # -----------------------------------------------------------------------
        ])

        ++ (with pkgs-unstable; [
          # -----------------------------------------------------------------------
          # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
          # -----------------------------------------------------------------------
          fresh-editor # Lightweight terminal text editor - not in 26.05
        ]);
    };
}
