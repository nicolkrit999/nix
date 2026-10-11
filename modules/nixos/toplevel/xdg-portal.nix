{ delib
, lib
, pkgs
, ...
}:
let
  # Only the manifest-only gnome-keyring portal and the wlr patch use UseIn;
  # xdp 1.22 reads it solely in its deprecated fallback, config routes ignore it.
  secretUseIn = "GNOME;KDE;COSMIC;Hyprland;niri;mango;sway;wlroots;X-Cinnamon;LXQt;XFCE;MATE";
  wlrDesktops = "mango;sway;wlroots";

  patchPortalPkg = useIn: pkgsArg: pkg: pkg.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      for f in $out/share/xdg-desktop-portal/portals/*.portal; do
        if grep -q '^UseIn=' "$f"; then
          ${pkgsArg.gnused}/bin/sed -i 's|^UseIn=.*|UseIn=${useIn}|' "$f"
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
    UseIn=${secretUseIn}
    EOF
  '';

  secretPortal = { "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ]; };

  # "none" stops xdp's deprecated UseIn fallback from picking a backend that
  # belongs to another desktop (kde, or hyprland under mango:wlroots).
  noRoutes = names: lib.genAttrs (map (n: "org.freedesktop.impl.portal.${n}") names) (_: [ "none" ]);
  sessionOnlyNames = [ "Background" "GlobalShortcuts" "RemoteDesktop" "Clipboard" "InputCapture" "Usb" ];

  # xdg-desktop-portal lowercases XDG_CURRENT_DESKTOP before looking up <desktop>-portals.conf,
  # so these keys must be lowercase.
  portalConfig = {
    hyprland = {
      default = [ "hyprland" "gtk" ];
    } // secretPortal;
    kde = {
      default = [ "kde" "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "plasmanotify" "gtk" ];
    } // secretPortal;
    gnome = { default = [ "gnome" "gtk" ]; } // secretPortal;
    cosmic = { default = [ "cosmic" "gtk" ]; } // noRoutes sessionOnlyNames // secretPortal;
    niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    } // secretPortal;
    # The mango flake sets the same Secret value; mkForce avoids a duplicated list.
    mango = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = lib.mkForce [ "gnome-keyring" ];
      # I-15: the mango flake sets these system-side only; mkForce + shared
      # binding keeps the home-manager portal config identical.
      "org.freedesktop.impl.portal.ScreenCast" = lib.mkForce [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = lib.mkForce [ "wlr" ];
      "org.freedesktop.impl.portal.Inhibit" = lib.mkForce [ "none" ];
    } // noRoutes sessionOnlyNames;
    common = { default = [ "gtk" ]; } // noRoutes (sessionOnlyNames ++ [ "ScreenCast" ]) // secretPortal;
  };
in
delib.module {
  name = "xdg-portal";

  nixos.always = {
    nixpkgs.overlays = [
      (final: prev: {
        xdg-desktop-portal-wlr = patchPortalPkg wlrDesktops final prev.xdg-desktop-portal-wlr;
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
        pkgs.xdg-desktop-portal-gnome
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
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-wlr
        pkgs.kdePackages.xdg-desktop-portal-kde
        gnomeKeyringPortal
      ];
      config = portalConfig;
    };
  };
}
