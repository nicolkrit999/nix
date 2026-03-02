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
# FIXME: Desktop 1 to 3 created but apps are still opening in the first one
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

      home-manager.users.${myUserName} =
        { pkgs, ... }:
        {

          # Ensure KDE creates at least 3 Virtual Desktops (Workspaces)
          programs.plasma.kwin.virtualDesktops = {
            number = 3;
            rows = 1;
          };

          # Declarative KWin rules to force the PWAs to specific workspaces
          programs.plasma.window-rules = [
            {
              description = "Force YouTube PWA to Workspace 2";
              match.window-class = {
                value = "brave-www.youtube.com__-Default";
                type = "substring";
              };
              apply.desktops = {
                value = "Desktop 2";
                apply = "force";
              };
            }
            {
              description = "Force Apple Music PWA to Workspace 3";
              match.window-class = {
                value = "brave-music.apple.com__ch_home-Default";
                type = "substring";
              };
              apply.desktops = {
                value = "Desktop 3";
                apply = "force";
              };
            }
          ];

          home.packages = with pkgs; [
            kdePackages.libkscreen
            jellyfin-desktop # Media server
          ];

          # 2. KDE Autostart: Isolate the OLED and enable HDR
          home.file.".config/autostart/media-monitor-setup.desktop".text = ''
            [Desktop Entry]

            Exec=${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-1.enable output.DP-1.hdr.enable output.DP-2.disable output.DP-3.disable output.HDMI-A-1.disable
            X-KDE-autostart-phase=1
          '';

          # 3. KDE Autostart: Launch Apps
          home.file.".config/autostart/media-apps-autostart.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=Media Apps Autostart
            Exec=${pkgs.writeShellScript "media-apps-start" ''
              sleep 3
              # Launch default browser (This will open on the current workspace: Desktop 1)
              ${config.myconfig.constants.browser} &

              # Launch YouTube PWA (KWin rule will intercept and move it to Desktop 2)
              ${pkgs.brave}/bin/brave --app="https://www.youtube.com" --password-store=gnome &

              # Launch Apple Music PWA (KWin rule will intercept and move it to Desktop 3)
              ${pkgs.brave}/bin/brave --app="https://music.apple.com/ch/home?l=en" --password-store=gnome &
            ''}
            X-KDE-autostart-phase=2
          '';
        };
    };
  };
}
