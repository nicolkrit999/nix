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
      monitorWorkspaces = listOfOption attrs [ ];
      windowRules = listOfOption attrs [ ];
      extraBinds = listOfOption attrs [ ];
      extraBindl = listOfOption attrs [ ];
      noHardwareCursors = boolOption false;
    };

  nixos.ifEnabled = {
    myconfig.stylix.targets.hyprland.enable = false;
  };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      inherit (lib.generators) mkLuaInline;
      term = myconfig.constants.terminal.name or "alacritty";

      caelestiaActiveOnHyprland =
        (parent.caelestia.enable or false)
        && (parent.caelestia.enableOnHyprland or false);
      noctaliaActiveOnHyprland =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnHyprland or false);
      wallpaperOwnedByShell = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;

      wallpaperCmds = lib.optionals (!wallpaperOwnedByShell) (
        [ "awww-daemon" ]
        ++ map
          (w:
            let
              imgPath = pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; };
              isWildcard = w.targetMonitor == "*";
              targetArgs = if isWildcard then "" else "-o ${w.targetMonitor} ";
              sleepSecs = if isWildcard then "1" else "2";
            in
            "sh -c 'sleep ${sleepSecs} && awww img ${targetArgs}${imgPath}'")
          myconfig.constants.wallpapers
      );

      execOnceItems = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "pkill ibus-daemon"
      ] ++ wallpaperCmds ++ cfg.execOnce;

      execOnceFn = mkLuaInline (
        "function()\n"
        + lib.concatMapStrings (cmd: "  hl.exec_cmd(${builtins.toJSON cmd})\n") execOnceItems
        + "end"
      );

      staticWindowRules = [
        { match.class = "(mpv)|(imv)|(showmethekey-gtk)"; float = true; }
        { match.class = "(showmethekey-gtk)"; border_size = 0; }
        { match.class = "(showmethekey-gtk)"; no_focus = true; }
        { match.class = "(showmethekey-gtk)"; pin = true; }
        { match.class = "(showmethekey-gtk)"; no_initial_focus = true; }
        { match.class = "(showmethekey-gtk)"; move = "990 60"; }
        { match.class = "(showmethekey-gtk)"; size = "900 170"; }

        { match.class = "^(ueberzugpp_layer)$"; float = true; }
        { match.class = "^(ueberzugpp_layer)$"; no_anim = true; }
        { match.class = "^(ueberzugpp_layer)$"; no_shadow = true; }
        { match.class = "^(ueberzugpp_layer)$"; no_blur = true; }
        { match.class = "^(ueberzugpp_layer)$"; no_initial_focus = true; }

        { match.class = "^(org.kde.gwenview)$"; float = true; }
        { match.class = "^(org.kde.gwenview)$"; center = true; }
        { match.class = "^(org.kde.gwenview)$"; size = "80% 80%"; }

        { match.title = "^(Open File)(.*)$"; float = true; }
        { match.title = "^(Select a File)(.*)$"; float = true; }
        { match.title = "^(Choose wallpaper)(.*)$"; float = true; }
        { match.title = "^(Open Folder)(.*)$"; float = true; }
        { match.title = "^(Save As)(.*)$"; float = true; }
        { match.title = "^(Library)(.*)$"; float = true; }
        { match.title = "^(File Upload)(.*)$"; float = true; }
        { match.title = "^(Save File)(.*)$"; float = true; }
        { match.title = "^(Enter name of file)(.*)$"; float = true; }
        { match.title = "^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"; center = true; }
        { match.title = "^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"; size = "50% 50%"; }

        { match.class = "^(xdg-desktop-portal-kde)$"; float = true; }
        { match.class = "^(xdg-desktop-portal-kde)$"; center = true; }
        { match.class = "^(xdg-desktop-portal-kde)$"; size = "50% 50%"; }

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

        { match.class = "^(xwaylandvideobridge)$"; opacity = "0.0 override"; }
        { match.class = "^(xwaylandvideobridge)$"; no_anim = true; }
        { match.class = "^(xwaylandvideobridge)$"; no_initial_focus = true; }
        { match.class = "^(xwaylandvideobridge)$"; max_size = "1 1"; }
        { match.class = "^(xwaylandvideobridge)$"; no_blur = true; }
        { match.class = "^(xwaylandvideobridge)$"; no_focus = true; }
      ]
      ++ lib.optional
        ((myconfig.constants.hyprland.terminalOpacity or 1.0) < 1.0)
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
        { _args = [ "SDL_VIDEODRIVER" "wayland" ]; }
        { _args = [ "CLUTTER_BACKEND" "wayland" ]; }
        { _args = [ "_JAVA_AWT_WM_NONREPARENTING" "1" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SCREENSHOTS_DIR" (builtins.replaceStrings [ "$HOME" ] [ "/home/${myconfig.constants.user}" ] myconfig.constants.screenshots) ]; }
      ];

      staticGestures = [
        { fingers = 3; direction = "right"; action = "workspace"; }
        { fingers = 3; direction = "left"; action = "workspace"; }
        { fingers = 3; direction = "up"; action = "fullscreen"; }
        { fingers = 3; direction = "down"; action = "close"; }
        {
          fingers = 4;
          direction = "up";
          action = mkLuaInline ''function() hl.exec_cmd("vicinae toggle") end'';
        }
        { fingers = 4; direction = "down"; action = "special"; workspace_name = "magic"; }
        { fingers = 4; direction = "pinchin"; action = "float"; }
      ];
    in

    {
      catppuccin.hyprland.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.hyprland.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprland.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      home.packages = with pkgs; [
        kdePackages.gwenview
        grimblast
        awww
        hyprpicker
        imv
        mpv
        brightnessctl
        pavucontrol
        playerctl
        showmethekey
        wl-clipboard
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        systemd = {
          enable = true;
          variables = [ "--all" ];
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
              gaps_in = myconfig.constants.hyprland.gap or 5;
              gaps_out = (myconfig.constants.hyprland.gap or 10) * 2;
              border_size = myconfig.constants.hyprland.borderSize or 2;

              "col.active_border" = lib.mkDefault (
                if myconfig.constants.theme.catppuccin then
                  "$accent"
                else
                  "rgb(${config.lib.stylix.colors.base0D})"
              );

              "col.inactive_border" = lib.mkForce "rgba(${config.lib.stylix.colors.base02}66)";

              resize_on_border = true;
              allow_tearing = false;
              layout = "dwindle";
            };

            decoration = {
              rounding = myconfig.constants.hyprland.rounding or 0;
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
              kb_layout = myconfig.constants.keyboardLayout or "us";
              kb_variant = myconfig.constants.keyboardVariant or "";
              kb_options = "grp:ctrl_alt_toggle";
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
              background_color = "rgb(${config.lib.stylix.colors.base00})";
            };

            group = {
              "col.border_active" = "rgb(${config.lib.stylix.colors.base0D})";
              "col.border_inactive" = "rgb(${config.lib.stylix.colors.base03})";
              "col.border_locked_active" = "rgb(${config.lib.stylix.colors.base0C})";
              groupbar = {
                text_color = "rgb(${config.lib.stylix.colors.base05})";
                "col.active" = "rgb(${config.lib.stylix.colors.base0D})";
                "col.inactive" = "rgb(${config.lib.stylix.colors.base03})";
              };
            };
          };
        };
      };
    };
}
