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
      outputs = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Native Niri outputs configuration. If empty, Niri auto-configures connected monitors.";
      };
      execOnce = listOfOption str [ ];
      extraBinds = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
        description = "Extra keybindings as attrset. Keys are bind strings (e.g. 'Mod+Y'), values are action attrsets.";
        example = ''
          {
            "Mod+Y".action.spawn = [ "chromium" ];
            "XF86Tools".action.focus-workspace-previous = [];
          }
        '';
      };
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
        active = c.base0D; # Accent blue — same as Hyprland active border
        inactive = c.base03; # Muted mid-tone — clearly distinguishable from active
        urgent = c.base08; # Red — universally signals urgency
        shadow = c.base00; # Darkest shade — neutral shadow base
      };

      gap = myconfig.constants.niri.gap or 8;
      rounding = myconfig.constants.niri.rounding or 10;
    in
    {
      home.packages = with pkgs; [
        xwayland-satellite # X11 Support
        swww # Wallpaper
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

          prefer-no-csd = true;

          input = {
            keyboard.xkb = {
              layout = myconfig.constants.keyboardLayout;
              variant = myconfig.constants.keyboardVariant;
              options = "grp:ctrl_alt_toggle";
            };
            touchpad = {
              tap = true;
              natural-scroll = false;
            };
            mouse.accel-profile = "flat";
          };

          outputs = cfg.outputs;

          layout = {
            gaps = gap;

            always-center-single-column = true;
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
              active.color = colors.active; # base0D: accent blue, clearly signals focus
              inactive.color = colors.inactive; # base03: muted — readable but non-distracting
              urgent.color = colors.urgent; # base08: red — universally signals urgency
            };
            border.enable = false;

            shadow = {
              enable = true;
              softness = 20; # Blur radius in logical px
              spread = 5; # Expands shadow outward from window edge
              offset = { x = 0; y = 4; }; # Slight downward offset for physical grounding
              color = "${colors.shadow}66"; # base00 @ 40% opacity
            };
          };

          animations = {
            workspace-switch.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };

            window-open.kind.easing = {
              duration-ms = 200;
              curve = "ease-out-expo";
            };

            window-close.kind.easing = {
              duration-ms = 150;
              curve = "ease-out-quad";
            };

            horizontal-view-movement.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };
            window-movement.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };
            window-resize.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };

            config-notification-open-close.kind.spring = {
              damping-ratio = 0.6;
              stiffness = 1000;
              epsilon = 0.001;
            };
          };

          window-rules = [
            {
              geometry-corner-radius = {
                top-left = rounding * 1.0;
                top-right = rounding * 1.0;
                bottom-left = rounding * 1.0;
                bottom-right = rounding * 1.0;
              };
              clip-to-geometry = true;
            }
          ];

          overview = {
            zoom = 0.5;
          };

          environment = {
            "NIXOS_OZONE_WL" = "1";
            "DISPLAY" = ":1";
            "XDG_SCREENSHOTS_DIR" = myconfig.constants.screenshots;
          };

          spawn-at-startup = [
            { command = [ "xwayland-satellite" ":1" ]; }
            { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
            {
              command = [
                "dbus-update-activation-environment"
                "--systemd"
                "--all"
              ];
            }
            # WALLPAPER
            { command = [ "swww-daemon" ]; }
          ]
          ++ (map
            (w:
              let
                imgPath = pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; };
                targetArgs = if w.targetMonitor == "*" then [ ] else [ "-o" w.targetMonitor ];
              in
              { command = [ "swww" "img" ] ++ targetArgs ++ [ "${imgPath}" ]; }
            )
            myconfig.constants.wallpapers)
          ++ (map
            (cmd: { command = [ "bash" "-c" cmd ]; })
            cfg.execOnce);
        };
      };
    };
}
