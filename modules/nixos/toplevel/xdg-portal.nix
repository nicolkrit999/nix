{ delib
, pkgs
, ...
}:
let
  # `UseIn=` in each .portal manifest gates backend loadability per
  # XDG_CURRENT_DESKTOP. Stock gtk → `gnome`, kde → `KDE`, gnome → `gnome`.
  permissiveDesktops = "GNOME;KDE;COSMIC;Hyprland;niri;mango;sway;wlroots;X-Cinnamon;LXQt;XFCE;MATE";

  patchPortalPkg = pkgsArg: pkg: pkg.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      for f in $out/share/xdg-desktop-portal/portals/*.portal; do
        if grep -q '^UseIn=' "$f"; then
          ${pkgsArg.gnused}/bin/sed -i 's|^UseIn=.*|UseIn=${permissiveDesktops}|' "$f"
        fi
      done
    '';
  });

  portalConfig = {
    Hyprland = {
      default = [ "hyprland" "kde" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
    };
    KDE.default = [ "kde" "gtk" ];
    GNOME.default = [ "gnome" "gtk" ];
    cosmic.default = [ "cosmic" "gtk" ];
    niri = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
    };
    mango = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
    };
    common.default = [ "gtk" ];
  };
in
delib.module {
  name = "xdg-portal";

  nixos.always = {
    nixpkgs.overlays = [
      (final: prev: {
        xdg-desktop-portal-gtk = patchPortalPkg final prev.xdg-desktop-portal-gtk;
        kdePackages = prev.kdePackages.overrideScope (_: kdePrev: {
          xdg-desktop-portal-kde = patchPortalPkg final kdePrev.xdg-desktop-portal-kde;
        });
      })
    ];

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
      config = portalConfig;
    };
  };

  home.always = { ... }: {
    xdg.portal = {
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
      config = portalConfig;
    };
  };
}
