{ lib }:
let
  secretPortal = { "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ]; };

  # "none" blocks xdp's UseIn fallback from picking another desktop's backend
  noRoutes = names: lib.genAttrs (map (n: "org.freedesktop.impl.portal.${n}") names) (_: [ "none" ]);
  sessionOnlyNames = [ "Background" "GlobalShortcuts" "RemoteDesktop" "Clipboard" "InputCapture" "Usb" ];

  # keys must be lowercase: xdp lowercases XDG_CURRENT_DESKTOP
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
    # mkForce: mango flake sets the same Secret value
    mango = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = lib.mkForce [ "gnome-keyring" ];
      # mkForce: see Documentation/usage/gotchas/xdg-desktop-portal-nixos.md
      "org.freedesktop.impl.portal.ScreenCast" = lib.mkForce [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = lib.mkForce [ "wlr" ];
      "org.freedesktop.impl.portal.Inhibit" = lib.mkForce [ "none" ];
    } // noRoutes sessionOnlyNames;
    common = { default = [ "gtk" ]; } // noRoutes (sessionOnlyNames ++ [ "ScreenCast" ]) // secretPortal;
  };
in
portalConfig
