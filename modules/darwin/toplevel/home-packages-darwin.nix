# Install packages based on host constants for Darwin hosts
{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "home-packages";
  options = delib.singleEnableOption true;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      # 🔄 TRANSLATION LAYER
      translatedEditor =
        let
          e = myconfig.constants.editor or "vscode";
        in
        if e == "nvim" then "neovim" else e;

      # 🛡️ SAFE FALLBACKS (Darwin-appropriate defaults)
      fallbackTerm = pkgs.alacritty;
      fallbackBrowser = pkgs.firefox;
      fallbackFileManager = pkgs.yazi;
      fallbackEditor = pkgs.vscode;

      # 🔍 PACKAGE LOOKUP (no kdePackages on Darwin)
      getPkg = name: fallback:
        if builtins.hasAttr name pkgs then pkgs.${name}
        else fallback;

      termName = myconfig.constants.terminal or "alacritty";
      myTermPkg = getPkg termName fallbackTerm;

      browserName = myconfig.constants.browser or "firefox";
      myBrowserPkg = getPkg browserName fallbackBrowser;

      fileManagerName = myconfig.constants.fileManager or "yazi";
      myFileManagerPkg = getPkg fileManagerName fallbackFileManager;

      editorName = translatedEditor;
      myEditorPkg = getPkg editorName fallbackEditor;
    in
    {
      environment.systemPackages =
        let
          # ✅ Check if any module (system-level or any home-manager user) already handles this program
          isProgramEnabled = name:
            lib.attrByPath [ "programs" name "enable" ] false config
            || lib.attrByPath [ "home-manager" "users" myconfig.constants.user "programs" name "enable" ] false config;
        in
        (lib.optional (!isProgramEnabled termName) myTermPkg)
        ++ (lib.optional (!isProgramEnabled browserName) myBrowserPkg)
        ++ (lib.optional (!isProgramEnabled fileManagerName) myFileManagerPkg)
        ++ (lib.optional (!isProgramEnabled editorName) myEditorPkg);
    };
}
