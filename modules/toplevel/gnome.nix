{ delib
, pkgs
, lib
, ...
}:
delib.module {
  # TODO: probably can be renamed to "programs.gnome" so that it's not enabled at all if the user does not want it
  name = "gnome";
  options.gnome = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
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

      # 4. 🔧 CONFLICT RESOLUTION (SSH Askpass)
      # Depending on the primary de (gnome vs kde) then use ksshaskpass (kde) or seahorse (gnome).
      # Hyprland does not provide one. If the main is hyprland then choose either one based on user preference.
      programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

      services.gnome.rygel.enable = false;

    };
}
