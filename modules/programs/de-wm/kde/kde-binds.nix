# Configure kde keybinds using the community "plasma-manager" flake
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
    , ...
    }:
    let
      spectacleCmd = "${pkgs.kdePackages.spectacle}/bin/spectacle";
    in
    {
      programs.plasma.hotkeys.commands = {
        # --- SPECTACLE (Meta + Ctrl) ---
        "spectacle-open" = {
          name = "Spectacle: Open";
          key = "Meta+Ctrl+0";
          command = "${spectacleCmd}";
        };
        "spectacle-launch" = {
          name = "Spectacle: Launch";
          key = "Meta+Ctrl+1";
          command = "${spectacleCmd}";
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

        # --- OTHER APPS ---
        "launch-walker" = {
          key = "Meta+A";
          command = "walker";
        };

        "launch-emoji" = {
          key = "Meta+.";
          command = "walker -m emojis";
        };
        "launch-clipboard" = {
          key = "Meta+V";
          command = "walker -m clipboard";
        };
        "launch-browser" = {
          key = "Meta+B";
          command = "${pkgs.${myconfig.constants.browser}}/bin/${myconfig.constants.browser}";
        };
        "launch-editor" = {
          key = "Meta+C";
          command =
            if
              builtins.elem myconfig.constants.editor [
                "neovim"
                "nvim"
                "nano"
                "vim"
                "helix"
              ]
            then
              "${myconfig.constants.terminal} -e ${myconfig.constants.editor}"
            else
              "${myconfig.constants.editor}";
        };
        "launch-terminal" = {
          key = "Meta+Return";
          command = myconfig.constants.terminal;
        };
        "launch-filemanager" = {
          key = "Meta+F";
          command =
            if
            # Add more if needed
              builtins.elem myconfig.constants.fileManager [
                "yazi"
                "ranger"
                "lf"
                "nnn"
              ]
            then
              "${myconfig.constants.terminal} -e ${myconfig.constants.fileManager}"
            else
              "${myconfig.constants.fileManager}";
        };
      }
      // cfg.extraBinds;

      programs.plasma.shortcuts = lib.mkForce {
        # --- UNBIND DEFAULTS ---
        "plasmashell"."manage activities" = "none";
        "kwin"."Show Activity Switcher" = "none";
        "kwin"."Switch to Next Keyboard Layout" = "none";

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

      # Ensure desktop entries are cleared
      xdg.desktopEntries = { };
    };
}
