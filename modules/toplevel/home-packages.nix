# Install home-manager related packages for every host
# Not enabling it breaks the logic that automatically install the terminal, browser, file manager and editor depending on host-specific constants
{
  delib,
  pkgs,
  pkgs-unstable,
  lib,
  config,
  ...
}:
delib.module {
  name = "home-packages";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
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

      termName = myconfig.constants.terminal or "alacritty";
      myTermPkg = getPkg termName fallbackTerm;

      browserName = myconfig.constants.browser or "brave";
      myBrowserPkg = getPkg browserName fallbackBrowser;

      fileManagerName = myconfig.constants.fileManager or "dolphin";
      myFileManagerPkg = getPkg fileManagerName fallbackFileManager;

      editorName = translatedEditor;
      myEditorPkg = getPkg editorName fallbackEditor;
    in
    {

      environment.systemPackages =
        let
          # ✅ This checks if a NixOS module is already handling the program
          # If the host has enabled a module in this way then it's not installed from this file to avoid evaluations errors due to duplicates
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
