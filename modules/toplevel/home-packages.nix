{ delib, ... }:
delib.module {
  name = "system.home-packages";

  nixos.always =
    {
      pkgs,
      pkgs-unstable,
      myconfig,
      lib,
      ...
    }:
    let
      # 🔄 TRANSLATION LAYER
      # Ensure these names match the 'programs.<name>' module in Home Manager
      translatedEditor =
        let
          e = myconfig.constants.editor or "vscode";
        in
        if e == "nvim" then "neovim" else e;

      # 🛡️ SAFE FALLBACKS
      fallbackTerm = pkgs.alacritty;
      fallbackBrowser = pkgs.brave;
      fallbackFileManager = pkgs.kdePackages.dolphin;
      fallbackEditor = pkgs.vscode;

      # 🔍 PACKAGE LOOKUP
      getPkg =
        name: fallback:
        if builtins.hasAttr name pkgs then
          pkgs.${name}
        else if builtins.hasAttr name pkgs.kdePackages then
          pkgs.kdePackages.${name}
        else
          fallback;

      termName = myconfig.constants.term or "alacritty";
      myTermPkg = getPkg termName fallbackTerm;

      browserName = myconfig.constants.browser or "brave";
      myBrowserPkg = getPkg browserName fallbackBrowser;

      fileManagerName = myconfig.constants.fileManager or "dolphin";
      myFileManagerPkg = getPkg fileManagerName fallbackFileManager;

      editorName = translatedEditor;
      myEditorPkg = getPkg editorName fallbackEditor;

      # If a program is installed with a module it's skipped to avoid build problems
      isModuleEnabled = name: lib.attrByPath [ "programs" name "enable" ] false config;

    in

    {

      home-manager.users.${myconfig.constants.user} =
        { config, ... }:
        let
          isModuleEnabled = name: lib.attrByPath [ "programs" name "enable" ] false config;
        in
        {
          home.packages =
            # 1. DYNAMIC INSTALLATION
            # These are installed based on user choices in variables.nix: browser, fileManager, editor
            (lib.optional (!isModuleEnabled termName) myTermPkg)
            ++ (lib.optional (!isModuleEnabled browserName) myBrowserPkg)
            ++ (lib.optional (!isModuleEnabled fileManagerName) myFileManagerPkg)
            ++ (lib.optional (!isModuleEnabled editorName) myEditorPkg)

            # 2. STATIC INSTALLATION
            # These are always installed, regardless of user choices
            # Packages in each category are sorted alphabetically
            # ⚠️ All these packages should be kept. The reason is indicated next to each package.
            # If a package does not need/can't be configured with home-manager then it can be in common-configuration.nix or a host-specific configuration.nix
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
            ])

            # 3. KDE PACKAGES
            ++ (with pkgs.kdePackages; [
              gwenview # Default image viewer as defined in mime.nix
            ])

            # 4. UNSTABLE PACKAGES
            ++ (with pkgs-unstable; [ ]);
        };
    };
}
