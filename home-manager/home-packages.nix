{ pkgs, pkgs-unstable, ... }:
{
  home.packages =
    (with pkgs; [
      # Packages in each category are sorted alphabetically

      # -----------------------------------------------------------------------------------
      # -----------------------------------------------------------------------------------
      #  ⚠️ START APPLICATIONS TO KEEP HERE BLOCK ⚠️

      # -----------------------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      imv # Image viewer (referenced in window rules)              -> ⚠️ KEEP
      mpv # Video player (referenced in window rules)              -> ⚠️ KEEP
      pavucontrol # Audio control (Vital for Hyprland)                     -> ⚠️ KEEP

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      brightnessctl # Control device backlight/brightness (needed for hyprland binds) -> ⚠️ KEEP
      cliphist # Wayland clipboard history manager (needed for clipboard management) -> ⚠️ KEEP
      ffmpegthumbnailer # Lightweight video thumbnailer (needed for ranger video previews) -> ⚠️ KEEP
      grimblast # Wayland screenshot helper for Hyprland (referenced in chromium.nix module) -> ⚠️ KEEP
      htop # Interactive process viewer (keep to kill processes easily) -> ⚠️ KEEP
      hyprpicker # Wayland color picker (needed for hyprland binds)         -> ⚠️ KEEP
      nixfmt-rfc-style # Nix code formatter with RFC style (used in flake.nix) -> ⚠️ KEEP
      playerctl # Control MPRIS-enabled media players (Spotify, etc.) (used in hyprland binds) -> ⚠️ KEEP
      showmethekey # Visualizer for keyboard input (used by hyprland binds) -> ⚠️ KEEP
      ueberzugpp # Image previews for terminal (used by Ranger backend) -> ⚠️ KEEP
      wget # File retrieval utility (used in various scripts) -> ⚠️ KEEP
      wl-clipboard # Wayland copy/paste CLI tools (needed for clipboard management) -> ⚠️ KEEP

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      vscode # Code editor (in my machine it would not installed if put in local-packages.nix) -> ⚠️ KEEP

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------
      #Modern hyprland does not need xwaylandvideobridge, it uses PipeWire, Wireplumber, and xdg-desktop-portal-hyprland
      # It may be needed for some legacy X11 apps, but most should work fine without it.
      #libsForQt5.xwaylandvideobridge
      libnotify # Library for desktop notifications (used by hyprland-notifications) -> ⚠️ KEEP
      xdg-desktop-portal-gtk # GTK portal backend for file pickers (needed for hyprland) -> ⚠️ KEEP
      xdg-desktop-portal-hyprland # Hyprland specific portal for screen sharing (needed for hyprland) -> ⚠️ KEEP

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds) -> ⚠️ KEEP
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used by nixos development) -> ⚠️ KEEP

      #  ⚠️ END APPLICATIONS TO KEEP HERE BLOCK ⚠️
      # -----------------------------------------------------------------------------------
      # -----------------------------------------------------------------------------------

      # -----------------------------------------------------------------------------------
      # -----------------------------------------------------------------------------------
      #  ⭐ START OF OTHER APPLICATION ⭐
      # There are application that are not strictly necessary to be kept here but are useful to have

      # -----------------------------------------------------------------------------------
      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      #winboat  # TODO: wait for the package to be fixed. currently has nmp dependencies issue during installation Run windows applications in linux
      kdePackages.audiotube # Client for youtube music

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      killall # Useful command to kill processes by name, such as waybar after a crash
      nix-search-cli # CLI tool to search nixpkgs from terminal
      ripgrep # Fast line-oriented search tool (needed by neovim) -> ⚠️ KEEP
      unzip # Extraction utility for .zip files (used by mason in neovim) -> ⚠️ KEEP
      wtype
      zip # Compression utility for .zip files (used by mason in neovim) -> ⚠️ KEEP
      zlib # Compression utility for .zip files (used by mason in neovim) -> ⚠️ KEEP

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      # Java Development Kit (needed for some Neovim LSP servers) -> ⚠️ KEEP
      jdk25
      nodejs # JavaScript runtime (needed for some Neovim plugins and LSP servers) -> ⚠️ KEEP
      (pkgs.python313.withPackages (
        ps: with ps; [
          black # The uncompromising code formatter
          flake8 # Style guide enforcement
          pip # Package installer for Python
          ruff # Extremely fast Python linter
        ]
      ))

      # -----------------------------------------------------------------------------------
      # 😂 FUN PACKAGES
      # -----------------------------------------------------------------------------------

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------

      #  ⭐ END OF OTHER APPLICATION ⭐
      # -----------------------------------------------------------------------------------
      # -----------------------------------------------------------------------------------
    ])
    ++ (with pkgs.kdePackages; [
      dolphin # File manager (default file picker) -> ⚠️ KEEP
      qtsvg # SVG Icon support (used in sddm.nix) -> ⚠️ KEEP
      kio-fuse # Mount remote filesystems (via ssh, ftp, etc.) in Dolphin -> ⚠️ KEEP
      kio-extras # Extra protocols for KDE file dialogs (needed for dolphin remote access) -> ⚠️ KEEP
    ])

    ++ (with pkgs-unstable; [
      # -----------------------------------------------------------------------
      # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
      # ----------------------------------------------------------------------
    ]);
}
