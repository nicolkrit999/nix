{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  # 1. PATHS & SCRIPTS
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

    # --- OTHER APPS (Working) ---
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
    "launch-firefox" = {
      key = "Meta+B"; # TODO: make it declarative
      command = "${pkgs.firefox}/bin/firefox";
    };
    "launch-chromium" = {
      key = "Meta+Y"; # TODO: Make it declarative
      command = "chromium";
    };
    "launch-vscode" = {
      key = "Meta+C"; # TODO: make it declarative
      command = "code";
    };
    "launch-terminal" = {
      key = "Meta+Return";
      command = vars.term;
    };
    "launch-filemanager" = {
      key = "Meta+F"; # TODO: Make it declarative
      command = "dolphin";
    };
  };

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
