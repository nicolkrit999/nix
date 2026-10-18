{ delib
, lib
, config
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
in
delib.module {
  name = "krit.specializations.entertainment";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    specialisation.entertainment.configuration = {
      system.nixos.tags = [ "entertainment" ];

      myconfig = {
        programs = {
          kde.enable = lib.mkForce true;
          hyprland.enable = lib.mkForce false;
          niri.enable = lib.mkForce false;
          gnome.enable = lib.mkForce false;
          cosmic.enable = lib.mkForce false;
          mango.enable = lib.mkForce false;
        };
      };
      services.xserver.desktopManager.xfce.enable = lib.mkForce false;

      environment.etc."xdg/autostart/entertainment-apps.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Entertainment Apps
        Exec=${pkgs.writeShellScript "entertainment-start" ''
          sleep 5
          ${pkgs.brave}/bin/brave &
          ${pkgs.brave}/bin/brave --app="https://www.youtube.com" &
          ${pkgs.brave}/bin/brave --app="https://music.apple.com/ch/home?l=en" &
          ${pkgs.jellyfin-desktop}/bin/jellyfin-desktop &
        ''}
      '';

      home-manager.users.${myUserName} =
        _:
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
