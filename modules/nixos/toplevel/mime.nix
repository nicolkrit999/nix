# Set defaults applications. If not enabled the system does not know with what to open file/directories/links and similar
{ delib
, lib
, moduleSystem
, options
, ...
}:
delib.module {
  name = "mime";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      home-manager.users.${myconfig.constants.user}.xdg.configFile."mimeapps.list".force = true;
    };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      editor = myconfig.constants.editor;
      browser = myconfig.constants.browser;
      termName = myconfig.constants.terminal.name;
      fileManager = myconfig.constants.fileManager;

      nvimEntry = {
        bin = "nvim";
        icon = "nvim";
        name = "Neovim (User)";
      };

      hasKritNvim =
        moduleSystem == "nixos"
        && (options ? myconfig.krit.programs.neovim)
        && (myconfig.krit.programs.neovim.enable or false);

      termEditors = {
        neovim = nvimEntry;
        nvim = nvimEntry;
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

      isNvimEditor = editor == "neovim" || editor == "nvim";
      deferToKritNvim = hasKritNvim && isNvimEditor;
      isTermEditor = builtins.hasAttr editor termEditors && !deferToKritNvim;
      editorConfig = termEditors.${editor};

      browserDesktopMap = {
        "brave" = "brave-browser.desktop";
        "chrome" = "google-chrome.desktop";
        "chromium" = "chromium-browser.desktop";
      };

      myEditor =
        if deferToKritNvim then
          "custom-nvim.desktop"
        else if isTermEditor then
          "user-${editor}.desktop"
        else if editor == "vscode" || editor == "code" then
          "code.desktop"
        else
          "${editor}.desktop";

      myBrowser = browserDesktopMap.${browser} or "${browser}.desktop";

      myMailer =
        if (myconfig.programs.thunderbird.enable or false) then
          "thunderbird.desktop"
        else
          myBrowser;

      myFileManager =
        if fileManager == "dolphin" then "org.kde.dolphin.desktop" else "${fileManager}.desktop";

    in
    {
      # -----------------------------------------------------------------------
      # 🖥️ CUSTOM DESKTOP ENTRY (Terminal Editors Only)
      # -----------------------------------------------------------------------
      xdg.desktopEntries = lib.mkIf isTermEditor {
        "user-${editor}" = {
          inherit (editorConfig) name icon;
          genericName = "Text Editor";
          comment = "Edit text files in ${termName}";
          exec = "${termName} -e ${editorConfig.bin} %F";
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

          # Mail (Thunderbird when enabled, otherwise the browser)
          "x-scheme-handler/mailto" = myMailer;

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
