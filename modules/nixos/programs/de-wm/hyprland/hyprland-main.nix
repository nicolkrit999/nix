{ delib
, config
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.hyprland";
  options =
    with delib;
    moduleOptions {
      monitors = listOfOption attrs [
        { output = ""; mode = "preferred"; position = "auto"; scale = "auto"; }
      ];
      execOnce = listOfOption str [ ];
      # Shell autostart only (caelestia/noctalia): specs mkForce execOnce, never this list.
      shellExecOnce = listOfOption str [ ];
      monitorWorkspaces = listOfOption attrs [ ];
      windowRules = listOfOption attrs [ ];
      extraBinds = listOfOption attrs [ ];
      noHardwareCursors = boolOption false;
    };

  myconfig.ifEnabled = {
    stylix.targets.hyprland.enable = false;
  };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      inherit (lib.generators) mkLuaInline;
      term = myconfig.constants.terminal.name;

      caelestiaActiveOnHyprland = parent.caelestia.enable && parent.caelestia.enableOnHyprland;
      noctaliaActiveOnHyprland = parent.noctalia.enable && parent.noctalia.enableOnHyprland;
      wallpaperOwnedByShell = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;
      skwdWallActive = parent.skwdWall.enable or false;
      vicinaeEnabled = parent.vicinae.enable or true;

      hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success;
      colors =
        if hasStylixPalette then config.lib.stylix.colors
        else {
          base00 = "1e1e2e";
          base02 = "45475a";
          base03 = "585b70";
          base05 = "cdd6f4";
          base0C = "94e2d5";
          base0D = "89b4fa";
        };

      gdkScale =
        let
          rawScale = if cfg.monitors == [ ] then 1 else (builtins.head cfg.monitors).scale or 1;
          scale =
            if builtins.isString rawScale then
              (if builtins.match "[0-9]+(\\.[0-9]+)?" rawScale != null then builtins.fromJSON rawScale else 1)
            else rawScale;
        in
        if scale > 1 then "2" else "1";

      wp = import ../wallpaperd/mk-wallpaperd.nix { inherit lib pkgs; } {
        wm = "hyprland";
        wallpapers = myconfig.constants.wallpapers;
      };

      wallpaperCmds = lib.optionals (!wallpaperOwnedByShell && !skwdWallActive) wp.startupCmds;

      execOnceItems = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ] ++ wallpaperCmds ++ cfg.execOnce ++ cfg.shellExecOnce;

      execOnceFn = mkLuaInline (
        "function()\n"
        + lib.concatMapStrings (cmd: "  hl.exec_cmd(${builtins.toJSON cmd})\n") execOnceItems
        + "end"
      );

      staticWindowRules = [
        { match.class = "(mpv)|(imv)"; float = true; }
        {
          match.class = "^(showmethekey-gtk)$";
          float = true;
          border_size = 0;
          no_focus = true;
          pin = true;
          no_initial_focus = true;
          move = "990 60";
          size = "900 170";
        }

        {
          match.class = "^(ueberzugpp_layer)$";
          float = true;
          no_anim = true;
          no_shadow = true;
          no_blur = true;
          no_initial_focus = true;
        }

        {
          match.class = "^(org.kde.gwenview)$";
          float = true;
          center = true;
          size = "80% 80%";
        }

        {
          match.title = "^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$";
          float = true;
          center = true;
          size = "50% 50%";
          pin = true;
        }

        {
          match.class = "^(xdg-desktop-portal-(kde|gtk))$";
          float = true;
          center = true;
          size = "50% 50%";
          pin = true;
        }

        { match.class = ".*"; suppress_event = "maximize"; }
        {
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }

        {
          match.class = "^(xwaylandvideobridge)$";
          opacity = "0.0 override";
          no_anim = true;
          no_initial_focus = true;
          max_size = "1 1";
          no_blur = true;
          no_focus = true;
        }
      ]
      ++ lib.optional
        (myconfig.constants.hyprland.terminalOpacity < 1.0)
        {
          match.class = "^(${term})$";
          opacity = "${toString myconfig.constants.hyprland.terminalOpacity} override";
        };

      staticWorkspaceRules = [
        { workspace = "f[1]"; gaps_out = 0; gaps_in = 0; }
      ];

      staticBeziers = [
        { _args = [ "easeOutExpo" { type = "bezier"; points = [ [ 0.16 1 ] [ 0.3 1 ] ]; } ]; }
        { _args = [ "easeInOutQuad" { type = "bezier"; points = [ [ 0.45 0 ] [ 0.55 1 ] ]; } ]; }
        { _args = [ "easeOutBack" { type = "bezier"; points = [ [ 0.34 1.56 ] [ 0.64 1 ] ]; } ]; }
      ];

      staticAnimations = [
        { leaf = "windows"; enabled = true; speed = 3; bezier = "easeOutExpo"; }
        { leaf = "windowsIn"; enabled = true; speed = 3; bezier = "easeOutBack"; style = "popin 80%"; }
        { leaf = "windowsOut"; enabled = true; speed = 2; bezier = "easeOutExpo"; style = "popin 80%"; }
        { leaf = "fade"; enabled = true; speed = 2; bezier = "easeOutExpo"; }
        { leaf = "border"; enabled = true; speed = 3; bezier = "easeOutExpo"; }
        { leaf = "workspaces"; enabled = true; speed = 4; bezier = "easeInOutQuad"; style = "slide"; }
      ];

      staticEnv = [
        { _args = [ "NIXOS_OZONE_WL" "1" ]; }
        { _args = [ "MOZ_ENABLE_WAYLAND" "1" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland;xcb" ]; }
        { _args = [ "GDK_BACKEND" "wayland,x11,*" ]; }
        { _args = [ "GDK_SCALE" gdkScale ]; }
        { _args = [ "SDL_VIDEODRIVER" "wayland" ]; }
        { _args = [ "CLUTTER_BACKEND" "wayland" ]; }
        { _args = [ "_JAVA_AWT_WM_NONREPARENTING" "1" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SCREENSHOTS_DIR" myconfig.constants.screenshotsAbs ]; }
      ];

      staticGestures = [
        { fingers = 3; direction = "right"; action = "workspace"; }
        { fingers = 3; direction = "left"; action = "workspace"; }
        { fingers = 3; direction = "up"; action = "fullscreen"; }
        { fingers = 3; direction = "down"; action = "close"; }
      ]
      ++ lib.optional vicinaeEnabled {
        fingers = 4;
        direction = "up";
        action = mkLuaInline ''function() hl.exec_cmd("vicinae toggle") end'';
      }
      ++ [
        { fingers = 4; direction = "down"; action = "special"; workspace_name = "magic"; }
        { fingers = 4; direction = "pinchin"; action = "float"; }
      ];
    in

    {
      catppuccin.hyprland = {
        enable = myconfig.constants.theme.catppuccin;
        flavor = myconfig.constants.theme.catppuccinFlavor;
        accent = myconfig.constants.theme.catppuccinAccent;
      };

      home.packages = with pkgs; [
        awww
        brightnessctl
        grimblast
        hyprpicker
        imv
        kdePackages.gwenview
        mpv
        mpvpaper
        pavucontrol
        playerctl
        showmethekey
        wev
        wl-clipboard
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        systemd = {
          enable = true;
          variables = [ "--all" ];
          extraCommands = [ "systemctl --user start hyprland-session.target" ];
        };

        settings = {
          env = staticEnv;
          monitor = cfg.monitors;
          curve = staticBeziers;
          animation = staticAnimations;
          gesture = staticGestures;
          window_rule = staticWindowRules ++ cfg.windowRules;
          workspace_rule = staticWorkspaceRules ++ cfg.monitorWorkspaces;

          on = {
            _args = [ "hyprland.start" execOnceFn ];
          };

          config = {
            general = {
              gaps_in = myconfig.constants.hyprland.gap;
              gaps_out = myconfig.constants.hyprland.gap * 2;
              border_size = myconfig.constants.hyprland.borderSize;

              "col.active_border" = lib.mkDefault (
                if myconfig.constants.theme.catppuccin then
                  mkLuaInline "colors.accent"
                else
                  "rgb(${colors.base0D})"
              );

              "col.inactive_border" = lib.mkForce "rgba(${colors.base02}66)";

              resize_on_border = true;
              allow_tearing = false;
              layout = "dwindle";
            };

            decoration = {
              rounding = myconfig.constants.hyprland.rounding;
              active_opacity = 1.0;
              inactive_opacity = 1.0;
              shadow = {
                enabled = true;
                range = 8;
                render_power = 3;
                color = lib.mkForce "rgba(00000066)";
                offset = "0 3";
              };
              blur = {
                enabled = true;
                size = 8;
                passes = 2;
              };
            };

            animations.enabled = true;

            input = {
              kb_layout = myconfig.constants.keyboardLayout;
              kb_variant = myconfig.constants.keyboardVariant;
              kb_options = myconfig.constants.keyboardOptions;
              touchpad.natural_scroll = false;
            };

            cursor.no_hardware_cursors = cfg.noHardwareCursors;

            dwindle.preserve_split = true;

            master = {
              new_status = "slave";
              new_on_top = true;
              mfact = 0.5;
            };

            misc = {
              force_default_wallpaper = 0;
              disable_hyprland_logo = true;
              background_color = "rgb(${colors.base00})";
            };

            xwayland = {
              force_zero_scaling = true;
            };

            group = {
              "col.border_active" = "rgb(${colors.base0D})";
              "col.border_inactive" = "rgb(${colors.base03})";
              "col.border_locked_active" = "rgb(${colors.base0C})";
              groupbar = {
                text_color = "rgb(${colors.base05})";
                "col.active" = "rgb(${colors.base0D})";
                "col.inactive" = "rgb(${colors.base03})";
              };
            };
          };
        };
      };
    };
}
