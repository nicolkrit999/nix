{ pkgs, lib, vars, ... }: {
  config = lib.mkIf (vars.hyprland or false) {
    wayland.windowManager.hyprland.settings = {
      bind = [
        # BASIC WINDOW MANAGEMENT
        "$Mod SHIFT, C, killactive" # Close active window
        "$Mod,       T, togglesplit" # Toggle split/stacked layout
        "$Mod,        space, togglefloating" # Toggle floating mode: the window can be freely moved/resized
        "$Mod,       M, fullscreen" # Toggle fullscreen (maximise): the window occupies the entire screen
        "$Mod ALT,   P, pin" # Pin/unpin window. Copy the same windows to all workspaces with same dimensions and position

        # APPLICATION LAUNCHING
        #"$Mod,      A, exec, wofi --show drun" # Fallback for the launcher
        "$Mod,      A, exec, $menu" # Application launcher (wofi/rofi)
        "$Mod, return, exec, $term" # Default terminal chosen in ./main.nix

        # FILE MANAGER
        "$Mod,       F, exec, $fileManager"

        # WEB BROWSER
        "$Mod,       B, exec, ${vars.browser}" # Web browser

        # FILE EDITOR
        "$Mod, C, exec, $editor" # Code editor

        # SESSION MANAGEMENT
        "$Mod SHIFT, Delete, exit" # Log out
        "$Mod,       Delete, exec, loginctl lock-session" # Lock

        # EXTRA UTILITIES
        "$Mod,       period, exec, bemoji -cn" # Emoji picker
        "$Mod SHIFT, P, exec, hyprpicker -an" # Color picker
        "$Mod,       V, exec, cliphist list | $menu --dmenu | cliphist decode | wl-copy" # Clipboard history (cliphist)
        "$Mod SHIFT, R, exec, hyprctl reload" # Reload Hyprland config
        "$Mod,       N, exec, swaync-client -t" # Open notification center

        # WAYBAR CONTROLS
        "$Mod ALT,   W, exec, pkill -SIGUSR2 waybar" # Reload config + CSS

        "$Mod SHIFT, W, exec, pkill -x -SIGUSR1 waybar" # Toggle show/hide

        # SCREENSHOTS (Updated to Meta+Ctrl)
        "SUPER CTRL, 3, exec, grimblast --notify --freeze copysave output" # Fullscreen
        "SUPER CTRL, 4, exec, grimblast --notify --freeze copysave area" # Region

        # MOVING FOCUS
        "$Mod,      left, movefocus, l" # Move focus left
        "$Mod,      H, movefocus, l" # Move focus left (alternative key)

        "$Mod,      right, movefocus, r" # Move focus right
        "$Mod,      L, movefocus, r" # Move focus right (alternative key)

        "$Mod,      up, movefocus, u" # Move focus up
        "$Mod,      K, movefocus, u" # Move focus up (alternative key)

        "$Mod,      down, movefocus, d" # Move focus down
        "$Mod,      J, movefocus, d" # Move focus down (alternative key)

        "CONTROL, Right, workspace, m+1" # Move to next workspace number
        "CONTROL, L,     workspace, m+1" # Move to next workspace number
        "CONTROL, Left, workspace, m-1" # Move to previous workspace number
        "CONTROL, H,    workspace, m-1" # Move to previous workspace number

        # MOVING WINDOWS
        "$Mod SHIFT, left,  swapwindow, l" # Move window left
        "$Mod SHIFT, H,     swapwindow, l" # Move window left (alternative key)

        "$Mod SHIFT, right, swapwindow, r" # Move window right
        "$Mod SHIFT, L,     swapwindow, r" # Move window right (alternative key)

        "$Mod SHIFT, up,    swapwindow, u" # Move window up
        "$Mod SHIFT, K,     swapwindow, u" # Move window up (alternative key)

        "$Mod SHIFT, down,  swapwindow, d" # Move window down
        "$Mod SHIFT, J,     swapwindow, d" # Move window down (alternative key)

        # RESIZEING WINDOWS                   X  Y
        "$Mod CTRL, left,  resizeactive, -60 0" # Resize window left, -60 represent pixels
        "$Mod CTRL, right, resizeactive,  60 0" # Resize window right +60 represent pixels
        "$Mod CTRL, up,    resizeactive,  0 -60" # Resize window up, -60 represent pixels
        "$Mod CTRL, down,  resizeactive,  0  60" # Resize window down +60 represent pixels

        # SWITCHING WORKSPACES
        "$Mod, 1, workspace, 1"
        "$Mod, 2, workspace, 2"
        "$Mod, 3, workspace, 3"
        "$Mod, 4, workspace, 4"
        "$Mod, 5, workspace, 5"
        "$Mod, 6, workspace, 6"
        "$Mod, 7, workspace, 7"
        "$Mod, 8, workspace, 8"
        "$Mod, 9, workspace, 9"
        "$Mod, 0, workspace, 10"

        # MOVING WINDOWS TO WORKSPACES
        "$Mod SHIFT, 1, movetoworkspacesilent, 1"
        "$Mod SHIFT, 2, movetoworkspacesilent, 2"
        "$Mod SHIFT, 3, movetoworkspacesilent, 3"
        "$Mod SHIFT, 4, movetoworkspacesilent, 4"
        "$Mod SHIFT, 5, movetoworkspacesilent, 5"
        "$Mod SHIFT, 6, movetoworkspacesilent, 6"
        "$Mod SHIFT, 7, movetoworkspacesilent, 7"
        "$Mod SHIFT, 8, movetoworkspacesilent, 8"
        "$Mod SHIFT, 9, movetoworkspacesilent, 9"
        "$Mod SHIFT, 0, movetoworkspacesilent, 10"

        # SCRATCHPAD IS A SPECIAL HIDDEN WORKSPACE FOR TEMPORARY WINDOWS
        # They overlay other windows and can be toggled visible/invisible
        "$Mod,       S, togglespecialworkspace,  magic" # Toggle scratchpad visibility
        "$Mod SHIFT, S, movetoworkspace, special:magic" # Move window to scratchpad
      ] ++ (vars.hyprlandExtraBinds or [ ]);

      # MOVE/RESIZE WINDOWS WITH MAINMOD + LMB/RMB AND DRAGGING
      bindm = [
        "$Mod, mouse:272, movewindow" # 272 is left mouse button
        "$Mod, mouse:273, resizewindow" # 273 is right mouse button
      ];

      # LAPTOP MULTIMEDIA KEYS FOR VOLUME AND LCD BRIGHTNESS
      bindel = [
        ",XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" # Increase volume by 5%
        ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" # Decrease volume by 5%
        ",XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" # Toggle mute
        ",XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" # Toggle mic mute
        "$Mod, bracketright, exec, brightnessctl s 10%+" # Increase screen brightness by 10%
        "$Mod, bracketleft,  exec, brightnessctl s 10%-" # Decrease screen brightness by 10%
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
