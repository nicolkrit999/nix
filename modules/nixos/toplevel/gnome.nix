{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "programs.gnome";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    services.desktopManager.gnome.enable = true;

    # nixpkgs' GNOME module enables ibus; hide its autostart entry (it pops a Wayland warning outside GNOME).
    home-manager.users.${myconfig.constants.user}.xdg.configFile."autostart/ibus-daemon.desktop" =
      lib.mkIf (config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "ibus") {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=IBus Daemon
          Hidden=true
        '';
      };

    environment.gnome.excludePackages = with pkgs; [
      # Communication and web
      epiphany # Default browser
      geary # Email
      gnome-connections # Remote desktop management

      # Media
      decibels # audio file previewer
      gnome-music # Music player
      loupe # image viewer
      showtime # video player
      totem # Video player

      # Documents and text
      gnome-text-editor # Text editor
      papers # document viewer
      simple-scan # Document scanner
      yelp # Help viewer

      # System and desktop tools
      baobab # Disk usage analyzer
      gnome-characters # Character map
      gnome-clocks # Clocks application
      gnome-color-manager # Graphical utilities for managing color profiles
      gnome-console # Terminal
      gnome-font-viewer # Font viewer
      gnome-maps # Maps application
      gnome-software # Software center
      gnome-system-monitor # System monitor
      gnome-tour # Onboarding
      gnome-weather # Weather application
      nautilus # File manager
    ];

    services.gnome.rygel.enable = false;

  };
}
