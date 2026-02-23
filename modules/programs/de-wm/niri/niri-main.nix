{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "programs.niri";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      outputs = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Native Niri outputs configuration. If empty, Niri auto-configures connected monitors.";
      };
      execOnce = listOfOption str [ ];
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      # Styling helper functions
      c = config.lib.stylix.colors.withHashtag;
      colors = {
        active = c.base0D;
        inactive = c.base03;
        urgent = c.base08;
        shadow = c.base00;
      };
    in
    {
      home.packages = with pkgs; [
        xwayland-satellite # X11 Support
        swww # Wallpaper
        grimblast # Screenshot tool
        slurp # Region selector for screenshots
        libnotify # Notifications
        hyprpicker # Color Picker
        wl-clipboard # Clipboard
        pavucontrol # GUI Volume Control
        brightnessctl # Laptop Brightness Keys (Fn+F keys)
        playerctl # Media Keys (Play/Pause)
        imv # Image Viewer
        mpv # Video Player
      ];

      programs.niri = {
        settings = {
          hotkey-overlay.skip-at-startup = true;

          input = {
            keyboard.xkb = {
              layout = myconfig.constants.keyboardLayout;
              variant = myconfig.constants.keyboardVariant;
              options = "grp:ctrl_alt_toggle";
            };
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
            mouse.accel-profile = "flat";
          };

          outputs = cfg.outputs;

          layout = {
            gaps = 12;
            center-focused-column = "always";
            preset-column-widths = [
              { proportion = 0.33333; }
              { proportion = 0.5; }
              { proportion = 0.66667; }
            ];
            default-column-width = {
              proportion = 0.5;
            };
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

          overview = {
            zoom = 0.5;
          };

          environment = {
            "NIXOS_OZONE_WL" = "1";
            "DISPLAY" = ":0";
          };

          spawn-at-startup = [
            # 1. Kill stuck portals from other sessions (Fixes slow load)
            { command = [ "/bin/sh" "-c" "$HOME/.local/bin/init-gnome-keyring.sh" ]; }
            # 2. CORE SERVICES
            { command = [ "xwayland-satellite" ]; }
            { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
            # 3. DBUS UPDATE
            { command = [ "dbus-update-activation-environment" "--systemd" "--all" ]; }
            # 4. WALLPAPER
            { command = [ "swww-daemon" ]; }
          ]
          ++ (map
            (w:
              let
                imgPath = pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; };
                targetArgs = if w.targetMonitor == "*" then [ ] else [ "-o" w.targetMonitor ];
              in
              {
                command = [ "swww" "img" ] ++ targetArgs ++ [ "${imgPath}" ];
              }
            )
            myconfig.constants.wallpapers)
          ++ (map
            (cmd: {
              command = [ "bash" "-c" cmd ];
            })
            cfg.execOnce);
        };
      };
    };
}
