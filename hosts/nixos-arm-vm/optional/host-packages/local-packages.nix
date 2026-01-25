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
      libreoffice-qt # Open source microsoft office alternative
      localsend # Simple file sharing over local network
      #protonvpn-gui # VPN client by Proton (currently not supported on arm despite nixpkgs telling otherwise)
      signal-desktop # Encrypted messaging application
      telegram-desktop # Messaging
      teams-for-linux # Unofficial Microsoft Teams client
      whatsapp-electron # Electron wrapper for whatsapp

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      htop # Process viewer and killer
      killall # Command to kill processes by name
      lsof # List open files
      nix-search-cli # CLI tool to search nixpkgs from terminal
      tealdeer # Fast implementation of tldr (simplified man pages)

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------

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
    ]);
}
