{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "krit.services.desktop.local-packages";
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
          #anydesk # Remote management desktop application
          cryptomator # Client side encryptions for cloud drives
          cpu-x # Hardware information visualizer application
          drawio # Diagramming application
          gearlever # Manager appimages
          gramps # Genealogy software
          gsimplecal # Simple calendar application
          gitnuro # Git client
          #handbrake # Video transcoder
          jellyfin-desktop # Media server
          #kdePackages.kate # Text editor from the kde theme
          libreoffice-qt # Open source microsoft office alternative
          localsend # Simple file sharing over local network
          #lutris # Gaming platform
          #meld # Visual diff and merge tool
          obs-studio # Streaming/Recording
          proton-pass # Password manager by Proton
          protonvpn-gui # VPN client by Proton
          #remmina # Remote management desktop client
          signal-desktop # Encrypted messaging application
          telegram-desktop # Messaging
          teams-for-linux # Unofficial Microsoft Teams client
          tor-browser # Privacy-focused web browser
          vscode # Microsoft visual studio code IDE
          vesktop # Discord client
          vlc # Media player
          #whatsapp-electron # Electron wrapper for whatsapp
          xmind # Mind mapping software
          yubikey-manager # Yubikey manager for configuring Yubikeys

          # -----------------------------------------------------------------------------------
          # 🖥️ CLI UTILITIES
          # -----------------------------------------------------------------------------------
          #bc # Arbitrary precision calculator
          #carbon-now-cli # Create beautiful images of your code (carbon.now.sh CLI)
          #cloudflared # Cloudflare's command-line tool and daemon
          #cloc # Count lines of code
          croc # Securely and easily send files between two computers
          efibootmgr # Manage UEFI boot entries
          fastfetch # Fast system information fetcher
          fd # Simple, fast and user-friendly alternative to find
          gh # GitHub CLI tool
          #glow # Markdown renderer for the terminal
          grex # Command-line tool for generating regular expressions
          htop # Process viewer and killer
          killall # Command to kill processes by name
          #lsof # List open files
          #ntfs3g # NTFS read/write support
          pay-respects # Check commands syntax error and get suggestions for fixes
          pokemon-colorscripts
          ripgrep # Fast line-oriented search tool
          stow # Symlink manager for dotfiles
          tealdeer # Fast implementation of tldr (simplified man pages)
          tree # Display directories as trees
          #ttyd # Share your terminal over the web
          tmate # Instant terminal sharing
          unzip # Extract zip files
          #unixtools.netstat # Network statistics
          #usbutils # USB device utilities
          #wakeonlan # Magic packets
          wget # Download files from the web
          yt-dlp # Media downloader for YouTube and other sites
          age-plugin-yubikey # Age plugin for Yubikeys
          yubikey-agent # Yubikey agent for managing Yubikeys
          yubikey-touch-detector # Detect if a Yubikey is touched
          zip # Extract zip files
          zlib # Compression library

          # -----------------------------------------------------------------------------------
          # 🧑🏽‍💻 CODING
          # -----------------------------------------------------------------------------------
          github-desktop # GitHub's official desktop client
          #jq # Command-line JSON processor
          #universal-ctags # Tool to generate index (tags) files of source code
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

          # -----------------------------------------------------------------------
          # ❓ OTHER
          # -----------------------------------------------------------------------
        ])

        ++ (with pkgs-unstable; [
          # -----------------------------------------------------------------------
          # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
          # -----------------------------------------------------------------------
          fresh-editor # Lightweight terminal text editor
        ]);
    };
}
