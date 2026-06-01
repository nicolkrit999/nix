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
