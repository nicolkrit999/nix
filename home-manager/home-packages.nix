{ pkgs, pkgs-unstable, vars, ... }:
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
  getPkg = name: fallback:
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
in {
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

      # -----------------------------------------------------------------------------------
      # 🖥️ CLI UTILITIES
      # -----------------------------------------------------------------------------------
      cliphist # Wayland clipboard history manager (needed for clipboard management in most de/wm modules)

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGER (WM) INFRASTRUCTURE
      # -----------------------------------------------------------------------

      # -----------------------------------------------------------------------
      # ❓ OTHER
      # -----------------------------------------------------------------------
      bemoji # Emoji picker with dmenu/wofi support (used in hyprland binds)
    ])

    # 3. KDE PACKAGES
    ++ (with pkgs.kdePackages;
      [
        gwenview # Default image viewer as defined in mime.nix
      ])

    # 4. UNSTABLE PACKAGES
    ++ (with pkgs-unstable; [ ]);
}
