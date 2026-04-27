{ delib
, pkgs
, ...
}:
delib.module {
  name = "xdg-portal";

  nixos.always = {
    # Make portal configs and desktop entries visible system-wide
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    xdg.portal = {
      enable = true;

      # GTK portal is the universal fallback — always available
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      config = {
        # Hyprland: hyprland for screenshare, prefer KDE file picker (Qt theme consistency), GTK fallback
        Hyprland = {
          default = [ "hyprland" "kde" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
        };

        # KDE: native portal, GTK fallback
        KDE = {
          default = [ "kde" "gtk" ];
        };

        # GNOME: native portal, GTK fallback
        GNOME = {
          default = [ "gnome" "gtk" ];
        };

        # COSMIC: native portal, GTK fallback
        cosmic = {
          default = [ "cosmic" "gtk" ];
        };

        # Niri: no native portal; prefer KDE file picker if available (Qt theme), GTK fallback
        niri = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
        };

        # Mango: no native portal; prefer KDE file picker if available (Qt theme), GTK fallback
        mango = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
        };

        # Fallback for any unrecognized desktop or server with no DE
        common = {
          default = [ "gtk" ];
        };
      };
    };
  };
}
