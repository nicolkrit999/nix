{ delib
, lib
, ...
}:
delib.module {
  name = "programs.hyprland";
  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      binds = import ../binds-lib/hyprland.nix { inherit lib; };

      caelestiaActiveOnHyprland = parent.caelestia.enable && parent.caelestia.enableOnHyprland;
      noctaliaActiveOnHyprland = parent.noctalia.enable && parent.noctalia.enableOnHyprland;

      vicinaeEnabled = parent.vicinae.enable or true;
      swayosdEnabled = parent.swayosd.enable or true;

      shellActiveOnHyprland = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;
      plainMedia = shellActiveOnHyprland || !swayosdEnabled;

      shell = {
        launcher = if vicinaeEnabled then "vicinae toggle" else null;
        menu =
          if caelestiaActiveOnHyprland then "caelestiaqs ipc call drawers toggle launcher"
          else if noctaliaActiveOnHyprland then "noctalia msg panel-toggle launcher"
          else if vicinaeEnabled then "vicinae toggle"
          else null;
        lock =
          if caelestiaActiveOnHyprland then "caelestiaqs ipc call lock lock"
          else if noctaliaActiveOnHyprland then "noctalia msg session lock"
          else "loginctl lock-session";
        emoji = if vicinaeEnabled then "vicinae vicinae://launch/core/search-emojis" else null;
        clipboard = if vicinaeEnabled then "vicinae vicinae://launch/clipboard/history" else null;
        picker = "hyprpicker -an";
        reload = "hyprctl reload";
        notifications = "swaync-client -t";
        barReload = "pkill -SIGUSR2 waybar";
        barToggle = "pkill -SIGUSR1 waybar";
        screenshotScreen = "grimblast --notify --freeze copysave output";
        screenshotArea = "grimblast --notify --freeze copysave area";
        volumeUp = if plainMedia then "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" else "swayosd-client --output-volume raise";
        volumeDown = if plainMedia then "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" else "swayosd-client --output-volume lower";
        volumeMute = if plainMedia then "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" else "swayosd-client --output-volume mute-toggle";
        micMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        brightnessUp = if plainMedia then "brightnessctl set 5%+" else "swayosd-client --brightness raise";
        brightnessDown = if plainMedia then "brightnessctl set 5%-" else "swayosd-client --brightness lower";
        kbdBrightnessUp = "brightnessctl --device='*::kbd_backlight' set +1";
        kbdBrightnessDown = "brightnessctl --device='*::kbd_backlight' set 1-";
        mediaPlay = if plainMedia then "playerctl play-pause" else "swayosd-client --playerctl play-pause";
        mediaNext = if plainMedia then "playerctl next" else "swayosd-client --playerctl next";
        mediaPrev = if plainMedia then "playerctl previous" else "swayosd-client --playerctl previous";
        mediaStop = if plainMedia then "playerctl stop" else "swayosd-client --playerctl stop";
        capsLock = if plainMedia then null else "swayosd-client --caps-lock";
      };
    in
    {
      wayland.windowManager.hyprland.settings.bind =
        binds { inherit (myconfig) constants; inherit shell; } ++ cfg.extraBinds;
    };
}
