{ lib }:
let
  cmdLib = import ./cmd.nix { inherit lib; };

  allowWhenLockedKeys = [
    "XF86AudioRaiseVolume"
    "XF86AudioLowerVolume"
    "XF86AudioMute"
    "XF86AudioMicMute"
    "XF86MonBrightnessUp"
    "XF86MonBrightnessDown"
    "XF86KbdBrightnessUp"
    "XF86KbdBrightnessDown"
  ];
in
{ constants, shell }:
let
  spawnApp =
    app:
    if builtins.elem app constants.terminalApps
    then [ constants.terminal.name "-e" app ]
    else [ app ];

  s = field: shell.${field} or null;
  spawn = v: { action.spawn = cmdLib.asArgv v; };
  optBind = field: key: lib.optionalAttrs (s field != null) { ${key} = spawn (s field); };

  mediaBindsRaw =
    lib.optionalAttrs (s "volumeUp" != null) { "XF86AudioRaiseVolume" = spawn (s "volumeUp"); }
    // lib.optionalAttrs (s "volumeDown" != null) { "XF86AudioLowerVolume" = spawn (s "volumeDown"); }
    // lib.optionalAttrs (s "volumeMute" != null) { "XF86AudioMute" = spawn (s "volumeMute"); }
    // lib.optionalAttrs (s "micMute" != null) { "XF86AudioMicMute" = spawn (s "micMute"); }
    // lib.optionalAttrs (s "brightnessUp" != null) {
      "Mod+BracketRight" = spawn (s "brightnessUp");
      "XF86MonBrightnessUp" = spawn (s "brightnessUp");
    }
    // lib.optionalAttrs (s "brightnessDown" != null) {
      "Mod+BracketLeft" = spawn (s "brightnessDown");
      "XF86MonBrightnessDown" = spawn (s "brightnessDown");
    }
    // optBind "kbdBrightnessUp" "XF86KbdBrightnessUp"
    // optBind "kbdBrightnessDown" "XF86KbdBrightnessDown"
    // optBind "mediaPlay" "XF86AudioPlay"
    // optBind "mediaPlay" "XF86AudioPause"
    // optBind "mediaNext" "XF86AudioNext"
    // optBind "mediaPrev" "XF86AudioPrev"
    // optBind "mediaStop" "XF86AudioStop"
    // optBind "capsLock" "Caps_Lock";

  mediaBinds = builtins.mapAttrs
    (key: bind:
      if builtins.elem key allowWhenLockedKeys
      then bind // { allow-when-locked = true; }
      else bind)
    mediaBindsRaw;

  screenshotBinds =
    if s "screenshotScreen" == null then {
      "Print".action.screenshot-screen = [ ];
      "Mod+Ctrl+3".action.screenshot-screen = [ ];
      "Mod+Ctrl+4".action.screenshot = [ ];
    } else
      lib.optionalAttrs ((s "printKey") != false) { "Print" = spawn (s "screenshotScreen"); }
      // { "Mod+Ctrl+3" = spawn (s "screenshotScreen"); }
      // optBind "screenshotArea" "Mod+Ctrl+4";

  baseBinds = {
    "Mod+Return".action.spawn = [ constants.terminal.name ];
    "Mod+B".action.spawn = [ constants.browser ];
    "Mod+F".action.spawn = spawnApp constants.fileManager;
    "Mod+C".action.spawn = spawnApp constants.editor;

    "Mod+Shift+C".action.close-window = [ ];
    "Mod+M".action.fullscreen-window = [ ];
    "Mod+Space".action.toggle-window-floating = [ ];
    "Mod+Delete" = spawn (s "lock");
    "Mod+Shift+Delete".action.quit = {
      skip-confirmation = true;
    };

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

    "Mod+Ctrl+Right".action.focus-monitor-right = [ ];
    "Mod+Ctrl+L".action.focus-monitor-right = [ ];
    "Mod+Ctrl+Left".action.focus-monitor-left = [ ];
    "Mod+Ctrl+H".action.focus-monitor-left = [ ];
    "Mod+Alt+Right".action.move-window-to-monitor-right = [ ];
    "Mod+Alt+L".action.move-window-to-monitor-right = [ ];
    "Mod+Alt+Left".action.move-window-to-monitor-left = [ ];
    "Mod+Alt+H".action.move-window-to-monitor-left = [ ];

    "Mod+O".action.toggle-overview = [ ];
  }
  // optBind "menu" "Mod+Shift+A"
  // optBind "notifications" "Mod+N"
  // optBind "picker" "Mod+Shift+P"
  // optBind "reload" "Mod+Shift+R"
  // screenshotBinds;

  launcherBinds =
    optBind "launcher" "Mod+A"
    // optBind "emoji" "Mod+Period"
    // optBind "clipboard" "Mod+V";
in
baseBinds // launcherBinds // mediaBinds
