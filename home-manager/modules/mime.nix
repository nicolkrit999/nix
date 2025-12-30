{
  pkgs,
  browser,
  editor,
  fileManager,
  ...
}:
let
  mkDesktop =
    name:
    if name == "dolphin" then
      "org.kde.dolphin.desktop"
    else if name == "kate" then
      "org.kde.kate.desktop"
    else if name == "vscode" || name == "code" then
      "code.desktop"
    else
      "${name}.desktop";

  myBrowser = mkDesktop browser;
  myFileManager = mkDesktop fileManager;
  myEditor = mkDesktop editor;
in
{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "inode/directory" = myFileManager;

      "text/html" = myBrowser;
      "x-scheme-handler/http" = myBrowser;
      "x-scheme-handler/https" = myBrowser;
      "x-scheme-handler/about" = myBrowser;
      "x-scheme-handler/unknown" = myBrowser;

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
      "application/pdf" = "org.pwmt.zathura.desktop";
    };
  };
}
