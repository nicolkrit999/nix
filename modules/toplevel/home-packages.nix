{
  delib,
  pkgs,
  pkgs-unstable,
  lib,
  config,
  ...
}:
delib.module {
  name = "system.home-packages";

  # 🌟 THE FIX: Use 'nixos.always' so standard options like 'environment' work.
  nixos.always =
    { myconfig, ... }: # 🌟 Keep 'myconfig' as the variable name for your logic.
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
      # Now that we are in a 'nixos' hook, 'environment' is a valid top-level option.
      environment.systemPackages =
        let
          # ✅ This checks if a NixOS module is already handling the program
          isModuleEnabled = name: lib.attrByPath [ "programs" name "enable" ] false config;
        in
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
}
