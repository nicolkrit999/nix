{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.mango";
  options =
    with delib;
    moduleOptions {
      extraBinds = listOfOption str [ ];
      extraMouseBinds = listOfOption str [ ];
      extraAxisBinds = listOfOption str [ ];
      extraLayerRules = listOfOption str [ ];
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      binds = import ../binds-lib/mango.nix { inherit lib; };
      mangoPip = import ../binds-lib/mango-pip.nix { inherit pkgs; };

      screenshotsDir = myconfig.constants.screenshots;

      mangoScreenshot = pkgs.writeShellApplication {
        name = "mango-screenshot";
        runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.libnotify pkgs.jq pkgs.coreutils ];
        text = ''
          mkdir -p "${screenshotsDir}"
          stamp=$(date +%Y%m%d-%H%M%S)
          case ''${1:-output} in
            area)
              region=$(slurp) || exit 0
              f="${screenshotsDir}/area-$stamp.png"
              grim -g "$region" "$f"
              ;;
            *)
              out=$(mmsg get all-monitors | jq -r '[.monitors[] | select(.active) | .name][0] // empty')
              f="${screenshotsDir}/screenshot-$stamp.png"
              if [[ -n $out ]]; then grim -o "$out" "$f"; else grim "$f"; fi
              ;;
          esac
          wl-copy < "$f"
          notify-send "Screenshot" "Saved $f"
        '';
      };

      noctaliaPkg = pkgs.noctalia;

      noctaliaActiveOnMango =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnMango or false);

      vicinaeEnabled = parent.vicinae.enable or true;
      swayosdEnabled = parent.swayosd.enable or true;
      plainMedia = noctaliaActiveOnMango || !swayosdEnabled;

      shell = {
        launcher = if vicinaeEnabled then "vicinae toggle" else null;
        menu =
          if noctaliaActiveOnMango then "sh -c '${lib.getExe noctaliaPkg} msg panel-toggle launcher'"
          else if vicinaeEnabled then "vicinae toggle"
          else "true";
        lock =
          if noctaliaActiveOnMango then "sh -c '${lib.getExe noctaliaPkg} msg session lock'"
          else "loginctl lock-session";
        emoji = if vicinaeEnabled then "vicinae vicinae://launch/core/search-emojis" else null;
        clipboard = if vicinaeEnabled then "vicinae vicinae://launch/clipboard/history" else null;
        picker = "hyprpicker -an";
        notifications = "swaync-client -t -sw";
        barReload = "pkill -SIGUSR2 waybar";
        barToggle = "pkill -SIGUSR1 waybar";
        screenshotScreen = "${lib.getExe mangoScreenshot} output";
        screenshotArea = "${lib.getExe mangoScreenshot} area";
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

      binds' = binds {
        inherit shell;
        inherit (myconfig) constants;
        pip = lib.getExe mangoPip;
      };

      tagIds = [ 1 2 3 4 5 6 7 8 9 ];
      tagRules =
        let
          fallback = map (i: "id:${toString i},layout_name:${cfg.defaultLayout}") tagIds;
          perMonitor = lib.concatMap
            (name: map (i: "id:${toString i},monitor_name:^${name}$,layout_name:${cfg.monitorLayouts.${name}}") tagIds)
            (builtins.attrNames cfg.monitorLayouts);
        in
        fallback ++ perMonitor;

      baseLayerRules = [
        "animation_type_open:zoom,layer_name:rofi"
        "animation_type_close:zoom,layer_name:rofi"
        "animation_type_open:zoom,layer_name:vicinae"
        "animation_type_close:zoom,layer_name:vicinae"
      ];
    in
    {
      wayland.windowManager.mango.settings = {
        bind = binds'.bind ++ cfg.extraBinds;
        mousebind = binds'.mousebind ++ cfg.extraMouseBinds;
        axisbind = binds'.axisbind ++ cfg.extraAxisBinds;
        inherit (binds') bindl bindsl gesturebind;
        tag_rule = tagRules;
        layer_rule = baseLayerRules ++ cfg.extraLayerRules;
      };
    };
}
