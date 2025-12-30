{
  pkgs,
  pkgs-unstable,
  term,
  browser,
  fileManager,
  editor,
  ...
}:
let
  # 🛡️ SAFE FALLBACKS for browser, fileManager, editor
  # If the user's choice is invalid or missing, these are installed.
  fallbackTerm = pkgs.kitty;
  fallbackBrowser = pkgs.google-chrome;
  fallbackFileManager = pkgs.kdePackages.dolphin;
  fallbackEditor = pkgs.vscode;

  # 🔍 PACKAGE LOOKUP FUNCTION
  # Tries to find 'pkgs.userInput'. If not found, returns the fallback.
  getPkg =
    name: fallback:
    if builtins.hasAttr name pkgs then
      pkgs.${name}
    else if builtins.hasAttr name pkgs.kdePackages then
      pkgs.kdePackages.${name}
    else
      fallback;

  myTermPkg = getPkg term fallbackTerm;
  myBrowserPkg = getPkg browser fallbackBrowser;
  myFileManagerPkg = getPkg fileManager fallbackFileManager;
  myEditorPkg = getPkg editor fallbackEditor;
in
{
  home.packages =
    # 1. DYNAMIC INSTALLATION
    # These are installed based on user choices in variables.nix: browser, fileManager, editor
    [
      myTermPkg
      myBrowserPkg
      myFileManagerPkg
      myEditorPkg
    ]

    # 2. STATIC INSTALLATION
    # These are always installed, regardless of user choices
    # Packages in each category are sorted alphabetically
    # ⚠️ All these packages should be kept. The reason is indicated next to each package.
    ++ (with pkgs; [

      # 🖥️ DESKTOP APPLICATIONS
      # -----------------------------------------------------------------------------------
      imv # Image viewer (referenced in window rules)
      mpv # Video player (referenced in window rules)
      pavucontrol # Audio control (Vital for Hyprland)

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      brightnessctl # Control device backlight/brightness (needed for hyprland binds)
      cliphist # Wayland clipboard history manager (needed for clipboard management)
      eza # Modern ls replacement (used in shell and ranger)
      ffmpegthumbnailer # Lightweight video thumbnailer (needed for ranger video previews)
      fzf # Fuzzy finder (used in shell and ranger)
      git # Version control system (used in various scripts)
      grimblast # Wayland screenshot helper for Hyprland (referenced in chromium.nix module)
      htop # Interactive process viewer (keep to kill processes easily)
      hyprpicker # Wayland color picker (needed for hyprland binds)
      nixfmt-rfc-style # Nix code formatter with RFC style (used in flake.nix)
      playerctl # Control MPRIS-enabled media players (Spotify, etc.) (used in hyprland binds)
      showmethekey # Visualizer for keyboard input (used by hyprland binds)
      starship # Shell prompt (used by starship.nix)
      ueberzugpp # Image previews for terminal (used by Ranger backend)
      wl-clipboard # Wayland copy/paste CLI tools (needed for clipboard management)
      zsh-autosuggestions # Fish-like autosuggestions for Zsh (used in zsh config)

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      #

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------
      libnotify # Library for desktop notifications (used by hyprland-notifications)
      xdg-desktop-portal-gtk # GTK portal backend for file pickers (needed for hyprland)
      xdg-desktop-portal-hyprland # Hyprland specific portal for screen sharing (needed for hyprland)

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds)
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used by nixos development)

    ])

    # 3. KDE PACKAGES
    ++ (with pkgs.kdePackages; [
      gwenview # Default image viewer as defined in mime.nix
      kio-extras # Extra protocols for KDE file dialogs (needed for dolphin remote access)
      kio-fuse # Mount remote filesystems (via ssh, ftp, etc.) in Dolphin
    ])

    # 4. UNSTABLE PACKAGES
    ++ (with pkgs-unstable; [
      # -----------------------------------------------------------------------
      # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
      # ----------------------------------------------------------------------
    ]);
}
