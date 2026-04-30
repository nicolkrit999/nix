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
  # selection is still driven by the `xdg.portal.config` blocks below.
  #
  # Add a new WM here when needed.
  permissiveDesktops = "GNOME;KDE;COSMIC;Hyprland;niri;mango;sway;wlroots;X-Cinnamon;LXQt;XFCE;MATE";

  # Inline patcher (same logic as the NixOS overlay below). Used at the
  # home-manager level where we don't apply an overlay because home-manager
  # has `useGlobalPkgs = false` — its `pkgs` is independent.
  patchPortalPkg = pkgsArg: pkg: pkg.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      for f in $out/share/xdg-desktop-portal/portals/*.portal; do
        if grep -q '^UseIn=' "$f"; then
          ${pkgsArg.gnused}/bin/sed -i 's|^UseIn=.*|UseIn=${permissiveDesktops}|' "$f"
        fi
      done
    '';
  });

  # Per-DE backend selection. Same routing applied at both NixOS and
  # home-manager level so the active config matches regardless of which
  # `NIX_XDG_DESKTOP_PORTAL_DIR` the portal frontend ends up reading.
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

  # NixOS level: overlay patches packages globally so any other NixOS
  # module pulling these in (flatpak, plasma6, etc.) sees the patched
  # version. Avoids systemd.packages collision on duplicate
  # xdg-desktop-portal-gtk.service from inline wrapping.
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

  # Home-manager level: home-manager's xdg.portal module gets auto-enabled
  # by HM-side WM modules (e.g. wayland.windowManager.hyprland) and sets
  # `NIX_XDG_DESKTOP_PORTAL_DIR=${profileDirectory}/share/xdg-desktop-portal/portals`,
  # OVERRIDING the NixOS env var. The portal frontend then only reads
  # manifests from the per-user profile — and gtk/kde manifests are
  # missing there unless we register them via home-manager too. Inline
  # `overrideAttrs` here is safe because home-manager's pkgs has no other
  # references to these packages → no service file collision in
  # ~/.config/systemd/user.
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
