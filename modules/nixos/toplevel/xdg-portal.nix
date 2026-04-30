{ delib
, pkgs
, ...
}:
let
  # `UseIn=` in each .portal manifest gates backend loadability per
  # XDG_CURRENT_DESKTOP. Stock gtk → `gnome`, kde → `KDE`, gnome → `gnome`.
  # Under Hyprland/niri/mango/cosmic/etc. all are rejected → no FileChooser
  # interface exposed → Chromium apps (Helium) silently fail to open file
  # pickers. We rewrite UseIn= to a permissive desktop list. Per-DE backend
  # selection is still driven by the `xdg.portal.config` block below.
  #
  # Add a new WM here when needed.
  permissiveDesktops = "GNOME;KDE;COSMIC;Hyprland;niri;mango;sway;wlroots;X-Cinnamon;LXQt;XFCE;MATE";

  # Why an overlay instead of wrapping inline in extraPortals: other NixOS
  # modules (flatpak, plasma6, gnome, etc.) reference these portal packages
  # too. Wrapping inline would put both the stock and patched derivations
  # into systemd.packages, and user-units would collide on the duplicate
  # xdg-desktop-portal-gtk.service symlink (build error: "File exists").
  # An overlay replaces the package globally — single derivation, no clash.
in
delib.module {
  name = "xdg-portal";

  nixos.always = {
    nixpkgs.overlays = [
      (final: prev:
        let
          patchUseIn = pkg: pkg.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              for f in $out/share/xdg-desktop-portal/portals/*.portal; do
                if grep -q '^UseIn=' "$f"; then
                  ${final.gnused}/bin/sed -i 's|^UseIn=.*|UseIn=${permissiveDesktops}|' "$f"
                fi
              done
            '';
          });
        in
        {
          xdg-desktop-portal-gtk = patchUseIn prev.xdg-desktop-portal-gtk;
          kdePackages = prev.kdePackages.overrideScope (_: kdePrev: {
            xdg-desktop-portal-kde = patchUseIn kdePrev.xdg-desktop-portal-kde;
          });
        }
      )
    ];

    # Make portal configs and desktop entries visible system-wide
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    xdg.portal = {
      enable = true;

      # GTK = generic fallback. KDE = the only widely-available backend
      # that still ships a FileChooser implementation. Both are already
      # patched via the overlay above; this just registers them with
      # xdg-desktop-portal so it knows to load them.
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];

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
