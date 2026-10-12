{ delib
, pkgs
, lib
, ...
}:

delib.module {
  name = "programs.vikunja-desktop";
  options = delib.singleEnableOption false;

  home.ifEnabled = lib.mkMerge [
    { home.packages = [ pkgs.vikunja-desktop ]; }
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      xdg.desktopEntries.vikunja-desktop = {
        name = "Vikunja Desktop";
        genericName = "To-Do list app";
        comment = "Desktop App of Vikunja to-do list app";
        exec = "${pkgs.vikunja-desktop}/bin/vikunja-desktop %u";
        icon = "vikunja-desktop";
        terminal = false;
        type = "Application";
        categories = [ "Office" "ProjectManagement" ];
        mimeType = [ "x-scheme-handler/vikunja-desktop" ];
      };

      xdg.mimeApps.defaultApplications."x-scheme-handler/vikunja-desktop" = "vikunja-desktop.desktop";
    })
  ];
}
