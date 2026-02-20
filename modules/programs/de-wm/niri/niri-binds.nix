{
  delib,
  lib,
  pkgs,
  inputs, # Added inputs here so it can be used in the let block
  config,
  ...
}:
delib.module {
  name = "programs.niri"; # Changed name to match the actual content

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }: # Corrected: added the lambda required by delib
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
            "${myconfig.constants.terminal}"
            "-e"
            app
          ]
        else
          [ app ];

      noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

      walkerCommand = [ "walker" ];

      shellLauncherCommand =
        if (myconfig.constants.niriNoctalia or false) then
          [
            "sh"
            "-c"
            "${noctaliaPkg}/bin/noctalia-shell ipc call launcher toggle"
          ]
        else
          [ "walker" ];
    in
    {

      programs.niri.settings.binds = {
        # The actual configuration goes here

        # -----------------------------------------------------------------------
        # 🚀 APPLICATIONS
        # -----------------------------------------------------------------------
        "Mod+Return".action.spawn = [ "${myconfig.constants.terminal}" ];
        "Mod+A".action.spawn = walkerCommand;
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
        "Mod+Delete".action.spawn = [
          "loginctl"
          "lock-session"
        ];
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
        # 🔈 MEDIA & BRIGHTNESS
        # -----------------------------------------------------------------------
        "XF86AudioRaiseVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "-l"
          "1"
          "@DEFAULT_AUDIO_SINK@"
          "5%+"
        ];
        "XF86AudioLowerVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "5%-"
        ];
        "XF86AudioMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
        "Mod+BracketRight".action.spawn = [
          "brightnessctl"
          "s"
          "10%+"
        ];
        "Mod+BracketLeft".action.spawn = [
          "brightnessctl"
          "s"
          "10%-"
        ];

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
        "Mod+Period".action.spawn = [
          "walker"
          "-m"
          "emojis"
        ];
        "Mod+Shift+P".action.spawn = [
          "hyprpicker"
          "-an"
        ];
        "Mod+V".action.spawn = [
          "walker"
          "-m"
          "clipboard"
        ];
        "Mod+O".action.toggle-overview = [ ];
        "Mod+Shift+R".action.spawn = [
          "niri"
          "msg"
          "action"
          "reload-config"
        ];
      };
    };
}
