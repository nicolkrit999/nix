{ delib, config, ... }:
delib.module {
  name = "system.home-packages";

  nixos.always =
    {
      pkgs,
      pkgs-unstable,
      myconfig,
      config,
      lib,
      ...
    }:
    let
      # 🔄 TRANSLATION LAYER
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
    in
    {
      home-manager.users.${myconfig.constants.user} =
        { config, ... }: # 🌟 Home Manager's config safely loads here!
        let
          # ✅ The module check ONLY lives here now
          isModuleEnabled = name: lib.attrByPath [ "programs" name "enable" ] false config;
        in
        {
          home.packages =
            (lib.optional (!isModuleEnabled termName) myTermPkg)
            ++ (lib.optional (!isModuleEnabled browserName) myBrowserPkg)
            ++ (lib.optional (!isModuleEnabled fileManagerName) myFileManagerPkg)
            ++ (lib.optional (!isModuleEnabled editorName) myEditorPkg)
            ++ (with pkgs; [
              cliphist
            ])
            ++ (with pkgs.kdePackages; [
              gwenview
            ])
            ++ (with pkgs-unstable; [ ]);
        };
    };
}
