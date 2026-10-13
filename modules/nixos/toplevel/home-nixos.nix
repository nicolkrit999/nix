{ delib
, pkgs
, lib
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "home";

  home.always =
    { myconfig, ... }:
    let
      inherit (myconfig.constants) user;
      homeDir = "/home/${user}";
    in
    {
      home = {
        username = user;
        homeDirectory = homeDir;
        stateVersion = myconfig.constants.homeStateVersion;
      } // lib.optionalAttrs (moduleSystem == "home") {
        sessionPath = [ "$HOME/.local/bin" ];
      };

      programs.home-manager.enable = true;

    } // lib.optionalAttrs (moduleSystem == "home") {
      nixpkgs.config.allowUnfree = true;
    };

  nixos.always =
    { myconfig, ... }:
    {
      home-manager = {
        sharedModules = [
          {
            xdg.userDirs.setSessionVariables = false;
          }
        ];

        users.${myconfig.constants.user} =
          { config, ... }:
          let
            inherit (config.gtk) gtk3 gtk4;
            stylixGtk = (config.stylix.enable or false) && (config.stylix.targets.gtk.enable or false);
          in
          {
            gtk.gtk2.force = true;

            xdg = {
              enable = true;
              userDirs = {
                enable = true;
                createDirectories = true;
              };

              configFile = {
                "gtk-3.0/settings.ini" = lib.mkIf (config.gtk.enable && gtk3.enable) { force = true; };
                "gtk-3.0/gtk.css" = lib.mkIf (config.gtk.enable && gtk3.enable && (stylixGtk || gtk3.extraCss != "")) { force = true; };
                "gtk-4.0/settings.ini" = lib.mkIf (config.gtk.enable && gtk4.enable) { force = true; };
                "gtk-4.0/gtk.css" = lib.mkIf (config.gtk.enable && gtk4.enable && (stylixGtk || gtk4.extraCss != "" || (gtk4.theme != null && gtk4.theme.package != null))) { force = true; };

                "menus/applications.menu".text = ''
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
              };

              # ksecretd entry points only; do NOT stub kwalletd5/6 (frontends into gnome-keyring).
              # See Documentation/usage/gotchas/secret-service-single-provider.md
              dataFile = {
                "dbus-1/services/org.kde.kwalletd.service".text = ''
                  [D-BUS Service]
                  Name=org.kde.kwalletd
                  Exec=${pkgs.coreutils}/bin/false
                '';
                "dbus-1/services/org.kde.secretservicecompat.service".text = ''
                  [D-BUS Service]
                  Name=org.kde.secretservicecompat
                  Exec=${pkgs.coreutils}/bin/false
                '';
                "dbus-1/services/org.freedesktop.impl.portal.desktop.kwallet.service".text = ''
                  [D-BUS Service]
                  Name=org.freedesktop.impl.portal.desktop.kwallet
                  Exec=${pkgs.coreutils}/bin/false
                '';
              };
            };

            home.activation = {
              removeExistingConfigs = inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
                rm -f "$HOME/.config/mimeapps.list.hm-backup"
                if [ -L "$HOME/.config/fastfetch" ]; then
                  rm -f "$HOME/.config/fastfetch"
                fi
              '';
              createEssentialDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                mkdir -p "${myconfig.constants.screenshots}"
              '';
            };
          };
      };
    };
}
