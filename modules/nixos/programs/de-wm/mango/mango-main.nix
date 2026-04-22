{ delib
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
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
      with config.lib.stylix.colors;
      {
        home.packages = with pkgs; [
          xwayland-satellite
          swww
          libnotify
          hyprpicker
          wl-clipboard
          pavucontrol
          brightnessctl
          playerctl
          imv
          mpv
          grimblast
          swappy
          slurp
        ];

        home.sessionVariables = {
          XDG_SCREENSHOTS_DIR = myconfig.constants.screenshots;
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
              "NIXOS_OZONE_WL"
              "XCURSOR_THEME"
              "XCURSOR_SIZE"
              "XDG_SCREENSHOTS_DIR"
            ];
          };

          settings = {
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
            shadowscolor = "0x000000ff";

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
            fadein_begin_opacity = "0.0";
            fadeout_begin_opacity = "1.0";
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
            animation_curve_opafadeout = "0.16,1,0.3,1";
            animation_curve_opafadein = "0.16,1,0.3,1";

            scroller_structs = 0;
            scroller_default_proportion = "0.5";
            scroller_focus_center = 0;
            scroller_prefer_center = 0;
            edge_scroller_pointer_focus = 1;
            scroller_default_proportion_single = "1.0";
            scroller_proportion_preset = "0.33333,0.5,0.66667";

            new_is_master = 1;
            default_mfact = "0.5";
            default_nmaster = 1;
            smartgaps = 0;

            enable_hotarea = 0;
            ov_tab_mode = 0;
            overviewgappi = 5;
            overviewgappo = 30;

            no_border_when_single = 0;
            axis_bind_apply_timeout = 100;
            focus_on_activate = 1;
            idleinhibit_ignore_visible = 0;
            sloppyfocus = 1;
            warpcursor = 1;
            focus_cross_monitor = 0;
            focus_cross_tag = 0;
            enable_floating_snap = 0;
            snap_distance = 30;
            cursor_size = 24;
            drag_tile_to_tile = 1;

            repeat_rate = 25;
            repeat_delay = 600;
            numlockon = 0;
            xkb_rules_layout = myconfig.constants.keyboardLayout;
            xkb_rules_variant = myconfig.constants.keyboardVariant;
            xkb_rules_options = "grp:ctrl_alt_toggle";

            disable_trackpad = 0;
            tap_to_click = 1;
            tap_and_drag = 1;
            drag_lock = 1;
            trackpad_natural_scrolling = 0;
            disable_while_typing = 1;
            left_handed = 0;
            middle_button_emulation = 0;
            swipe_min_threshold = 1;

            mouse_natural_scrolling = 0;

            gappih = 8;
            gappiv = 8;
            gappoh = 16;
            gappov = 16;
            scratchpad_width_ratio = "0.8";
            scratchpad_height_ratio = "0.9";
            borderpx = 2;
            rootcolor = "0x${base00}ff";
            bordercolor = "0x${base03}ff";
            focuscolor = "0x${base0D}ff";
            maximizescreencolor = "0x${base0B}ff";
            urgentcolor = "0x${base08}ff";
            scratchpadcolor = "0x${base0A}ff";
            globalcolor = "0x${base0E}ff";
            overlaycolor = "0x${base0C}ff";

            exec = [
              "xwayland-satellite :1"
              "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
              "dbus-update-activation-environment --systemd --all"
              "swww-daemon"
            ]
            ++ (map
              (w:
                let
                  imgPath = pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; };
                  targetArgs = if w.targetMonitor == "*" then "" else "-o ${w.targetMonitor} ";
                in
                "sh -c 'sleep 1 && swww img ${targetArgs}${imgPath}'")
              myconfig.constants.wallpapers)
            ++ cfg.execOnce;
          };

          autostart_sh = ''
            systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY XDG_SCREENSHOTS_DIR
            export XDG_SCREENSHOTS_DIR="${myconfig.constants.screenshots}"
            mkdir -p "${myconfig.constants.screenshots}"
          '';
        };
      };
}
