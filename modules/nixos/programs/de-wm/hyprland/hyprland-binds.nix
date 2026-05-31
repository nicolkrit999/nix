{ delib
, ...
}:
delib.module {
  name = "programs.hyprland";
  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      mod = "SUPER";
      term = myconfig.constants.terminal.name or "alacritty";
      browser = myconfig.constants.browser or "firefox";
      rawFm = myconfig.constants.fileManager or "dolphin";
      rawEd = myconfig.constants.editor or "vscode";
      termApps = [ "nvim" "neovim" "vim" "nano" "hx" "helix" "yazi" "ranger" "lf" "nnn" ];
      smartFm = if builtins.elem rawFm termApps then "${term} --class ${rawFm} -e ${rawFm}" else rawFm;
      smartEd = if builtins.elem rawEd termApps then "${term} --class ${rawEd} -e ${rawEd}" else rawEd;

      caelestiaActiveOnHyprland =
        (myconfig.programs.caelestia.enable or false)
        && (myconfig.programs.caelestia.enableOnHyprland or false);
      noctaliaActiveOnHyprland =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnHyprland or false);

      shellMenu =
        if caelestiaActiveOnHyprland then "caelestiaQS"
        else if noctaliaActiveOnHyprland then "noctalia-shell ipc call toggleAppLauncher"
        else "true";

      shellLock =
        if caelestiaActiveOnHyprland then "caelestiaLogout lock"
        else if noctaliaActiveOnHyprland then "noctalia-shell ipc call lockScreen lock"
        else "loginctl lock-session";

      shellActiveOnHyprland = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;

      bindelList =
        if shellActiveOnHyprland then [
          { _args = [ "" "XF86AudioRaiseVolume" "exec" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" ]; }
          { _args = [ "" "XF86AudioLowerVolume" "exec" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" ]; }
          { _args = [ "" "XF86AudioMute" "exec" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ]; }
          { _args = [ "" "XF86AudioMicMute" "exec" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" ]; }
          { _args = [ "" "XF86MonBrightnessUp" "exec" "brightnessctl set 5%+" ]; }
          { _args = [ "" "XF86MonBrightnessDown" "exec" "brightnessctl set 5%-" ]; }
          { _args = [ mod "bracketright" "exec" "brightnessctl set 5%+" ]; }
          { _args = [ mod "bracketleft" "exec" "brightnessctl set 5%-" ]; }
          { _args = [ "" "XF86KbdBrightnessUp" "exec" "brightnessctl --device='*::kbd_backlight' set +10%" ]; }
          { _args = [ "" "XF86KbdBrightnessDown" "exec" "brightnessctl --device='*::kbd_backlight' set 10%-" ]; }
        ] else [
          { _args = [ "" "XF86AudioRaiseVolume" "exec" "swayosd-client --output-volume raise" ]; }
          { _args = [ "" "XF86AudioLowerVolume" "exec" "swayosd-client --output-volume lower" ]; }
          { _args = [ "" "XF86AudioMute" "exec" "swayosd-client --output-volume mute-toggle" ]; }
          { _args = [ "" "XF86AudioMicMute" "exec" "swayosd-client --input-volume mute-toggle" ]; }
          { _args = [ "" "XF86MonBrightnessUp" "exec" "swayosd-client --brightness raise" ]; }
          { _args = [ "" "XF86MonBrightnessDown" "exec" "swayosd-client --brightness lower" ]; }
          { _args = [ mod "bracketright" "exec" "swayosd-client --brightness raise" ]; }
          { _args = [ mod "bracketleft" "exec" "swayosd-client --brightness lower" ]; }
          { _args = [ "" "XF86KbdBrightnessUp" "exec" "swayosd-client --keyboard-brightness raise" ]; }
          { _args = [ "" "XF86KbdBrightnessDown" "exec" "swayosd-client --keyboard-brightness lower" ]; }
        ];

      bindlList =
        if shellActiveOnHyprland then [
          { _args = [ "" "XF86AudioNext" "exec" "playerctl next" ]; }
          { _args = [ "" "XF86AudioPause" "exec" "playerctl play-pause" ]; }
          { _args = [ "" "XF86AudioPlay" "exec" "playerctl play-pause" ]; }
          { _args = [ "" "XF86AudioPrev" "exec" "playerctl previous" ]; }
          { _args = [ "" "XF86AudioStop" "exec" "playerctl stop" ]; }
        ] else [
          { _args = [ "" "XF86AudioNext" "exec" "swayosd-client --playerctl next" ]; }
          { _args = [ "" "XF86AudioPause" "exec" "swayosd-client --playerctl play-pause" ]; }
          { _args = [ "" "XF86AudioPlay" "exec" "swayosd-client --playerctl play-pause" ]; }
          { _args = [ "" "XF86AudioPrev" "exec" "swayosd-client --playerctl previous" ]; }
          { _args = [ "" "XF86AudioStop" "exec" "swayosd-client --playerctl stop" ]; }
          { _args = [ "" "Caps_Lock" "exec" "swayosd-client --caps-lock" ]; }
        ];
    in
    {
      wayland.windowManager.hyprland.settings = {
        gesture = [
          { _args = [ "3" "right" "dispatcher" "workspace, m+1" ]; }
          { _args = [ "3" "left" "dispatcher" "workspace, m-1" ]; }
          { _args = [ "3" "up" "fullscreen" ]; }
          { _args = [ "3" "down" "close" ]; }
          { _args = [ "4" "up" "dispatcher" "exec, vicinae toggle" ]; }
          { _args = [ "4" "down" "special" "magic" ]; }
          { _args = [ "4" "pinchin" "float" ]; }
        ];

        bind = [
          # Window management
          { _args = [ "${mod}+SHIFT" "C" "killactive" ]; }
          { _args = [ mod "T" "togglesplit" ]; }
          { _args = [ mod "space" "togglefloating" ]; }
          { _args = [ mod "M" "fullscreen" ]; }
          { _args = [ "${mod}+ALT" "P" "pin" ]; }
          # PiP mode: float + pin so window follows across workspaces on same monitor
          { _args = [ mod "P" "exec" "hyprctl dispatch togglefloating && hyprctl dispatch pin" ]; }

          # Application launching
          { _args = [ mod "A" "exec" "vicinae toggle" ]; }
          { _args = [ "${mod}+SHIFT" "A" "exec" shellMenu ]; }
          { _args = [ mod "return" "exec" term ]; }
          { _args = [ mod "F" "exec" smartFm ]; }
          { _args = [ mod "B" "exec" browser ]; }
          { _args = [ mod "C" "exec" smartEd ]; }

          # Session
          { _args = [ "${mod}+SHIFT" "Delete" "exit" ]; }
          { _args = [ mod "Delete" "exec" shellLock ]; }

          # Utilities
          { _args = [ mod "period" "exec" "vicinae vicinae://launch/core/search-emojis" ]; }
          { _args = [ "${mod}+SHIFT" "P" "exec" "hyprpicker -an" ]; }
          { _args = [ mod "V" "exec" "vicinae vicinae://launch/clipboard/history" ]; }
          { _args = [ "${mod}+SHIFT" "R" "exec" "hyprctl reload" ]; }
          { _args = [ mod "N" "exec" "swaync-client -t" ]; }

          # Waybar
          { _args = [ "${mod}+ALT" "W" "exec" "pkill -SIGUSR2 waybar" ]; }
          { _args = [ "${mod}+SHIFT" "W" "exec" "pkill -x -SIGUSR1 waybar" ]; }

          # Screenshots
          { _args = [ "" "Print" "exec" "grimblast --notify --freeze copysave output" ]; }
          { _args = [ "SUPER+CTRL" "3" "exec" "grimblast --notify --freeze copysave output" ]; }
          { _args = [ "SUPER+CTRL" "4" "exec" "grimblast --notify --freeze copysave area" ]; }

          # Focus
          { _args = [ mod "left" "movefocus" "l" ]; }
          { _args = [ mod "H" "movefocus" "l" ]; }
          { _args = [ mod "right" "movefocus" "r" ]; }
          { _args = [ mod "L" "movefocus" "r" ]; }
          { _args = [ mod "up" "movefocus" "u" ]; }
          { _args = [ mod "K" "movefocus" "u" ]; }
          { _args = [ mod "down" "movefocus" "d" ]; }
          { _args = [ mod "J" "movefocus" "d" ]; }

          # Move windows
          { _args = [ "${mod}+SHIFT" "left" "swapwindow" "l" ]; }
          { _args = [ "${mod}+SHIFT" "H" "swapwindow" "l" ]; }
          { _args = [ "${mod}+SHIFT" "right" "swapwindow" "r" ]; }
          { _args = [ "${mod}+SHIFT" "L" "swapwindow" "r" ]; }
          { _args = [ "${mod}+SHIFT" "up" "swapwindow" "u" ]; }
          { _args = [ "${mod}+SHIFT" "K" "swapwindow" "u" ]; }
          { _args = [ "${mod}+SHIFT" "down" "swapwindow" "d" ]; }
          { _args = [ "${mod}+SHIFT" "J" "swapwindow" "d" ]; }

          # Resize
          { _args = [ "${mod}+CTRL" "left" "resizeactive" "-60 0" ]; }
          { _args = [ "${mod}+CTRL" "right" "resizeactive" "60 0" ]; }
          { _args = [ "${mod}+CTRL" "up" "resizeactive" "0 -60" ]; }
          { _args = [ "${mod}+CTRL" "down" "resizeactive" "0 60" ]; }

          # Workspaces
          { _args = [ mod "1" "workspace" "1" ]; }
          { _args = [ mod "2" "workspace" "2" ]; }
          { _args = [ mod "3" "workspace" "3" ]; }
          { _args = [ mod "4" "workspace" "4" ]; }
          { _args = [ mod "5" "workspace" "5" ]; }
          { _args = [ mod "6" "workspace" "6" ]; }
          { _args = [ mod "7" "workspace" "7" ]; }
          { _args = [ mod "8" "workspace" "8" ]; }
          { _args = [ mod "9" "workspace" "9" ]; }
          { _args = [ mod "0" "workspace" "10" ]; }

          { _args = [ "${mod}+SHIFT" "1" "movetoworkspacesilent" "1" ]; }
          { _args = [ "${mod}+SHIFT" "2" "movetoworkspacesilent" "2" ]; }
          { _args = [ "${mod}+SHIFT" "3" "movetoworkspacesilent" "3" ]; }
          { _args = [ "${mod}+SHIFT" "4" "movetoworkspacesilent" "4" ]; }
          { _args = [ "${mod}+SHIFT" "5" "movetoworkspacesilent" "5" ]; }
          { _args = [ "${mod}+SHIFT" "6" "movetoworkspacesilent" "6" ]; }
          { _args = [ "${mod}+SHIFT" "7" "movetoworkspacesilent" "7" ]; }
          { _args = [ "${mod}+SHIFT" "8" "movetoworkspacesilent" "8" ]; }
          { _args = [ "${mod}+SHIFT" "9" "movetoworkspacesilent" "9" ]; }
          { _args = [ "${mod}+SHIFT" "0" "movetoworkspacesilent" "10" ]; }

          # Scratchpad
          { _args = [ mod "S" "togglespecialworkspace" "magic" ]; }
          { _args = [ "${mod}+SHIFT" "S" "movetoworkspace" "special:magic" ]; }
        ]
        ++ (cfg.extraBinds or [ ]);

        bindm = [
          { _args = [ mod "mouse:272" "movewindow" ]; }
          { _args = [ mod "mouse:273" "resizewindow" ]; }
        ];

        bindel = bindelList;

        bindl = bindlList ++ (cfg.extraBindl or [ ]);
      };
    };
}
