{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "programs.niri";

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      spawnApp =
        app:
        if
          builtins.elem app [
            "nvim"
            "yazi"
            "ranger"
          ]

        then
          [
            "${myconfig.constants.terminal.name}"
            "-e"
            app
          ]
        else
          [ app ];

      noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

      vicinaeCommand = [ "vicinae" "toggle" ];

      # Three-way active check: only dispatch to noctalia's IPC if noctalia
      # is actually running on Niri (master + per-WM + wm.enable).
      noctaliaActiveOnNiri =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnNiri or false)
        && (parent.niri.enable or false);

      # No fallback by design: super+shift+a is the *shell* launcher. If noctalia
      # isn't active on Niri, the bind is a no-op (use super+a → vicinae instead).
      shellLauncherCommand =
        if noctaliaActiveOnNiri then
          [
            "sh"
            "-c"
            "${noctaliaPkg}/bin/noctalia-shell ipc call launcher toggle"
          ]
        else
          [ "true" ];

      # Direct dispatch — bypasses the universalLock chain (loginctl → hypridle
      # → universalLock → pgrep noctalia → hyprlock fallback) which silently
      # falls through to hyprlock when noctalia isn't pgrep-matched.
      shellLockCommand =
        if noctaliaActiveOnNiri then
          [
            "sh"
            "-c"
            "${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock"
          ]
        else
          [ "loginctl" "lock-session" ];

      # Media / brightness keys: when noctalia is active it shows its own OSD
      # via PipeWire / brightness DBus signals. Routing through swayosd-client
      # would pop swayosd's OSD instead and noctalia would never see the event.
      mediaBinds =
        if noctaliaActiveOnNiri then {
          "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ];
          "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
          "XF86AudioMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
          "XF86AudioMicMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
          "Mod+BracketRight".action.spawn = [ "brightnessctl" "set" "5%+" ];
          "Mod+BracketLeft".action.spawn = [ "brightnessctl" "set" "5%-" ];
          "XF86MonBrightnessUp".action.spawn = [ "brightnessctl" "set" "5%+" ];
          "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "5%-" ];
          "XF86KbdBrightnessUp".action.spawn = [ "brightnessctl" "--device=*::kbd_backlight" "set" "+10%" ];
          "XF86KbdBrightnessDown".action.spawn = [ "brightnessctl" "--device=*::kbd_backlight" "set" "10%-" ];
          "XF86AudioPlay".action.spawn = [ "playerctl" "play-pause" ];
          "XF86AudioPause".action.spawn = [ "playerctl" "play-pause" ];
          "XF86AudioNext".action.spawn = [ "playerctl" "next" ];
          "XF86AudioPrev".action.spawn = [ "playerctl" "previous" ];
          "XF86AudioStop".action.spawn = [ "playerctl" "stop" ];
        } else {
          "XF86AudioRaiseVolume".action.spawn = [ "swayosd-client" "--output-volume" "raise" ];
          "XF86AudioLowerVolume".action.spawn = [ "swayosd-client" "--output-volume" "lower" ];
          "XF86AudioMute".action.spawn = [ "swayosd-client" "--output-volume" "mute-toggle" ];
          "XF86AudioMicMute".action.spawn = [ "swayosd-client" "--input-volume" "mute-toggle" ];
          "Mod+BracketRight".action.spawn = [ "swayosd-client" "--brightness" "raise" ];
          "Mod+BracketLeft".action.spawn = [ "swayosd-client" "--brightness" "lower" ];
          "XF86MonBrightnessUp".action.spawn = [ "swayosd-client" "--brightness" "raise" ];
          "XF86MonBrightnessDown".action.spawn = [ "swayosd-client" "--brightness" "lower" ];
          "XF86KbdBrightnessUp".action.spawn = [ "swayosd-client" "--keyboard-brightness" "raise" ];
          "XF86KbdBrightnessDown".action.spawn = [ "swayosd-client" "--keyboard-brightness" "lower" ];
          "XF86AudioPlay".action.spawn = [ "swayosd-client" "--playerctl" "play-pause" ];
          "XF86AudioPause".action.spawn = [ "swayosd-client" "--playerctl" "play-pause" ];
          "XF86AudioNext".action.spawn = [ "swayosd-client" "--playerctl" "next" ];
          "XF86AudioPrev".action.spawn = [ "swayosd-client" "--playerctl" "previous" ];
          "XF86AudioStop".action.spawn = [ "swayosd-client" "--playerctl" "stop" ];
          "Caps_Lock".action.spawn = [ "swayosd-client" "--caps-lock" ];
        };

      baseBinds = {
        # -----------------------------------------------------------------------
        # 🚀 APPLICATIONS
        # -----------------------------------------------------------------------
        "Mod+Return".action.spawn = [ "${myconfig.constants.terminal.name}" ];
        "Mod+A".action.spawn = vicinaeCommand;
        "Mod+Shift+A".action.spawn = shellLauncherCommand;
        "Mod+B".action.spawn = [ "${myconfig.constants.browser}" ];
        "Mod+F".action.spawn = spawnApp myconfig.constants.fileManager;
        "Mod+C".action.spawn = spawnApp myconfig.constants.editor;

        # -----------------------------------------------------------------------
        # 🪟 WINDOW MANAGEMENT
        # -----------------------------------------------------------------------
        "Mod+Shift+C".action.close-window = [ ];
        "Mod+M".action.fullscreen-window = [ ];
        "Mod+Space".action.toggle-window-floating = [ ];
        "Mod+Delete".action.spawn = shellLockCommand;
        "Mod+Shift+Delete".action.quit = {
          skip-confirmation = true;
        };

        # -----------------------------------------------------------------------
        # ↔️ MOVEMENT
        # -----------------------------------------------------------------------
        "Mod+Left".action.focus-column-left = [ ];
        "Mod+H".action.focus-column-left = [ ];
        "Mod+Right".action.focus-column-right = [ ];
        "Mod+L".action.focus-column-right = [ ];
        "Mod+Up".action.focus-window-up = [ ];
        "Mod+K".action.focus-window-up = [ ];
        "Mod+Down".action.focus-window-down = [ ];
        "Mod+J".action.focus-window-down = [ ];
        "Mod+Shift+Left".action.move-column-left = [ ];
        "Mod+Shift+H".action.move-column-left = [ ];
        "Mod+Shift+Right".action.move-column-right = [ ];
        "Mod+Shift+L".action.move-column-right = [ ];
        "Mod+Shift+Up".action.move-window-up = [ ];
        "Mod+Shift+K".action.move-window-up = [ ];
        "Mod+Shift+Down".action.move-window-down = [ ];
        "Mod+Shift+J".action.move-window-down = [ ];

        # -----------------------------------------------------------------------
        # 🔢 WORKSPACES (1-9)
        # -----------------------------------------------------------------------
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        "Mod+Shift+1".action.move-window-to-workspace = 1;
        "Mod+Shift+2".action.move-window-to-workspace = 2;
        "Mod+Shift+3".action.move-window-to-workspace = 3;
        "Mod+Shift+4".action.move-window-to-workspace = 4;
        "Mod+Shift+5".action.move-window-to-workspace = 5;
        "Mod+Shift+6".action.move-window-to-workspace = 6;
        "Mod+Shift+7".action.move-window-to-workspace = 7;
        "Mod+Shift+8".action.move-window-to-workspace = 8;
        "Mod+Shift+9".action.move-window-to-workspace = 9;

        # -----------------------------------------------------------------------
        # 🔔 NOTIFICATIONS
        # -----------------------------------------------------------------------
        "Mod+N".action.spawn = [
          "swaync-client"
          "-t"
          "-sw"
        ];

        # -----------------------------------------------------------------------
        # 📸 SCREENSHOTS
        # -----------------------------------------------------------------------
        "Print".action.screenshot-screen = [ ];
        "Mod+Ctrl+3".action.screenshot-screen = [ ];
        "Mod+Ctrl+4".action.screenshot = [ ];

        # -----------------------------------------------------------------------
        # 🛠️ UTILITIES
        # -----------------------------------------------------------------------
        # TODO: re-enable emoji bind once we figure out the correct Vicinae deeplink / extension.
        # "Mod+Period".action.spawn = [ "walker" "-m" "symbols" ]; # Emoji picker (walker — kept commented for reference)
        "Mod+Shift+P".action.spawn = [
          "hyprpicker"
          "-an"
        ];
        "Mod+V".action.spawn = [
          "vicinae"
          "vicinae://launch/clipboard/history"
        ];
        "Mod+O".action.toggle-overview = [ ];
        "Mod+Shift+R".action.spawn = [
          "niri"
          "msg"
          "action"
          "reload-config"
        ];
      };
    in
    {
      programs.niri.settings.binds = baseBinds // mediaBinds // (cfg.extraBinds or { });
    };
}
