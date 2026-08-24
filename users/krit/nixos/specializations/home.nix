{ delib
, lib
, ...
}:
delib.module {
  name = "krit.specializations.home";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    specialisation.home.configuration = {
      system.nixos.tags = [ "home" ];

      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      myconfig.constants.wallpapers = lib.mkForce [
        {
          targetMonitor = "eDP-1";
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
          wallpaperSHA256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";

          videoURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/various-videos-gifs/landscape/girl-desk-working.MP4";
          videoSHA256 = "0q6asqgcq0n5va8210v5jhqlqw7nzw1i5wdr8cn8bccj316fnfgy";
        }
        {
          targetMonitor = "DP-1";
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
          wallpaperSHA256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";

          videoURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/various-videos-gifs/landscape/girl-desk-working.MP4";
          videoSHA256 = "0q6asqgcq0n5va8210v5jhqlqw7nzw1i5wdr8cn8bccj316fnfgy";
        }
        {
          targetMonitor = "DP-2";
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/switch_swirl.jpg";
          wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";

          videoURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/various-videos-gifs/portrait/purple-car.mp4";
          videoSHA256 = "0g1gxwhwbg7brglwxg069ivacs33p7hmy4mn7gkz9zh4xlwrmag4";
        }
      ];

      myconfig.programs.hyprland.monitors = lib.mkForce [
        { output = "eDP-1"; mode = "3200x2000@120"; position = "0x0"; scale = 1.6; }
        { output = "DP-1"; mode = "3840x2160@240"; position = "1440x560"; scale = 1.5; bitdepth = 10; }
        { output = "DP-2"; mode = "3840x2160@144"; position = "0x0"; scale = 1.5; transform = 1; bitdepth = 10; }
      ];

      myconfig.programs.hyprland.monitorWorkspaces = lib.mkForce [
        { workspace = "1"; monitor = "DP-1"; }
        { workspace = "2"; monitor = "DP-1"; }
        { workspace = "3"; monitor = "DP-1"; }
        { workspace = "4"; monitor = "DP-1"; }
        { workspace = "5"; monitor = "DP-1"; }
        { workspace = "6"; monitor = "DP-2"; }
        { workspace = "7"; monitor = "DP-2"; }
        { workspace = "8"; monitor = "DP-2"; }
        { workspace = "9"; monitor = "DP-2"; }
        { workspace = "10"; monitor = "DP-2"; }
      ];

      myconfig.programs.mango.monitors = lib.mkForce [
        "name:^eDP-1$,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.6"
        "name:^DP-1$,width:3840,height:2160,refresh:240,x:1440,y:560,scale:1.5"
        "name:^DP-2$,width:3840,height:2160,refresh:144,x:0,y:0,scale:1.5,rr:1"
      ];

      myconfig.programs.mango.monitorLayouts = lib.mkForce {
        "eDP-1" = "scroller";
        "DP-1" = "center_tile";
        "DP-2" = "vertical_tile";
      };

      myconfig.programs.niri.outputs = lib.mkForce {
        "eDP-1" = {
          mode = {
            width = 3200;
            height = 2000;
            refresh = 120.0;
          };
        };
        "DP-1" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 240.0;
          };
          scale = 1.5;
          position = {
            x = 1440;
            y = 560;
          };
        };
        "DP-2" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 144.0;
          };
          scale = 1.5;
          position = {
            x = 0;
            y = 0;
          };
          transform = {
            rotation = 90;
            flipped = false;
          };
        };
      };
    };
  };
}
