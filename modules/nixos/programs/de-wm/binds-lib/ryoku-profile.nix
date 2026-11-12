{ home }:
{
  launcher = { cmd = "ryoku-shell launcher"; hyprGlobal = "ryoku:launcher"; };
  menu = null;
  lock = "ryoku-shell lock";
  emoji = null;
  clipboard = { cmd = "ryoku-shell clipboard"; hyprGlobal = "ryoku:clipboard"; };
  picker = "hyprpicker -an";
  reload = "ryoku-shell reload";
  notifications = null;
  barReload = null;
  barToggle = null;

  screenshotScreen = "env RYOSHOT_MODE=monitor ryoku-cmd-ryoshot";
  screenshotArea = "ryoku-cmd-ryoshot";
  printKey = false;

  volumeUp = "ryoku-volume up";
  volumeDown = "ryoku-volume down";
  volumeMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  micMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
  brightnessUp = "ryoku-cmd-brightness +5";
  brightnessDown = "ryoku-cmd-brightness -5";
  kbdBrightnessUp = { sh = "brightnessctl --device='*::kbd_backlight' set +1"; };
  kbdBrightnessDown = { sh = "brightnessctl --device='*::kbd_backlight' set 1-"; };
  mediaPlay = "playerctl play-pause";
  mediaNext = "playerctl next";
  mediaPrev = "playerctl previous";
  mediaStop = "playerctl stop";
  capsLock = null;

  workspaceHelper = "${home}/.config/hypr/scripts/ryoku-workspace";
}
