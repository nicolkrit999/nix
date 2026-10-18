{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg
    , myconfig
    , parent
    , ...
    }:
    let
      vicinaeEnabled = parent.vicinae.enable or true;
      termApps = myconfig.constants.terminalApps;
      inTerminal = app: "${myconfig.constants.terminal.name} -e ${app}";
      vicinaeCommands = lib.optionalAttrs vicinaeEnabled {
        "vicinae-toggle" = {
          name = "Vicinae: Application Launcher";
          key = "Meta+A";
          command = "vicinae toggle";
        };
        "vicinae-clipboard" = {
          name = "Vicinae: Clipboard";
          key = "Meta+V";
          command = "vicinae vicinae://launch/clipboard/history";
        };
        "vicinae-emoji" = {
          name = "Vicinae: Emoji Picker";
          key = "Meta+.";
          command = "vicinae vicinae://launch/core/search-emojis";
        };
      };
      spectacleCmd = lib.getExe' pkgs.kdePackages.spectacle "spectacle";
    in
    {
      programs.plasma.hotkeys.commands = {
        "spectacle-print" = {
          name = "Spectacle: Print Screen (Fullscreen)";
          key = "Print";
          command = "${spectacleCmd} -f";
        };
        "spectacle-open" = {
          name = "Spectacle: Open";
          key = "Meta+Ctrl+0";
          command = spectacleCmd;
        };
        "spectacle-active" = {
          name = "Spectacle: Active Window";
          key = "Meta+Ctrl+2";
          command = "${spectacleCmd} -a";
        };
        "spectacle-fullscreen" = {
          name = "Spectacle: Full Screen";
          key = "Meta+Ctrl+3";
          command = "${spectacleCmd} -f";
        };
        "spectacle-region" = {
          name = "Spectacle: Region";
          key = "Meta+Ctrl+4";
          command = "${spectacleCmd} -r";
        };
        "spectacle-monitor" = {
          name = "Spectacle: Current Monitor";
          key = "Meta+Ctrl+5";
          command = "${spectacleCmd} -m";
        };
        "spectacle-under-cursor" = {
          name = "Spectacle: Window Under Cursor";
          key = "Meta+Ctrl+6";
          command = "${spectacleCmd} -u";
        };

        "launch-browser" = {
          name = "Launch ${myconfig.constants.browser}";
          key = "Meta+B";
          command = myconfig.constants.browser;
        };
        "launch-editor" = {
          key = "Meta+C";
          command =
            if builtins.elem myconfig.constants.editor termApps then
              inTerminal myconfig.constants.editor
            else
              myconfig.constants.editor;
        };
        "launch-terminal" = {
          key = "Meta+Return";
          command = myconfig.constants.terminal.name;
        };
        "launch-filemanager" = {
          key = "Meta+F";
          command =
            if builtins.elem myconfig.constants.fileManager termApps then
              inTerminal myconfig.constants.fileManager
            else
              myconfig.constants.fileManager;
        };
      }
      // vicinaeCommands
      // cfg.extraBinds;

      programs.plasma.shortcuts = lib.mkForce {
        # --- UNBIND DEFAULTS ---
        "plasmashell"."manage activities" = "none";
        "kwin"."Show Activity Switcher" = "none";

        "org.kde.spectacle.desktop" = {
          "ActiveWindowScreenShot" = "none";
          "FullScreenScreenShot" = "none";
          "RectangularRegionScreenShot" = "none";
          "_launch" = "none";
          "RecordRegion" = "Meta+Ctrl+7";
          "RecordScreen" = "Meta+Ctrl+8";
          "RecordWindow" = "Meta+Ctrl+9";
        };

        "ksmserver"."Log Out" = "Meta+Shift+Delete";
        "ksmserver"."Lock Session" = "Meta+Delete";

        "powerdevil"."Switch to Balanced" = "none";
        "plasmashell"."show-battery" = "none";

        "org.kde.krunner.desktop"."_launch" = "Meta+Shift+K";
        "kwin"."Window Close" = "Meta+Shift+C";
        "kwin"."Overview" = "Meta+W";
      };
    };
}
