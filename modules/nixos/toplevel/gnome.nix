{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.gnome";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.desktopManager.gnome.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour # Onboarding
      epiphany # Default browser
      geary # Email
      totem # Video player
      yelp # Help viewer
      nautilus # File manager
      papers # document viewer
      gnome-connections # Remote desktop management
      gnome-characters # Character map
      gnome-console # Terminal
      gnome-color-manager # Graphical utilities for managing color profiles
      loupe # image viewer
      decibels # audio file previewer
      showtime # video player
      gnome-music # Music player
      gnome-maps # Maps application
      gnome-clocks # Clocks application
      baobab # Disk usage analyzer
      simple-scan # Document scanner
      gnome-software # Software center
      seahorse # Password and key manager
      gnome-weather # Weather application
      gnome-text-editor # Text editor
      gnome-system-monitor # System monitor
      gnome-font-viewer # Font viewer

    ];

    # SSH Askpass is set globally in common-configuration-nixos.nix (seahorse)
    # since GNOME Keyring is enforced system-wide regardless of DE.

    services.gnome.rygel.enable = false;

  };
}
