{
  delib,
  lib,
  pkgs,
  config,
  ...
}:
let
  myUserName = "krit";
in
delib.host {
  name = "nixos-desktop";

  nixos = {
    nixpkgs.config.allowUnfree = true;
    specialisation.entertainment.configuration = {
      system.nixos.tags = [ "entertainment" ];

      # 1. Force KDE and disable ALL other Desktop Environments
      myconfig.programs.kde.enable = lib.mkForce true;
      myconfig.programs.hyprland.enable = lib.mkForce false;
      myconfig.programs.niri.enable = lib.mkForce false;
      myconfig.programs.gnome.enable = lib.mkForce false;
      myconfig.programs.cosmic.enable = lib.mkForce false;
      services.xserver.desktopManager.xfce.enable = lib.mkForce false;

      # 2. Autostart script to launch entertainment-focused apps at login
      environment.etc."xdg/autostart/entertainment-apps.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Entertainment Apps
        Exec=${pkgs.writeShellScript "entertainment-start" ''
          sleep 5
          # Launch Brave (Browser)
          ${pkgs.brave}/bin/brave &

          # Launch YouTube PWA
          ${pkgs.brave}/bin/brave --app="https://www.youtube.com" --password-store=gnome &

          # Launch Apple Music PWA
          ${pkgs.brave}/bin/brave --app="https://music.apple.com/ch/home?l=en" --password-store=gnome &

          # Launch Jellyfin
          ${pkgs.jellyfin-desktop}/bin/jellyfin-desktop &
        ''}
      '';

      home-manager.users.${myUserName} =
        { ... }:
        {
          # Force an empty session to avoid relaunching default apps
          programs.plasma.configFile."ksmserverrc"."General"."loginMode" = "emptySession";

          home.packages = with pkgs; [
            jellyfin-desktop
            brave
          ];
        };
    };
  };
}
