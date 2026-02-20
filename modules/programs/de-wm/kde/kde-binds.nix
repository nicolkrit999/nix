{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:
    let
      spectacleCmd = "${pkgs.kdePackages.spectacle}/bin/spectacle";
    in
    {
      # ---------------------------------------------------------
      # 2. HOTKEYS (Custom Commands)
      # ---------------------------------------------------------
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
          command = "${pkgs.${constants.browser}}/bin/${constants.browser}";
        };
        "launch-editor" = {
          key = "Meta+C";
          command =
            if
              builtins.elem constants.editor [
                "neovim"
                "nvim"
                "nano"
                "vim"
                "helix"
              ]
            then
              "${constants.term} -e ${constants.editor}"
            else
              "${constants.editor}";
        };
        "launch-terminal" = {
          key = "Meta+Return";
          command = constants.term;
        };
        "launch-filemanager" = {
          key = "Meta+F";
          command =
            if
              builtins.elem constants.fileManager [
                "yazi"
                "ranger"
                "lf"
                "nnn"
              ]
            then
              "${constants.term} -e ${constants.fileManager}"
            else
              "${constants.fileManager}";
        };
      }
      // cfg.extraBinds;

      # ---------------------------------------------------------
      # 3. GLOBAL SHORTCUTS
      # ---------------------------------------------------------
      programs.plasma.shortcuts = lib.mkForce {

        # --- UNBIND DEFAULTS ---
        # Unbind conflicting keys
        "plasmashell"."manage activities" = "none";
        "kwin"."Show Activity Switcher" = "none";
        "kwin"."Switch to Next Keyboard Layout" = "none";

        # Unbind standard Spectacle
        "org.kde.spectacle.desktop" = {
          "ActiveWindowScreenShot" = "none";
          "FullScreenScreenShot" = "none";
          "RectangularRegionScreenShot" = "none";
          "_launch" = "none";
          # Keep recording (Meta+Ctrl)
          "RecordRegion" = "Meta+Ctrl+7";
          "RecordScreen" = "Meta+Ctrl+8";
          "RecordWindow" = "Meta+Ctrl+9";
        };

        # Session
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
