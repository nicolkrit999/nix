# 🌟 1. ALL standard NixOS variables go up here at the top!
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

  # 🌟 2. Denix provides its own variables here
  myconfig.always =
    { myconfig, ... }:
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
      # 🌟 THE FIX: Since you removed Home Manager, use environment.systemPackages
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
