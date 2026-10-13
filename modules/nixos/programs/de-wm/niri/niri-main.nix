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
    , parent
    , myconfig
    , ...
    }:
    let
      hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success;
      c =
        if hasStylixPalette then config.lib.stylix.colors.withHashtag
        else {
          base00 = "#1e1e2e";
          base03 = "#585b70";
          base08 = "#f38ba8";
          base0D = "#89b4fa";
        };
      colors = {
        active = c.base0D; # accent blue, same as the Hyprland active border
        inactive = c.base03; # muted, readable but non-distracting
        urgent = c.base08; # red
        shadow = c.base00; # neutral shadow base
      };

      # niri's environment/screenshot-path never shell-expand $HOME
      screenshotsDir = myconfig.constants.screenshotsAbs;
      gap = myconfig.constants.niri.gap;
      rounding = myconfig.constants.niri.rounding;

      noctaliaActiveOnNiri =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnNiri or false);
      skwdWallActive = parent.skwdWall.enable or false;

      wp = import ../wallpaperd/mk-wallpaperd.nix { inherit lib pkgs; } {
        wm = "niri";
        wallpapers = myconfig.constants.wallpapers;
      };

      wallpaperSpawns = lib.optionals (!noctaliaActiveOnNiri && !skwdWallActive)
        (map (c: { command = c; }) wp.startupArgv);
    in
    {
      home.packages = with pkgs; [
        awww
        brightnessctl
        hyprpicker
        imv
        libnotify
        mpv
        mpvpaper
        pavucontrol
        playerctl
        wev
        wl-clipboard
        xwayland-satellite # niri starts it itself and needs it on PATH
      ];

      programs.niri = {
        settings = {
          hotkey-overlay.skip-at-startup = true;

          prefer-no-csd = true;

          input = {
            keyboard.xkb = {
              layout = myconfig.constants.keyboardLayout;
              variant = myconfig.constants.keyboardVariant;
              options = myconfig.constants.keyboardOptions;
            };
            touchpad = {
              tap = true;
              natural-scroll = false;
            };
            mouse.accel-profile = "flat";
          };

          inherit (cfg) outputs;

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
              active.color = colors.active;
              inactive.color = colors.inactive;
              urgent.color = colors.urgent;
            };
            border.enable = false;

            shadow = {
              enable = true;
              softness = 20;
              spread = 5;
              offset = { x = 0; y = 4; };
              color = "${colors.shadow}66"; # 40% opacity
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
            "XDG_SCREENSHOTS_DIR" = screenshotsDir;
          };

          screenshot-path = "${screenshotsDir}/Screenshot_%Y-%m-%d_%H-%M-%S.png";

          spawn-at-startup = [
            { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
            {
              command = [
                "dbus-update-activation-environment"
                "--systemd"
                "--all"
              ];
            }
          ]
          ++ wallpaperSpawns
          ++ (map
            (cmd: { command = [ "bash" "-c" cmd ]; })
            cfg.execOnce);
        };
      };
    };
}
