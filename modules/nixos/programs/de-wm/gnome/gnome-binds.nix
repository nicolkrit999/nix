{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.gnome";
  home.ifEnabled =
    { cfg
    , myconfig
    , parent
    , ...
    }:
    let
      screenshotScript = pkgs.writeShellScript "launch-screenshot" ''
        FILENAME="${myconfig.constants.screenshots}/Screenshot_$(date +%F_%H-%M-%S).png"
        mkdir -p "${myconfig.constants.screenshots}"
        ${pkgs.gnome-screenshot}/bin/gnome-screenshot --file="$FILENAME"
        ${pkgs.libnotify}/bin/notify-send "Screenshot Saved" "Saved to $FILENAME" -i camera-photo
      '';

      vicinaeEnabled = parent.vicinae.enable or true;
      termApps = myconfig.constants.terminalApps;
      inTerminal = app: "${myconfig.constants.terminal.name} -e ${app}";
      launchCommand = app: if builtins.elem app termApps then inTerminal app else app;

      keybindingsPath = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings";

      customBindings =
        lib.optionals vicinaeEnabled [
          {
            name = "Vicinae: Application Launcher";
            command = "vicinae toggle";
            binding = "<Super>a";
          }
          {
            name = "Vicinae: Clipboard";
            command = "vicinae vicinae://launch/clipboard/history";
            binding = "<Super>v";
          }
          {
            name = "Vicinae: Emoji Picker";
            command = "vicinae vicinae://launch/core/search-emojis";
            binding = "<Super>period";
          }
        ]
        ++ [
          {
            name = "Launch Terminal";
            command = myconfig.constants.terminal.name;
            binding = "<Super>Return";
          }
          {
            name = "Launch ${myconfig.constants.browser}";
            command = myconfig.constants.browser;
            binding = "<Super>b";
          }
          {
            name = "Launch File Manager";
            command = launchCommand myconfig.constants.fileManager;
            binding = "<Super>f";
          }
          {
            name = "Launch editor";
            command = launchCommand myconfig.constants.editor;
            binding = "<Super>c";
          }
          {
            name = "Take Screenshot (Native)";
            command = "${screenshotScript}";
            binding = "Print";
          }
        ]
        ++ cfg.extraBinds;

      customKeyNames = lib.imap0 (i: _: "${keybindingsPath}/custom${toString i}") customBindings;

      dconfList = map (path: "/${path}/") customKeyNames;

      dconfSettings = lib.listToAttrs (
        lib.zipListsWith
          (path: b: lib.nameValuePair path { inherit (b) name command binding; })
          customKeyNames
          customBindings
      );

    in
    {
      dconf.settings = {
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = dconfList;
          screensaver = [ "<Super>Delete" ];
          logout = [ "<Super><Shift>Delete" ];
          screenshot = [ ];
        };

        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super><Shift>c" ];
        };

        "org/gnome/shell/keybindings" = {
          toggle-overview = [ "<Super>w" ];
          toggle-application-view = [ ];
        };
      }
      // dconfSettings;
    };
}
