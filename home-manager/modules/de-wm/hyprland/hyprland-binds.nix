{ pkgs, lib, vars, ... }: {
  config = lib.mkIf (vars.hyprland or false) {
    wayland.windowManager.hyprland.settings = {
      bind = [
        # BASIC WINDOW MANAGEMENT
        "$mainMod SHIFT, C, killactive," # Close active window
        "$mainMod,       J, togglesplit," # Toggle split/stacked layout
        "$mainMod,        space, togglefloating," # Toggle floating mode: the window can be freely moved/resized
        "$mainMod,       M, fullscreen," # Toggle fullscreen (maximise): the window occupies the entire screen
        "$mainMod ALT,   P, pin," # Pin/unpin window. Copy the same windows to all workspaces with same dimensions and position

        # APPLICATION LAUNCHING
        "$mainMod,       A, exec, $menu --show drun" # Application launcher menu (wofi)
        "$mainMod, return, exec, $term" # Default terminal chosen in ./main.nix

        # FILE MANAGER
        "$mainMod,       F, exec, $fileManager"

        # WEB BROWSER
        "$mainMod,       B, exec, ${vars.browser}" # Web browser

        # FILE EDITOR
        "$mainMod, C, exec, $editor" # Code editor

        # SESSION MANAGEMENT
        "$mainMod SHIFT, Delete, exit," # Log out
        "$mainMod,       Delete, exec, loginctl lock-session" # Lock

        # EXTRA UTILITIES
        "$mainMod,       period, exec, bemoji -cn" # Emoji picker
        "$mainMod SHIFT, P, exec, hyprpicker -an" # Color picker
        "$mainMod,       V, exec, cliphist list | $menu --dmenu | cliphist decode | wl-copy" # Clipboard history (cliphist)
        "$mainMod SHIFT, R, exec, hyprctl reload" # Reload Hyprland config
        "$mainMod,       N, exec, swaync-client -t" # Open notification center

        # WAYBAR CONTROLS
        "$mainMod ALT,   W, exec, pkill -SIGUSR2 waybar" # Reload config + CSS

        "$mainMod SHIFT, W, exec, pkill -x -SIGUSR1 waybar" # Toggle show/hide

        # SCREENSHOTS (Updated to Meta+Ctrl)
        "SUPER CTRL, 3, exec, grimblast --notify --freeze copysave output" # Fullscreen
        "SUPER CTRL, 4, exec, grimblast --notify --freeze copysave area" # Region
        ''
          SUPER CTRL, R, exec, pkill -SIGINT gpu-screen-recorder || gpu-screen-recorder -w screen -f 60 -c mkv -o "$HOME/Videos/Recordings/mute-fullscreen-recording_$(date +%Y-%m-%d_%H-%M-%S).mkv"''

        # MOVING FOCUS
        "$mainMod,      left, movefocus, l" # Move focus left
        "$mainMod,      H, movefocus, l" # Move focus left (alternative key)

        "$mainMod,      right, movefocus, r" # Move focus right
        "$mainMod,      L, movefocus, r" # Move focus right (alternative key)

        "$mainMod,      up, movefocus, u" # Move focus up
        "$mainMod,      K, movefocus, u" # Move focus up (alternative key)

        "$mainMod,      down, movefocus, d" # Move focus down
        "$mainMod,      J, movefocus, d" # Move focus down (alternative key)

        "CONTROL, Right, workspace, m+1" # Move to next workspace number
        "CONTROL, Left, workspace, m-1" # Move to previous workspace number

        # MOVING WINDOWS
        "$mainMod SHIFT, left,  swapwindow, l" # Move window left
        "$mainMod SHIFT, H,     swapwindow, l" # Move window left (alternative key)

        "$mainMod SHIFT, right, swapwindow, r" # Move window right
        "$mainMod SHIFT, L,     swapwindow, r" # Move window right (alternative key)

        "$mainMod SHIFT, up,    swapwindow, u" # Move window up
        "$mainMod SHIFT, K,     swapwindow, u" # Move window up (alternative key)

        "$mainMod SHIFT, down,  swapwindow, d" # Move window down
        "$mainMod SHIFT, J,     swapwindow, d" # Move window down (alternative key)

        # RESIZEING WINDOWS                   X  Y
        "$mainMod CTRL, left,  resizeactive, -60 0" # Resize window left, -60 represent pixels
        "$mainMod CTRL, right, resizeactive,  60 0" # Resize window right +60 represent pixels
        "$mainMod CTRL, up,    resizeactive,  0 -60" # Resize window up, -60 represent pixels
        "$mainMod CTRL, down,  resizeactive,  0  60" # Resize window down +60 represent pixels

        # SWITCHING WORKSPACES
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # MOVING WINDOWS TO WORKSPACES
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod SHIFT, 0, movetoworkspacesilent, 10"

        # SCRATCHPAD IS A SPECIAL HIDDEN WORKSPACE FOR TEMPORARY WINDOWS
        # They overlay other windows and can be toggled visible/invisible
        "$mainMod,       S, togglespecialworkspace,  magic" # Toggle scratchpad visibility
        "$mainMod SHIFT, S, movetoworkspace, special:magic" # Move window to scratchpad
      ] ++ (vars.hyprlandExtraBinds or [ ]);

      # MOVE/RESIZE WINDOWS WITH MAINMOD + LMB/RMB AND DRAGGING
      bindm = [
        "$mainMod, mouse:272, movewindow" # 272 is left mouse button
        "$mainMod, mouse:273, resizewindow" # 273 is right mouse button
      ];

      # LAPTOP MULTIMEDIA KEYS FOR VOLUME AND LCD BRIGHTNESS
      bindel = [
        ",XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" # Increase volume by 5%
        ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" # Decrease volume by 5%
        ",XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" # Toggle mute
        ",XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" # Toggle mic mute
        "$mainMod, bracketright, exec, brightnessctl s 10%+" # Increase screen brightness by 10%
        "$mainMod, bracketleft,  exec, brightnessctl s 10%-" # Decrease screen brightness by 10%
      ];

      # AUDIO PLAYBACK
      bindl = [
        ", XF86AudioNext,  exec, playerctl next" # Next track
        ", XF86AudioPause, exec, playerctl play-pause" # Pause playback
        ", XF86AudioPlay,  exec, playerctl play-pause" # Play playback
        ", XF86AudioPrev,  exec, playerctl previous" # Previous track
      ];
    };
  };
}
