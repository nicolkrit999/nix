{
  xdg.mime.defaultApplications = {
    # 📂 Directories
    "inode/directory" = "org.kde.dolphin.desktop";

    # 🌍 Web
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";

    # 📝 Text Files (.txt, .md, .nix, etc)
    "text/plain" = "org.kde.kate.desktop";
    "application/x-shellscript" = "code.desktop";

    # 🖼️ Images (Gwenview)
    "image/jpeg" = "org.kde.gwenview.desktop";
    "image/png" = "org.kde.gwenview.desktop";
    "image/gif" = "org.kde.gwenview.desktop";
    "image/webp" = "org.kde.gwenview.desktop";

    # 📄 PDFs (Okular)
    "application/pdf" = "org.pwmt.zathura.desktop";
  };
}
