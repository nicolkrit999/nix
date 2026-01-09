{
  pkgs,
  pkgs-unstable,
  vars,
  ...
}:
{
  users.users.${vars.user}.packages =
    with pkgs;
    [
      # This allow guest user to not have this packages installed
      # Packages in each category are sorted alphabetically

      # -----------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------
      kdePackages.kate # Text editor from the kde theme
      notion-app # Writing app
      obs-studio # Streaming/Recording
      telegram-desktop # Messaging
      teams-for-linux # Unofficial Microsoft Teams client
      signal-desktop # Encrypted messaging application
      vlc # Media player
      proton-pass # Password manager by Proton
      protonvpn-gui # VPN client by Proton
      vesktop # Discord client
      libreoffice-qt # Open source microsoft office alternative
      gsimplecal # Simple calendar application
      meld # Visual diff and merge tool

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      bc # Arbitrary precision calculator
      carbon-now-cli # Create beautiful images of your code (carbon.now.sh CLI)
      cava # Console-based audio visualizer
      cloudflared # Cloudflare's command-line tool and daemon
      croc # Securely and easily send files between two computers
      efibootmgr # Manage UEFI boot entries
      fastfetch # Fast system information fetcher
      fd # User-friendly replacement for 'find'
      ffmpeg # Multimedia framework for audio/video processing
      gh # GitHub CLI tool
      glow # Markdown renderer for the terminal
      grex # Command-line tool for generating regular expressions
      grim # Screenshot utility for Wayland
      htop # Process viewer and killer
      lsof # List open files
      mediainfo # Display technical info about media files
      ntfs3g # NTFS read/write support
      pass # Simple password manager
      pay-respects # Cli commands autosuggestion (used in my zsh dotfiles) -> ⚠️ KEEP
      pokemon-colorscripts # Print pokemon sprites in terminal with colors (used in my dotfiles) -> ⚠️ KEEP
      #solaar # Linux driver for Logitech devices
      stow # Symlink farm manager (used in my dotfiles) -> ⚠️ KEEP
      tealdeer # Fast implementation of tldr (simplified man pages)
      tree # Display directory structure as a tree
      ttyd # Share your terminal over the web
      unixtools.netstat # Network statistics
      usbutils # USB device utilities
      wakeonlan # Magic packets
      yt-dlp # Media downloader for YouTube and other sites
      zlib # Compression utility for .zip files. It is used by programs to compress/decompress data.
      # Fast, lightweight alternative to 'cd'
      zoxide # Fast, lightweight alternative to 'cd'

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      cmake # Cross-platform build system
      docker # Containerization platform
      github-desktop # GitHub's official desktop client
      jq # Command-line JSON processor
      maven # Java build tool
      tectonic # Modernized, complete, self-contained TeX/LaTeX engine
      texliveFull # The complete TeX Live distribution (Note: Large download)
      universal-ctags # Tool to generate index (tags) files of source code
      jetbrains.pycharm-oss # Python IDE
      jetbrains.clion # C/C++ IDE
      jetbrains.idea-oss # Java IDE
      zeal # Offline documentation browser
      (pkgs.python313.withPackages (
        ps: with ps; [
          faker # Generate fake data
          isort # Sort imports alphabetically
          pyright # Static type checker
          pylint # Source code analyzer
          setuptools # Library for packaging Python projectsS
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
      logiops # Logitech devices manager (currently used for my MX Master 3S)
    ]

    ++ (with pkgs-unstable; [
      # -----------------------------------------------------------------------
      # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
      # -----------------------------------------------------------------------
    ]);
}
