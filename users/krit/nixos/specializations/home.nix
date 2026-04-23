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

      # Full home monitor setup: internal display + two external monitors.
      # Use this specialization when docked at home with DP-1 and DP-2 connected.
      myconfig.programs.hyprland.monitors = lib.mkForce [
        "eDP-1,3200x2000@120,0x0,1.6"
        "DP-1,3840x2160@240,1440x560,1.5,bitdepth,10"
        "DP-2,3840x2160@144,0x0,1.5,transform,1,bitdepth,10"
      ];

      myconfig.programs.hyprland.monitorWorkspaces = lib.mkForce [
        "1, monitor:DP-1"
        "2, monitor:DP-1"
        "3, monitor:DP-1"
        "4, monitor:DP-1"
        "5, monitor:DP-1"
        "6, monitor:DP-2"
        "7, monitor:DP-2"
        "8, monitor:DP-2"
        "9, monitor:DP-2"
        "10, monitor:DP-2"
      ];

      myconfig.programs.mango.monitors = lib.mkForce [
        "name:^eDP-1$,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.6"
        "name:^DP-1$,width:3840,height:2160,refresh:240,x:1440,y:560,scale:1.5"
        "name:^DP-2$,width:3840,height:2160,refresh:144,x:0,y:0,scale:1.5,rr:1"
      ];

      myconfig.programs.mango.monitorLayouts = lib.mkForce {
        "eDP-1" = "scroller";
        "DP-1" = "scroller";
        "DP-2" = "vertical_scroller";
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
