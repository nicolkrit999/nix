{ delib
, lib
, pkgs
, moduleSystem
, ...
}:
let
  # UseIn is only a deprecated xdp 1.22 fallback; see the xdg-desktop-portal gotcha doc.
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

  # Manifest-only: the full package's secrets.service would shadow the system one.
  gnomeKeyringPortal = pkgs.runCommand "gnome-keyring-portal-manifest" { } ''
    mkdir -p $out/share/xdg-desktop-portal/portals
    cat > $out/share/xdg-desktop-portal/portals/gnome-keyring.portal <<EOF
    [portal]
    DBusName=org.freedesktop.secrets
    Interfaces=org.freedesktop.impl.portal.Secret
    UseIn=${secretUseIn}
    EOF
  '';

  # Standalone home builds use stock pkgs: see Documentation/usage/gotchas/xdg-desktop-portal-nixos.md
  wlrPortal =
    if moduleSystem == "home"
    then patchPortalPkg wlrDesktops pkgs pkgs.xdg-desktop-portal-wlr
    else pkgs.xdg-desktop-portal-wlr;

  portalConfig = import ./xdg-portal-config.nix { inherit lib; };
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

  home.always = _: {
    xdg.portal = {
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
        wlrPortal
        pkgs.kdePackages.xdg-desktop-portal-kde
        gnomeKeyringPortal
      ];
      config = portalConfig;
    };
  };
}
