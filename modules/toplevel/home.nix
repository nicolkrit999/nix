{
  delib,
  pkgs,
  config,
  lib,
  ...
}:
delib.module {
  name = "home";

  nixos.always =
    { constants, ... }:
    {
      home-manager.users.${constants.user} =
        { config, lib, ... }:
        {

          home = {
            username = constants.user;
            homeDirectory = "/home/${constants.user}";
            stateVersion = constants.homeStateVersion or "25.11";
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

          home.file.".local/bin/init-gnome-keyring.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              pkill -f kwallet || true
              sleep 0.5
              eval $(${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)
              export SSH_AUTH_SOCK
              export GNOME_KEYRING_CONTROL
              export GNOME_KEYRING_PID
              ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
              ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd SSH_AUTH_SOCK GNOME_KEYRING_CONTROL GNOME_KEYRING_PID

              if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
                 if command -v hyprctl >/dev/null; then
                    hyprctl setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
                    hyprctl setenv GNOME_KEYRING_CONTROL "$GNOME_KEYRING_CONTROL"
                    hyprctl setenv GNOME_KEYRING_PID "$GNOME_KEYRING_PID"
                 fi
              fi
            '';
          };

          home.file.".config/plasma-workspace/env/99-init-keyring.sh".source =
            config.lib.file.mkOutOfStoreSymlink "/home/${constants.user}/.local/bin/init-gnome-keyring.sh";

          home.activation = {
            removeExistingConfigs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
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
            createEssentialDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p "${constants.screenshots}"
            '';
            updateKDECache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              if command -v kbuildsycoca6 >/dev/null; then
                kbuildsycoca6 --noincremental || true
              fi
            '';
          };
        };
    };
}
