{ delib, pkgs, lib, ... }:
delib.module {
  name = "home-packages";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      translatedEditor =
        let
          e = myconfig.constants.editor or "vscode";
        in
        if e == "nvim" then "neovim" else e;

      fallbackTerm = pkgs.alacritty;
      fallbackBrowser = pkgs.brave;
      fallbackFileManager = pkgs.kdePackages.dolphin;
      fallbackEditor = pkgs.vscode;

      getPkg =
        name: fallback:
        if builtins.hasAttr name pkgs then
          pkgs.${name}
        else if builtins.hasAttr name pkgs.kdePackages then
          pkgs.kdePackages.${name}
        else
          fallback;

      termName = myconfig.constants.terminal or "alacritty";
      myTermPkg = getPkg termName fallbackTerm;

      browserName = myconfig.constants.browser or "brave";
      myBrowserPkg = getPkg browserName fallbackBrowser;

      fileManagerName = myconfig.constants.fileManager or "dolphin";
      myFileManagerPkg = getPkg fileManagerName fallbackFileManager;

      editorName = translatedEditor;
      myEditorPkg = getPkg editorName fallbackEditor;

      isModuleEnabled =
        name:
        (lib.attrByPath [ "programs" name "enable" ] false myconfig)
        || (lib.attrByPath [ "krit" "programs" name "enable" ] false myconfig);
    in
    {
      home.packages =
        (lib.optional (!isModuleEnabled termName) myTermPkg)
        ++ (lib.optional (!isModuleEnabled browserName) myBrowserPkg)
        ++ (lib.optional (!isModuleEnabled fileManagerName) myFileManagerPkg)
        ++ (lib.optional (!isModuleEnabled editorName) myEditorPkg);
    };
}
