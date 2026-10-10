{ delib
, lib
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

  # Manifest-only: routes org.freedesktop.impl.portal.Secret to the running
  # gnome-keyring. The full package is not added because its (non-setcap)
  # org.freedesktop.secrets.service would shadow the system one.
  gnomeKeyringPortal = pkgs.runCommand "gnome-keyring-portal-manifest" { } ''
    mkdir -p $out/share/xdg-desktop-portal/portals
    cat > $out/share/xdg-desktop-portal/portals/gnome-keyring.portal <<EOF
    [portal]
    DBusName=org.freedesktop.secrets
    Interfaces=org.freedesktop.impl.portal.Secret
    UseIn=${permissiveDesktops}
    EOF
  '';

  secretPortal = { "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ]; };

  # xdg-desktop-portal lowercases XDG_CURRENT_DESKTOP before looking up <desktop>-portals.conf,
  # so these keys must be lowercase.
  portalConfig = {
    hyprland = {
      default = [ "hyprland" "kde" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
    } // secretPortal;
    kde = { default = [ "kde" "gtk" ]; } // secretPortal;
    gnome = { default = [ "gnome" "gtk" ]; } // secretPortal;
    cosmic = { default = [ "cosmic" "gtk" ]; } // secretPortal;
    niri = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
    } // secretPortal;
    # The mango flake sets the same Secret value; mkForce avoids a duplicated list.
    mango = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = lib.mkForce [ "gnome-keyring" ];
    };
    common = { default = [ "gtk" ]; } // secretPortal;
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
        gnomeKeyringPortal
      ];
      config = portalConfig;
    };
  };

  home.always = { ... }: {
    xdg.portal = {
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.kdePackages.xdg-desktop-portal-kde
        gnomeKeyringPortal
      ];
      config = portalConfig;
    };
  };
}
