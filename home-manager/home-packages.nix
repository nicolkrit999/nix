{ pkgs, pkgs-unstable, vars, ... }:
let
  # 🔄 TRANSLATION LAYER
  translatedEditor = let e = vars.editor or "vscode";
  in if e == "nvim" then "neovim" else e;

  # 🛡️ SAFE FALLBACKS for browser, fileManager, editor
  # If the user's choice is invalid or missing, these are installed.
  fallbackTerm = pkgs.alacritty;
  fallbackBrowser = pkgs.brave;
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

  myTermPkg = getPkg (vars.term or "alacritty") fallbackTerm;
  myBrowserPkg = getPkg (vars.browser or "brave") fallbackBrowser;
  myFileManagerPkg = getPkg (vars.fileManager or "dolphin") fallbackFileManager;
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
    # If a package does not need/can't be configured with home-manager then it can be in common-configuration.nix or a host-specific configuration.nix
    ++ (with pkgs;
      [

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
      ])

    # 3. KDE PACKAGES
    ++ (with pkgs.kdePackages;
      [
        gwenview # Default image viewer as defined in mime.nix
      ])

    # 4. UNSTABLE PACKAGES
    ++ (with pkgs-unstable; [ ]);
}
