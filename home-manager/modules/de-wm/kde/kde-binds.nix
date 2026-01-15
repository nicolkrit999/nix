{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  spectacleCmd = "${pkgs.kdePackages.spectacle}/bin/spectacle";

  bemojiScript = pkgs.writeShellScript "launch-bemoji" ''
    ${pkgs.bemoji}/bin/bemoji -cn
  '';
  cliphistScript = pkgs.writeShellScript "launch-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
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
    "launch-wofi" = {
      key = "Meta+A";
      command = "${pkgs.wofi}/bin/wofi --show drun";
    };
    "launch-bemoji" = {
      key = "Meta+Alt+Space";
      command = "${bemojiScript}";
    };
    "launch-cliphist" = {
      key = "Meta+Shift+V";
      command = "${cliphistScript}";
    };
    "launch-browser" = {
      key = "Meta+B";
      command = "${pkgs.${vars.browser}}/bin/${vars.browser}";
    };
    "launch-editor" = {
      key = "Meta+C";
      command =
        if
          builtins.elem vars.editor [
            "neovim"
            "nvim"
            "nano"
            "vim"
            "helix"
          ]
        then
          "${vars.term} -e ${vars.editor}"
        else
          "${vars.editor}";
    };
    "launch-terminal" = {
      key = "Meta+Return";
      command = vars.term;
    };
    "launch-filemanager" = {
      key = "Meta+F";
      command =
        if
          builtins.elem vars.fileManager [
            "yazi"
            "ranger"
            "lf"
            "nnn"
          ]
        then
          "${vars.term} -e ${vars.fileManager}"
        else
          "${vars.fileManager}";
    };
  }
  // (vars.kdeExtraBinds or { });

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
    "ksmserver"."Log Out" = "Meta+Shift+L";
    "ksmserver"."Lock Session" = "Meta+L";

    "powerdevil"."Switch to Balanced" = "none";
    "plasmashell"."show-battery" = "none";

    "org.kde.krunner.desktop"."_launch" = "Meta+Shift+K";
    "kwin"."Window Close" = "Meta+Shift+C";
    "kwin"."Overview" = "Meta+W";
  };

  # Ensure desktop entries are cleared
  xdg.desktopEntries = { };
}
