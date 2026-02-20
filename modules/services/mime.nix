{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.mime";
  # 🌟 Enabled by default to protect your desktop routing!
  options.programs.mime = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
    {
      myconfig,
      ...
    }:
    let
      # If variables are missing, these defaults will be used.
      safeEditor = myconfig.constants.editor or "vscode";
      safeBrowser = myconfig.constants.browser or "brave";
      safeTerm = myconfig.constants.term or "alacritty";
      safeFileManager = myconfig.constants.fileManager or "dolphin";

      # -----------------------------------------------------------------------
      # 1. HELPER: Terminal Editor Logic
      # -----------------------------------------------------------------------
      termEditors = {
        neovim = {
          bin = "nvim";
          icon = "nvim";
          name = "Neovim (User)";
        };
        nvim = {
          bin = "nvim";
          icon = "nvim";
          name = "Neovim (User)";
        };
        vim = {
          bin = "vim";
          icon = "vim";
          name = "Vim (User)";
        };
        nano = {
          bin = "nano";
          icon = "nano";
          name = "Nano (User)";
        };
        helix = {
          bin = "hx";
          icon = "helix";
          name = "Helix (User)";
        };
      };

      # Check if the chosen editor is a terminal one
      isTermEditor = builtins.hasAttr safeEditor termEditors;
      editorConfig = termEditors.${safeEditor};

      # Fixes browsers that don't follow the "name.desktop" convention
      browserDesktopMap = {
        "vivaldi" = "vivaldi-stable.desktop";
        "brave" = "brave-browser.desktop";
        "chrome" = "google-chrome.desktop";
        "chromium" = "chromium-browser.desktop";
      };

      # EDITOR
      myEditor =
        if isTermEditor then
          "user-${safeEditor}.desktop"
        else if safeEditor == "vscode" || safeEditor == "code" then
          "code.desktop"
        else
          "${safeEditor}.desktop";

      # BROWSER (Uses the map, defaults to name.desktop)
      myBrowser = browserDesktopMap.${safeBrowser} or "${safeBrowser}.desktop";

      # FILE MANAGER
      myFileManager =
        if safeFileManager == "dolphin" then "org.kde.dolphin.desktop" else "${safeFileManager}.desktop";

    in
    {
      # -----------------------------------------------------------------------
      # 🖥️ CUSTOM DESKTOP ENTRY (Terminal Editors Only)
      # -----------------------------------------------------------------------
      xdg.desktopEntries = lib.mkIf isTermEditor {
        "user-${safeEditor}" = {
          name = editorConfig.name;
          genericName = "Text Editor";
          comment = "Edit text files in ${safeTerm}";
          exec = "${safeTerm} -e ${editorConfig.bin} %F";
          icon = editorConfig.icon;
          terminal = false;
          categories = [
            "Utility"
            "TextEditor"
          ];
          mimeType = [
            "text/plain"
            "text/markdown"
            "text/x-nix"
          ];
        };
      };

      # -----------------------------------------------------------------------
      # 📂 MIME ASSOCIATIONS
      # -----------------------------------------------------------------------
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # Directories
          "inode/directory" = myFileManager;

          # Browser
          "text/html" = myBrowser;
          "x-scheme-handler/http" = myBrowser;
          "x-scheme-handler/https" = myBrowser;
          "x-scheme-handler/about" = myBrowser;
          "x-scheme-handler/unknown" = myBrowser;
          "application/pdf" = myBrowser;

          # Editor
          "text/plain" = myEditor;
          "text/markdown" = myEditor;
          "application/x-shellscript" = myEditor;
          "application/json" = myEditor;
          "text/x-nix" = myEditor;

          # Images (defaults to Gwenview)
          "image/jpeg" = "org.kde.gwenview.desktop";
          "image/png" = "org.kde.gwenview.desktop";
          "image/gif" = "org.kde.gwenview.desktop";
          "image/webp" = "org.kde.gwenview.desktop";

        };
      };
    };
}
