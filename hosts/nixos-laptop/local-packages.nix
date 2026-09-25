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
          censor # PDF document redaction for the GNOME desktop
          concessio # File permission viewer/calculator
          cryptomator # Client side encryptions for cloud drives
          drawio # Diagramming application
          google-chrome # Freeware web browser developed by Google
          jellyfin-desktop # Media server
          libreoffice-qt # Open source microsoft office alternative
          localsend # Simple file sharing over local network
          obs-studio # Streaming/Recording
          proton-pass # Password manager by Proton
          signal-desktop # Encrypted messaging application
          shortwave # Find and listen to internet radio stations
          teams-for-linux # Unofficial Microsoft Teams client
          tor-browser # Privacy-focused web browser
          vscode # Microsoft visual studio code IDE
          vesktop # Discord client
          vlc # Media player

          # -----------------------------------------------------------------------------------
          # 🖥️ CLI UTILITIES
          # -----------------------------------------------------------------------------------
          distrobox-tui # TUI for DistroBox
          hwinfo # Hardware detection tool from openSUSE
          grex # Command-line tool for generating regular expressions
          nchat # terminal-based chat client with support for telegram and whatsapp
          tealdeer # Fast implementation of tldr (simplified man pages)

          # -----------------------------------------------------------------------------------
          # 🧑🏽‍💻 CODING
          # -----------------------------------------------------------------------------------
          github-desktop # GitHub's official desktop client
          zeal # Offline documentation browser

          (pkgs.python313.withPackages (
            ps: with ps; [
              faker # Generate fake data
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
          # 🏠 GENERAL
          # -----------------------------------------------------------------------------------
          fastfetch
          fd
          killall
          pay-respects
          pokemon-colorscripts
          ripgrep
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
        ]);
    };
}
