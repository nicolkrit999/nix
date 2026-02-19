{
  pkgs,
  pkgs-unstable,
  myconfig,
  ...
}:
{
  users.users.${myconfig.constants.user}.packages =
    with pkgs;
    [
      # This allow guest user to not have this packages installed
      # Packages in each category are sorted alphabetically

      # -----------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------
      cryptomator # Client side encryptions for cloud drives
      gsimplecal # Simple calendar application
      kdePackages.kate # Text editor from the kde theme
      libreoffice-qt # Open source microsoft office alternative
      localsend # Simple file sharing over local network
      meld # Visual diff and merge tool
      obs-studio # Streaming/Recording
      proton-pass # Password manager by Proton
      #FIXME: possibly broken with this flake.lock
      #protonvpn-gui # VPN client by Proton
      signal-desktop # Encrypted messaging application
      telegram-desktop # Messaging
      teams-for-linux # Unofficial Microsoft Teams client
      tor-browser # Privacy-focused web browser
      vscode # Microsoft visual studio code IDE
      vesktop # Discord client
      vlc # Media player
      whatsapp-electron # Electron wrapper for whatsapp

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      bc # Arbitrary precision calculator
      carbon-now-cli # Create beautiful images of your code (carbon.now.sh CLI)
      cava # Console-based audio visualizer
      cloudflared # Cloudflare's command-line tool and daemon
      cloc # Count lines of code
      croc # Securely and easily send files between two computers
      efibootmgr # Manage UEFI boot entries
      fastfetch # Fast system information fetcher
      gh # GitHub CLI tool
      glow # Markdown renderer for the terminal
      grex # Command-line tool for generating regular expressions
      grim # Used to make screenshots with cli
      htop # Process viewer and killer
      killall # Command to kill processes by name
      lsof # List open files
      mediainfo # Display technical info about media files
      nix-search-cli # CLI tool to search nixpkgs from terminal
      ntfs3g # NTFS read/write support
      ripgrep # Fast line-oriented search tool
      screen # Terminal multiplexer
      tealdeer # Fast implementation of tldr (simplified man pages)
      ttyd # Share your terminal over the web
      unixtools.netstat # Network statistics
      usbutils # USB device utilities
      wakeonlan # Magic packets
      yt-dlp # Media downloader for YouTube and other sites

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      github-desktop # GitHub's official desktop client
      jq # Command-line JSON processor
      universal-ctags # Tool to generate index (tags) files of source code
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
    ]

    ++ (with pkgs-unstable; [
      # -----------------------------------------------------------------------
      # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
      # -----------------------------------------------------------------------
      fresh-editor # Lightweight terminal text editor
    ]);
}
