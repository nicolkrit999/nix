{ delib
, lib
, pkgs
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
      binds = import ../binds-lib/niri.nix { inherit lib; };

      noctaliaPkg = pkgs.noctalia;

      vicinaeEnabled = parent.vicinae.enable or true;
      swayosdEnabled = parent.swayosd.enable or true;

      noctaliaActiveOnNiri =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnNiri or false);

      plainMedia = noctaliaActiveOnNiri || !swayosdEnabled;
      vicinaeCommand = [ "vicinae" "toggle" ];

      shell = {
        launcher = if vicinaeEnabled then vicinaeCommand else null;
        menu =
          if noctaliaActiveOnNiri then
            [ "sh" "-c" "${lib.getExe noctaliaPkg} msg panel-toggle launcher" ]
          else if vicinaeEnabled then
            vicinaeCommand
          else
            [ "true" ];
        lock =
          if noctaliaActiveOnNiri then
            [ "sh" "-c" "${lib.getExe noctaliaPkg} msg session lock" ]
          else
            [ "loginctl" "lock-session" ];
        emoji = if vicinaeEnabled then [ "vicinae" "vicinae://launch/core/search-emojis" ] else null;
        clipboard = if vicinaeEnabled then [ "vicinae" "vicinae://launch/clipboard/history" ] else null;
        picker = [ "hyprpicker" "-an" ];
        reload = [ "niri" "msg" "action" "load-config-file" ];
        notifications = [ "swaync-client" "-t" "-sw" ];
        screenshotScreen = null;
        screenshotArea = null;
        volumeUp = if plainMedia then [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ] else [ "swayosd-client" "--output-volume" "raise" ];
        volumeDown = if plainMedia then [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ] else [ "swayosd-client" "--output-volume" "lower" ];
        volumeMute = if plainMedia then [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ] else [ "swayosd-client" "--output-volume" "mute-toggle" ];
        micMute = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
        brightnessUp = if plainMedia then [ "brightnessctl" "set" "5%+" ] else [ "swayosd-client" "--brightness" "raise" ];
        brightnessDown = if plainMedia then [ "brightnessctl" "set" "5%-" ] else [ "swayosd-client" "--brightness" "lower" ];
        kbdBrightnessUp = [ "brightnessctl" "--device=*::kbd_backlight" "set" "+1" ];
        kbdBrightnessDown = [ "brightnessctl" "--device=*::kbd_backlight" "set" "1-" ];
        mediaPlay = if plainMedia then [ "playerctl" "play-pause" ] else [ "swayosd-client" "--playerctl" "play-pause" ];
        mediaNext = if plainMedia then [ "playerctl" "next" ] else [ "swayosd-client" "--playerctl" "next" ];
        mediaPrev = if plainMedia then [ "playerctl" "previous" ] else [ "swayosd-client" "--playerctl" "previous" ];
        mediaStop = if plainMedia then [ "playerctl" "stop" ] else [ "swayosd-client" "--playerctl" "stop" ];
        capsLock = if plainMedia then null else [ "swayosd-client" "--caps-lock" ];
      };
    in
    {
      programs.niri.settings.binds =
        binds { inherit (myconfig) constants; inherit shell; } // cfg.extraBinds;
    };
}
