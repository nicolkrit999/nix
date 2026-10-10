{ delib
, lib
, pkgs
, config
, ...
}:
delib.module {
  name = "programs.mango";
  options =
    with delib;
    moduleOptions {
      execOnce = listOfOption str [ ];
      monitors = listOfOption str [ ];
      windowRules = listOfOption str [ ];
      # window_rule_once re-arms on every config reload (option_defs.c:1312-1317)
      windowRulesOnce = listOfOption str [ ];
      defaultLayout = strOption "scroller";
      monitorLayouts = attrsOption { };
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      baseWindowRules = [
        "is_floating:1,app_id:^(mpv|imv|showmethekey-gtk)$"
        "is_floating:1,no_animation:1,no_shadow:1,no_blur:1,is_open_silent:1,app_id:^(ueberzugpp_layer)$"
        "is_floating:1,width:1200,height:800,app_id:^(org.kde.gwenview)$"
        "is_floating:1,width:900,height:600,title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"
        "is_floating:1,width:900,height:600,app_id:^(xdg-desktop-portal-kde|xdg-desktop-portal-gtk)$"
        "is_floating:1,focused_opacity:0.01,unfocused_opacity:0.01,no_animation:1,no_blur:1,width:1,height:1,is_open_silent:1,app_id:^(xwaylandvideobridge)$"
      ];

      noctaliaActiveOnMango =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnMango or false);
      wallpaperOwnedByShell = noctaliaActiveOnMango;
      skwdWallActive = parent.skwdWall.enable or false;

      wp = import ../wallpaperd/mk-wallpaperd.nix { inherit lib pkgs; } {
        wm = "mango";
        wallpapers = myconfig.constants.wallpapers;
      };

      wallpaperExecs =
        lib.optionals (!(wallpaperOwnedByShell || skwdWallActive)) wp.launcherCmds;

      fitValues = key: map (v:
        if lib.stringLength v > 255 then
          throw "programs.mango: ${key} value is ${toString (lib.stringLength v)} chars, mango truncates config values at 255: ${v}"
        else
          v);
    in
    with config.lib.stylix.colors;
    {
      home.packages = with pkgs; [
        awww
        mpvpaper
        libnotify
        hyprpicker
        wl-clipboard
        pavucontrol
        brightnessctl
        playerctl
        imv
        mpv
        grim
        slurp
        swappy
        wev
      ];

      home.sessionVariables = {
        XDG_SCREENSHOTS_DIR = myconfig.constants.screenshots;
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        GDK_BACKEND = "wayland,x11,*";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = "1";
        # Serves Hyprland (force_zero_scaling); mango overrides it via settings.env
        GDK_SCALE =
          let
            firstMonitor = if cfg.monitors != [ ] then builtins.head cfg.monitors else "";
            m = builtins.match ".*scale:([0-9]+(\\.[0-9]+)?).*" firstMonitor;
            rawScale = if m != null then builtins.head m else "1";
          in
          if rawScale != "1" && rawScale != "1.0" then "2" else "1";
      };

      wayland.windowManager.mango = {
        enable = true;

        systemd = {
          enable = true;
          variables = [
            "DISPLAY"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
            "XDG_SESSION_TYPE"
            "XDG_SESSION_DESKTOP"
            "NIXOS_OZONE_WL"
            "QT_QPA_PLATFORM"
            "GDK_BACKEND"
            "SDL_VIDEODRIVER"
            "CLUTTER_BACKEND"
            "_JAVA_AWT_WM_NONREPARENTING"
            "GDK_SCALE"
            "XCURSOR_THEME"
            "XCURSOR_SIZE"
            "XDG_SCREENSHOTS_DIR"
          ];
        };

        settings = {
          env = [ "GDK_SCALE,1" ];
          monitor_rule = fitValues "monitor_rule" cfg.monitors;
          window_rule = fitValues "window_rule" (baseWindowRules ++ cfg.windowRules);
          window_rule_once = fitValues "window_rule_once" cfg.windowRulesOnce;

          blur = 0;
          blur_layer = 0;
          blur_optimized = 1;

          shadows = 0;
          layer_shadows = 0;
          shadow_only_floating = 1;
          shadows_size = 10;
          shadows_blur = 15;
          shadows_position_x = 0;
          shadows_position_y = 0;
          shadows_color = "0x000000ff";

          border_radius = 10;
          no_radius_when_single = 0;
          focused_opacity = "1.0";
          unfocused_opacity = "1.0";

          animations = 1;
          layer_animations = 1;
          animation_type_open = "zoom";
          animation_type_close = "zoom";
          animation_fade_in = 1;
          animation_fade_out = 1;
          tag_animation_direction = 1;
          zoom_initial_ratio = "0.3";
          zoom_end_ratio = "1.0";
          fade_in_begin_opacity = "0.0";
          fade_out_begin_opacity = "1.0";
          animation_duration_move = 300;
          animation_duration_open = 200;
          animation_duration_tag = 400;
          animation_duration_close = 150;
          animation_duration_focus = 0;
          animation_curve_open = "0.16,1,0.3,1";
          animation_curve_move = "0.16,1,0.3,1";
          animation_curve_tag = "0.45,0,0.55,1";
          animation_curve_close = "0.16,1,0.3,1";
          animation_curve_focus = "0.16,1,0.3,1";
          animation_curve_opacity_fade_out = "0.16,1,0.3,1";
          animation_curve_opacity_fade_in = "0.16,1,0.3,1";

          scroller_structs = 0;
          scroller_default_proportion = "0.5";
          scroller_focus_center = 0;
          scroller_prefer_center = 0;
          edge_scroller_pointer_focus = 1;
          scroller_default_proportion_single = "1.0";
          scroller_proportion_preset = "0.33333,0.5,0.66667";

          new_is_master = 1;
          default_master_factor = "0.5";
          default_master_count = 1;
          smart_gaps = 0;

          enable_hotarea = 0;
          overview_gap_inner = 5;
          overview_gap_outer = 30;

          no_border_when_single = 0;
          axis_bind_apply_timeout = 100;
          focus_on_activate = 1;
          idle_inhibit_ignore_visible = 0;
          sloppy_focus = 1;
          warp_cursor = 1;
          focus_cross_monitor = 0;
          focus_cross_tag = 0;
          enable_floating_snap = 0;
          snap_distance = 30;
          cursor_size = 24;
          drag_tile_to_tile = 1;

          repeat_rate = 25;
          repeat_delay = 600;
          numlock_on = 0;
          xkb_rules_layout = myconfig.constants.keyboardLayout;
          xkb_rules_variant = myconfig.constants.keyboardVariant;
          xkb_rules_options = "grp:ctrl_alt_toggle";

          disable_trackpad = 0;
          tap_to_click = 1;
          tap_and_drag = 1;
          drag_lock = 1;
          trackpad_natural_scrolling = 0;
          trackpad_disable_while_typing = 1;
          trackpad_left_handed = 0;
          trackpad_middle_button_emulation = 0;
          swipe_min_threshold = 1;

          mouse_natural_scrolling = 0;
          mouse_left_handed = 0;
          mouse_middle_button_emulation = 0;

          gap_inner_horizontal = 8;
          gap_inner_vertical = 8;
          gap_outer_horizontal = 16;
          gap_outer_vertical = 16;
          scratchpad_width_ratio = "0.8";
          scratchpad_height_ratio = "0.9";
          border_px = 2;
          root_color = "0x${base00}ff";
          border_color = "0x${base03}ff";
          focus_color = "0x${base0D}ff";
          maximized_screen_color = "0x${base0B}ff";
          urgent_color = "0x${base08}ff";
          scratchpad_color = "0x${base0A}ff";
          global_color = "0x${base0E}ff";
          overlay_color = "0x${base0C}ff";

          exec_once = fitValues "exec_once" (
            [
              "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
              "dbus-update-activation-environment --systemd --all"
            ]
            ++ wallpaperExecs
            ++ cfg.execOnce
          );
        };

        autostart_sh = ''
          export XDG_SCREENSHOTS_DIR="${myconfig.constants.screenshots}"
          mkdir -p "${myconfig.constants.screenshots}"
        '';
      };
    };
}
