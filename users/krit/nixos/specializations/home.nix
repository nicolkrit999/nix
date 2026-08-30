{ delib
, lib
, pkgs
, ...
}:
let
  asus = {
    make = "ASUSTek COMPUTER INC";
    model = "PG32UCDP";
    serial = "SALMQS185801";
  };
  lg = {
    make = "LG Electronics";
    model = "27GN950";
    serial = "202NTWGFH113";
  };

  hyprDesc = m: "desc:${m.make} ${m.model} ${m.serial}";

  niriKey = m: "${m.make} ${m.model} ${m.serial}";

  resolveMonitorBySerial = pkgs.writeShellScript "resolve-monitor-by-serial" ''
    set -euo pipefail
    serial="$1"
    if command -v niri >/dev/null 2>&1 && niri msg -j outputs >/dev/null 2>&1; then
      niri msg -j outputs \
        | ${pkgs.jq}/bin/jq -r --arg s "$serial" \
            'to_entries[] | select(.value.serial == $s) | .key' \
        | head -n1
    elif command -v hyprctl >/dev/null 2>&1 && hyprctl monitors -j >/dev/null 2>&1; then
      hyprctl monitors -j \
        | ${pkgs.jq}/bin/jq -r --arg s "$serial" \
            '.[] | select(.serial == $s) | .name' \
        | head -n1
    fi
  '';

  monitorBySerial = m: "$(${resolveMonitorBySerial} ${m.serial})";
in
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

      myconfig.programs.mango.enable = lib.mkForce false;

      myconfig.constants.wallpapers = lib.mkForce [
        {
          targetMonitor = "eDP-1";
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
          wallpaperSHA256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";
        }
        {
          targetMonitor = monitorBySerial lg;
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/switch_swirl.jpg";
          wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
        }
        {
          targetMonitor = monitorBySerial asus;
          wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/1%20rain_world.png";
          wallpaperSHA256 = "0lmjfz4zng97xzbcnxwx9aqciznxcdhj5n3dnifj7jp40xm2s7qk";
        }
      ];

      myconfig.programs.hyprland.monitors = lib.mkForce [
        { output = "eDP-1"; mode = "3200x2000@120"; position = "4000x560"; scale = 1.6; }
        { output = hyprDesc lg; mode = "3840x2160@144"; position = "0x0"; scale = 1.5; transform = 1; bitdepth = 10; }
        { output = hyprDesc asus; mode = "3840x2160@240"; position = "1440x560"; scale = 1.5; bitdepth = 10; }
      ];

      myconfig.programs.hyprland.monitorWorkspaces = lib.mkForce [
        { workspace = "1"; monitor = hyprDesc asus; }
        { workspace = "2"; monitor = hyprDesc asus; }
        { workspace = "3"; monitor = hyprDesc asus; }
        { workspace = "4"; monitor = hyprDesc asus; }
        { workspace = "5"; monitor = hyprDesc asus; }
        { workspace = "6"; monitor = hyprDesc lg; }
        { workspace = "7"; monitor = hyprDesc lg; }
        { workspace = "8"; monitor = hyprDesc lg; }
        { workspace = "9"; monitor = hyprDesc lg; }
        { workspace = "10"; monitor = hyprDesc lg; }
      ];

      myconfig.programs.mango.monitors = lib.mkForce [
        "name:^eDP-1$,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.6"
        "name:^DP-1$,width:3840,height:2160,refresh:144,x:0,y:0,scale:1.5,rr:1"
        "name:^DP-2$,width:3840,height:2160,refresh:240,x:1440,y:560,scale:1.5"
      ];

      myconfig.programs.mango.monitorLayouts = lib.mkForce {
        "eDP-1" = "scroller";
        "DP-1" = "vertical_tile";
        "DP-2" = "center_tile";
      };

      myconfig.programs.niri.outputs = lib.mkForce {
        "eDP-1" = {
          mode = {
            width = 3200;
            height = 2000;
            refresh = 120.0;
          };
        };
        "${niriKey lg}" = {
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
        "${niriKey asus}" = {
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
      };
    };
  };
}
