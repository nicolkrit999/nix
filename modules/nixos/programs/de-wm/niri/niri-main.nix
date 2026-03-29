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

      # Design constants (fall back to good defaults if host doesn't set them)
      gap = myconfig.constants.niri.gap or 8;
      rounding = myconfig.constants.niri.rounding or 10;
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

          # Remove client-side decorations — required for clean geometry-corner-radius
          # without CSD enabled, niri knows the exact corner radius and draws shadows correctly
          prefer-no-csd = true;

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
            gaps = gap; # From constant (default 8px = one 8px-grid unit)

            always-center-single-column = true;
            center-focused-column = "always";

            preset-column-widths = [
              { proportion = 0.33333; }
              { proportion = 0.5; }
              { proportion = 0.66667; }
            ];
            default-column-width = { proportion = 0.5; };

            # Focus ring: shown only around the FOCUSED window
            # Width=2 matches Hyprland border_size=2 for visual coherence
            focus-ring = {
              enable = true;
              width = 2;
              active.color = colors.active; # base0D: accent blue, clearly signals focus
              inactive.color = colors.inactive; # base03: muted — readable but non-distracting
              urgent.color = colors.urgent; # base08: red — universally signals urgency
            };

            # Border (drawn around ALL windows, active and inactive)
            # Kept disabled — focus-ring alone is enough; border + ring would be redundant
            border.enable = false;

            # Shadow: depth cues beneath windows
            # Values calibrated to match Hyprland's shadow (range=8, offset=0 3, opacity=40%)
            shadow = {
              enable = true;
              softness = 20; # Blur radius in logical px (~CSS box-shadow blur)
              spread = 5; # Expands shadow outward from window edge
              offset = { x = 0; y = 4; }; # Slight downward offset for physical grounding
              color = "${colors.shadow}66"; # base00 @ 40% opacity (was "aa" = 67%)
            };
          };

          # -------------------------------------------------------------------
          # ANIMATIONS
          # -------------------------------------------------------------------
          # Niri supports two types:
          #   spring: physical spring model — feels natural with touchpad gestures
          #   easing: fixed-duration curve — precise control for open/close
          #
          # Design principle (same as Hyprland):
          #   - Open slower than close (200ms vs 150ms)
          #   - Movements use springs (velocity-aware, touchpad-friendly)
          #   - Workspace switch spring: snappy but not jarring (stiffness=800)
          #   - No bounce on most springs (damping-ratio=1.0 = critically damped)
          animations = {
            # Workspace scrolling — spring for touchpad velocity awareness
            workspace-switch.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };

            # Window open: ease-out-expo — fast start, smooth landing (same curve as Hyprland windowsIn)
            window-open.kind.easing = {
              duration-ms = 200;
              curve = "ease-out-expo";
            };

            # Window close: faster than open (same principle as Hyprland windowsOut < windowsIn)
            window-close.kind.easing = {
              duration-ms = 150;
              curve = "ease-out-quad";
            };

            # All movement springs — critically damped, snappy
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

            # Config reload notification — slight bounce (underdamped) is intentional and delightful
            config-notification-open-close.kind.spring = {
              damping-ratio = 0.6;
              stiffness = 1000;
              epsilon = 0.001;
            };
          };

          # -------------------------------------------------------------------
          # WINDOW RULES — rounding for all windows
          # -------------------------------------------------------------------
          # geometry-corner-radius clips the window itself (not just the border/shadow)
          # clip-to-geometry=true is required to actually cut window pixels to the rounded rect
          # Shadows automatically follow the corner radius when prefer-no-csd is set
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

          # -------------------------------------------------------------------
          # LAYER RULES — shadows for waybar (pill-shaped)
          # -------------------------------------------------------------------
          # Niri can shadow layer-shell surfaces (waybar) via layer-rules
          # geometry-corner-radius=100 matches the waybar pill shape (border-radius: 100px in CSS)
          layer-rules = [
            {
              matches = [{ namespace = "waybar"; }];
              shadow = {
                enable = true;
                softness = 20;
                spread = 5;
                offset = { x = 0; y = 4; };
                draw-behind-window = true; # Prevents artifacts at pill ends
                color = "${colors.shadow}66";
              };
              geometry-corner-radius = {
                top-left = 100.0;
                top-right = 100.0;
                bottom-left = 100.0;
                bottom-right = 100.0;
              };
            }
          ];

          overview = {
            zoom = 0.5;
          };

          environment = {
            "NIXOS_OZONE_WL" = "1";
            "DISPLAY" = ":0";
          };

          spawn-at-startup = [
            # CORE SERVICES
            { command = [ "xwayland-satellite" ]; }
            { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
            # DBUS UPDATE
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
