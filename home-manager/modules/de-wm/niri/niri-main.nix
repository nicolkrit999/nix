{ pkgs, lib, config, vars, ... }:
let
  c = config.lib.stylix.colors.withHashtag;

  colors = {
    active = c.base0D;
    inactive = c.base03;
    urgent = c.base08;
    shadow = c.base00;
  };

  activeMonitors = builtins.filter
    (m: let parts = lib.splitString "," m; in (builtins.length parts) > 2)
    vars.monitors;

  monitorSettings = builtins.listToAttrs (map (m:
    let
      parts = lib.splitString "," m;
      name = builtins.elemAt parts 0;
      modeStr = builtins.elemAt parts 1;
      posStr = builtins.elemAt parts 2;
      scale = builtins.fromJSON (builtins.elemAt parts 3);

      posParts = lib.splitString "x" posStr;
      posX = lib.toInt (builtins.elemAt posParts 0);
      posY = lib.toInt (builtins.elemAt posParts 1);

      modeSplit = lib.splitString "@" modeStr;
      resSplit = lib.splitString "x" (builtins.head modeSplit);
      width = lib.toInt (builtins.head resSplit);
      height = lib.toInt (builtins.elemAt resSplit 1);
      refresh = if (builtins.length modeSplit > 1) then
        (builtins.fromJSON (builtins.elemAt modeSplit 1)) + 0.0
      else
        60.0;

      isRotated = (builtins.length parts > 4)
        && (builtins.elemAt parts 4 == "transform");

      rotationVal = if isRotated then 90 else 0;
    in {
      name = name;
      value = {
        mode = {
          width = width;
          height = height;
          refresh = refresh;
        };
        scale = scale;
        position = {
          x = posX;
          y = posY;
        };
        transform = {
          rotation = rotationVal;
          flipped = false;
        };
      };
    }) activeMonitors);

  wallpaper = builtins.head vars.wallpapers;
  wallpaperFile = pkgs.fetchurl {
    url = wallpaper.wallpaperURL;
    sha256 = wallpaper.wallpaperSHA256;
  };

in {
  config = lib.mkIf (vars.niri or false) {

    home.packages = with pkgs; [
      xwayland-satellite # X11 Support
      swww # Wallpaper
      libnotify # Notifications
      mako # Notification Daemon
      wofi # App Launcher
      wl-clipboard # Clipboard
    ];

    programs.niri = {
      settings = {
        # ⌨️ Inputs (From Variables)
        input = {
          keyboard.xkb = {
            layout = vars.keyboardLayout;
            variant = vars.keyboardVariant;
            options = "grp:ctrl_alt_toggle";
          };
          touchpad = {
            tap = true;
            natural-scroll = true;
          };
          mouse.accel-profile = "flat";
        };

        outputs = monitorSettings;

        layout = {
          gaps = 12;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          default-column-width = { proportion = 0.5; };

          focus-ring = {
            enable = true;
            width = 2;
            active.color = colors.active;
            inactive.color = colors.inactive;
          };
          border.enable = false;
          shadow = {
            enable = true;
            color = "${colors.shadow}aa";
          };
        };

        environment = {
          "NIXOS_OZONE_WL" = "1";
          "DISPLAY" = ":0";
        };

        spawn-at-startup = [
          { command = [ "xwayland-satellite" ]; }
          {
            command = [
              "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
            ];
          }
          {
            command = [
              "dbus-update-activation-environment"
              "--systemd"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
            ];
          }
          { command = [ "swww-daemon" ]; }
          { command = [ "swww" "img" "${wallpaperFile}" ]; }
          { command = [ "mako" ]; }
        ];
      };
    };
  };
}
