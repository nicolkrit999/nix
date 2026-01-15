{
  pkgs,
  vars,
  lib,
  ...
}:
let
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
  isTermEditor = builtins.hasAttr vars.editor termEditors;
  editorConfig = termEditors.${vars.editor};

  # -----------------------------------------------------------------------
  # 2. LOGIC: Determine the .desktop file name
  # -----------------------------------------------------------------------
  myEditor =
    if isTermEditor then
      # If it's a terminal editor, use our custom generated file
      "user-${vars.editor}.desktop"
    else
    # If it's a GUI editor (VSCode), use the standard system file
    if vars.editor == "vscode" || vars.editor == "code" then
      "code.desktop"
    else
      "${vars.editor}.desktop";

  myBrowser = "${vars.browser}.desktop";
  myFileManager =
    if vars.fileManager == "dolphin" then "org.kde.dolphin.desktop" else "${vars.fileManager}.desktop";

in
{
  # -----------------------------------------------------------------------
  # 🖥️ CUSTOM DESKTOP ENTRY (Terminal Editors Only)
  # -----------------------------------------------------------------------
  # This creates a mimeapps.list file under ~/.local/share/applications/mimeapps.list
  xdg.desktopEntries = lib.mkIf isTermEditor {
    "user-${vars.editor}" = {
      name = editorConfig.name;
      genericName = "Text Editor";
      comment = "Edit text files in ${vars.term}";
      exec = "${vars.term} -e ${editorConfig.bin} %F";
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
      "inode/directory" = myFileManager;

      "text/html" = myBrowser;
      "x-scheme-handler/http" = myBrowser;
      "x-scheme-handler/https" = myBrowser;
      "x-scheme-handler/about" = myBrowser;
      "x-scheme-handler/unknown" = myBrowser;

      # Force these types to use our calculated 'myEditor'
      "text/plain" = myEditor;
      "text/markdown" = myEditor;
      "application/x-shellscript" = myEditor;
      "application/json" = myEditor;
      "text/x-nix" = myEditor;

      # Images
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/png" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";

      # PDFs
      "application/pdf" = myBrowser;
    };
  };
}
