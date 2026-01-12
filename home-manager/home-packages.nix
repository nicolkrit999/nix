{ pkgs
, pkgs-unstable
, vars
, ...
}:
let
  # 🔄 TRANSLATION LAYER
  translatedEditor = if vars.editor == "nvim" then "neovim" else vars.editor;

  # 🛡️ SAFE FALLBACKS for browser, fileManager, editor
  # If the user's choice is invalid or missing, these are installed.
  fallbackTerm = pkgs.alacritty;
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

  myTermPkg = getPkg vars.term fallbackTerm;
  myBrowserPkg = getPkg vars.browser fallbackBrowser;
  myFileManagerPkg = getPkg vars.fileManager fallbackFileManager;
  myEditorPkg = getPkg translatedEditor fallbackEditor;
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
      pavucontrol # Audio control (Vital for Hyprland and caelestia)

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      cliphist # Wayland clipboard history manager (needed for clipboard management)
      dix # Nix diff viewer between generations
      eza # Modern ls replacement (used by eza.nix module)
      fd # Fast file finder (used in various scripts)
      fzf # Fuzzy finder (used in various scripts)
      git # Version control system (used in various scripts)
      nixfmt-rfc-style # Nix code formatter with RFC style (used in flake.nix)
      starship # Shell prompt (used by starship.nix)
      zoxide # Jump around filesystem (used in various scripts)

      # -----------------------------------------------------------------------------------
      # 🧑🏽‍💻 CODING
      # -----------------------------------------------------------------------------------
      #

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------
      libnotify # Library for desktop notifications (used by hyprland-notifications)
      xdg-desktop-portal-gtk # GTK portal backend for file pickers

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds)
      nix-prefetch-scripts # Tools to get hashes for nix derivations (used in zsh.nix module)
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
