{
  delib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "home";

  nixos.always =
    { myconfig, ... }:
    {
      home-manager.users.${myconfig.constants.user} =
        { config, ... }:
        {
          home = {
            username = myconfig.constants.user;
            homeDirectory = "/home/${myconfig.constants.user}";
            stateVersion = myconfig.constants.homeStateVersion or "25.11";
            sessionPath = [ "$HOME/.local/bin" ];
          };

          programs.home-manager.enable = true;

          xdg = {
            enable = true;
            mimeApps.enable = true;
            userDirs = {
              enable = true;
              createDirectories = true;
            };

            configFile."menus/applications.menu".text = ''
              <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
              "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
              <Menu>
                <Name>Applications</Name>
                <DefaultAppDirs/>
                <DefaultDirectoryDirs/>
                <Include>
                  <Category>System</Category>
                  <Category>Utility</Category>
                </Include>
              </Menu>
            '';

            dataFile."dbus-1/services/org.kde.kwalletd5.service".text = ''
              [D-BUS Service]
              Name=org.kde.kwalletd5
              Exec=${pkgs.coreutils}/bin/false
            '';
            dataFile."dbus-1/services/org.kde.kwalletd.service".text = ''
              [D-BUS Service]
              Name=org.kde.kwalletd
              Exec=${pkgs.coreutils}/bin/false
            '';
          };

          home.activation = {
            removeExistingConfigs = inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
              rm -f "$HOME/.config/autostart/gnome-keyring-force.desktop"
              rm -f "$HOME/.gtkrc-2.0"
              rm -f "$HOME/.config/gtk-3.0/settings.ini"
              rm -f "$HOME/.config/gtk-3.0/gtk.css"
              rm -f "$HOME/.config/gtk-4.0/settings.ini"
              rm -f "$HOME/.config/gtk-4.0/gtk.css"
              rm -f "$HOME/.config/dolphinrc"
              rm -f "$HOME/.config/kdeglobals"
              rm -f "$HOME/.local/share/applications/mimeapps.list"
            '';
            createEssentialDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p "${myconfig.constants.screenshots}"
            '';

            updateKDECache = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              if command -v kbuildsycoca6 >/dev/null; then
                kbuildsycoca6 --noincremental || true
              fi
            '';
          };
        };
    };
}
