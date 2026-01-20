{ pkgs, lib, config, vars, ... }:
let
  # Styling helper functions
  c = config.lib.stylix.colors.withHashtag;
  colors = {
    active = c.base0D;
    inactive = c.base03;
    urgent = c.base08;
    shadow = c.base00;
  };

  # ---------------------------------------------------------------------------
  # 🖥️ MONITOR PARSING
  # ---------------------------------------------------------------------------

  enabledMonitors = lib.concatMap (m:
    let
      parts = lib.splitString "," m;
      name = builtins.elemAt parts 0;
      configStr =
        if builtins.length parts > 1 then builtins.elemAt parts 1 else "";
    in if (configStr == "disable" || configStr == "disabled") then
      [ ]
    else
      [ name ]) vars.monitors;

  # 2. Get a list of DISABLED monitors (for turning them off)
  disabledMonitors = lib.concatMap (m:
    let
      parts = lib.splitString "," m;
      name = builtins.elemAt parts 0;
      configStr =
        if builtins.length parts > 1 then builtins.elemAt parts 1 else "";
    in if (configStr == "disable" || configStr == "disabled") then
      [ name ]
    else
      [ ]) vars.monitors;

  # 3. Generate Settings Block for Niri (Resolution, Scale, Position)
  monitorSettings = builtins.listToAttrs (lib.concatMap (m:
    let
      parts = lib.splitString "," m;
      len = builtins.length parts;
    in if len < 2 then
      [ ]
    else
      let
        name = builtins.elemAt parts 0;
        configStr = builtins.elemAt parts 1;
      in if (configStr == "disable" || configStr == "disabled") then
        [ ]
      else if len < 4 then
        [ ]
      else
        let
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
        in [{
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
        }]) vars.monitors);

  # ---------------------------------------------------------------------------
  # 🎨 WALLPAPER LOGIC
  # ---------------------------------------------------------------------------

  # 1. Fetch ALL wallpapers defined in variables.nix
  fetchedWallpapers = map (w:
    pkgs.fetchurl {
      url = w.wallpaperURL;
      sha256 = w.wallpaperSHA256;
    }) vars.wallpapers;

  # 2. Generate 'swww' commands by zipping Monitors with Wallpapers
  wallpaperCommands = lib.imap0 (i: mon:
    let
      # Logic: Use wallpaper at index 'i'. 
      # If we run out of wallpapers, fallback to the FIRST one (index 0).
      wp = if i < builtins.length fetchedWallpapers then
        builtins.elemAt fetchedWallpapers i
      else
        builtins.head fetchedWallpapers;
    in { command = [ "swww" "img" "-o" mon "${wp}" ]; }) enabledMonitors;

in {
  config = lib.mkIf (vars.niri or false) {

    home.packages = with pkgs; [
      xwayland-satellite # X11 Support
      swww # Wallpaper
      grimblast # Screenshot tool
      slurp # Region selector for screenshots
      libnotify # Notifications
      hyprpicker # Color Picker
      wofi # App Launcher
      wl-clipboard # Clipboard
      pavucontrol # GUI Volume Control
      brightnessctl # Laptop Brightness Keys (Fn+F keys)
      playerctl # Media Keys (Play/Pause)
      imv # Image Viewer
      mpv # Video Player
    ];

    programs.niri = {
      settings = {
        hotkey-overlay.skip-at-startup =
          true; # Disable keymap overlay at startup
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
          center-focused-column = "always";
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

        overview = { zoom = 0.5; };

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
        ] ++ wallpaperCommands

          # Disable unused monitors
          ++ (map (name: { command = [ "niri" "msg" "output" name "off" ]; })
            disabledMonitors)

          # User defined extra execs
          ++ (map (cmd: { command = [ "bash" "-c" cmd ]; })
            (vars.niri_Exec-Once or [ ]));
      };
    };
  };
}
