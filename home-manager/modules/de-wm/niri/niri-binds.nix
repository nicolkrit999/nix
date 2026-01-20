{ pkgs, lib, inputs, vars, ... }:
let
  spawnApp = app:
    if builtins.elem app [ "nvim" "yazi" "ranger" ] then [
      "${vars.term}"
      "-e"
      app
    ] else
      [ app ];

  noctaliaPkg =
    inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

  launcherCommand = if (vars.niriNoctalia or false) then [
    "sh"
    "-c"
    "${noctaliaPkg}/bin/noctalia-shell ipc call launcher toggle"
  ] else [
    "wofi"
    "--show"
    "drun"
  ];
in {
  config = lib.mkIf (vars.niri or false) {
    programs.niri.settings.binds = {
      # -----------------------------------------------------------------------
      # 🚀 APPLICATIONS
      # -----------------------------------------------------------------------
      # Terminal
      "Mod+Return".action.spawn = [ "${vars.term}" ];

      # Launcher
      "Mod+A".action.spawn = launcherCommand;

      # Browser
      "Mod+B".action.spawn = [ "${vars.browser}" ];

      # File Manager
      "Mod+F".action.spawn = spawnApp vars.fileManager;

      # Editor
      "Mod+C".action.spawn = spawnApp vars.editor;

      # -----------------------------------------------------------------------
      # 🪟 WINDOW MANAGEMENT
      # -----------------------------------------------------------------------
      "Mod+Shift+C".action.close-window = [ ];
      "Mod+M".action.fullscreen-window = [ ];
      "Mod+Space".action.toggle-window-floating = [ ];

      "Mod+Delete".action.spawn = [ "loginctl" "lock-session" ];
      "Mod+Shift+Delete".action.quit = { skip-confirmation = true; };
      # -----------------------------------------------------------------------
      # ↔️ MOVEMENT (Hyprland Translation)
      # -----------------------------------------------------------------------
      # Focus
      "Mod+Left".action.focus-column-left = [ ];
      "Mod+H".action.focus-column-left = [ ]; # Alternative

      "Mod+Right".action.focus-column-right = [ ];
      "Mod+L".action.focus-column-right = [ ]; # Alternative

      "Mod+Up".action.focus-window-up = [ ];
      "Mod+K".action.focus-window-up = [ ]; # Alternative

      "Mod+Down".action.focus-window-down = [ ];
      "Mod+J".action.focus-window-down = [ ]; # Alternative

      # Move Windows
      "Mod+Shift+Left".action.move-column-left = [ ];
      "Mod+Shift+H".action.move-column-left = [ ]; # Alternative

      "Mod+Shift+Right".action.move-column-right = [ ];
      "Mod+Shift+L".action.move-column-right = [ ]; # Alternative

      "Mod+Shift+Up".action.move-window-up = [ ];
      "Mod+Shift+K".action.move-window-up = [ ]; # Alternative

      "Mod+Shift+Down".action.move-window-down = [ ];
      "Mod+Shift+J".action.move-window-down = [ ]; # Alternative

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

      # Move Window to Workspace
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
      # 🔈 MEDIA & BRIGHTNESS
      # -----------------------------------------------------------------------
      "XF86AudioRaiseVolume".action.spawn =
        [ "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+" ];
      "XF86AudioLowerVolume".action.spawn =
        [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
      "XF86AudioMute".action.spawn =
        [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];

      "Mod+BracketRight".action.spawn = [ "brightnessctl" "s" "10%+" ];
      "Mod+BracketLeft".action.spawn = [ "brightnessctl" "s" "10%-" ];

      # -----------------------------------------------------------------------
      # 🔔 NOTIFICATIONS (SwayNC)
      # -----------------------------------------------------------------------
      # Toggle Notification Center
      "Mod+N".action.spawn = [ "swaync-client" "-t" "-sw" ];

      # -----------------------------------------------------------------------
      # 📸 SCREENSHOTS
      # -----------------------------------------------------------------------
      # Fullscreen
      "Mod+Ctrl+3".action.spawn = [
        "bash"
        "-c"
        ''
          file="$HOME/Pictures/Screenshots/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"
          mkdir -p "$(dirname "$file")"
          grim "$file"
          wl-copy < "$file"
          notify-send "Screenshot" "Saved to $file and copied to clipboard"
        ''
      ];

      # Area Selection (Save to Pictures + Copy to Clipboard)
      "Mod+Ctrl+4".action.spawn = [
        "bash"
        "-c"
        ''
          file="$HOME/Pictures/Screenshots/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"
          mkdir -p "$(dirname "$file")"
          slurp | grim -g - "$file"
          wl-copy < "$file"
          notify-send "Screenshot" "Saved to $file and copied to clipboard"
        ''
      ];

      # -----------------------------------------------------------------------
      # 🛠️ UTILITIES
      # -----------------------------------------------------------------------
      "Mod+Period".action.spawn = [ "bemoji" "-cn" ]; # Emoji
      "Mod+Shift+P".action.spawn = [ "hyprpicker" "-an" ]; # Color Picker
      "Mod+V".action.spawn = [
        "bash"
        "-c"
        "${pkgs.cliphist}/bin/cliphist list | wofi --dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy"
      ]; # Clipboard History
      "Mod+O".action.toggle-overview = [ ]; # Window Overview

      "Mod+Shift+R".action.spawn =
        [ "niri" "msg" "action" "reload-config" ]; # Reload
    };
  };
}
