{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.gnome";
  home.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:

    let

      screenshotScript = pkgs.writeShellScript "launch-screenshot" ''
        # Create the filename with timestamp
        # Note: cfg.screenshots contains "$HOME", so the shell will expand it correctly
        FILENAME="${cfg.screenshots}/Screenshot_$(date +%F_%H-%M-%S).png"

        mkdir -p "${cfg.screenshots}"

        ${pkgs.gnome-screenshot}/bin/gnome-screenshot --file="$FILENAME"

        ${pkgs.libnotify}/bin/notify-send "Screenshot Saved" "Saved to $FILENAME" -i camera-photo
      '';

      customKeyPath =
        i: "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}";

      customBindings = [
        {
          name = "Launch Terminal";
          command = constants.term;
          binding = "<Super>Return";
        }
        {
          name = "Launch ${constants.browser}";
          command = "${pkgs.${constants.browser}}/bin/${constants.browser}";
          binding = "<Super>b";
        }
        {
          name = "Launch File Manager";
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
          binding = "<Super>f";
        }
        {
          name = "Launch editor";
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
          binding = "<Super>c";
        }
        {
          name = "Emoji Picker";
          command = "walker -m emojis";
          binding = "<Super>Period";
        }

        {
          name = "Application Launcher";
          command = "walker";
          binding = "<Super>a";
        }

        {
          name = "Clipboard History";
          command = "walker -m clipboard";
          binding = "<Super>v";
        }

        {
          name = "Take Screenshot (Native)";
          command = "${screenshotScript}";
          binding = "Print";
        }

      ]
      ++ (cfg.gnomeExtraBinds or [ ]);

      dconfList = lib.genList (
        i: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}/"
      ) (builtins.length customBindings);

      dconfSettings =
        lib.foldl'
          (
            acc: item:
            let
              index = item.index;
              binding = item.value;
            in
            acc
            // {
              "${customKeyPath index}" = {
                name = binding.name;
                command = binding.command;
                binding = binding.binding;
              };
            }
          )
          { }
          (
            lib.imap0 (i: v: {
              index = i;
              value = v;
            }) customBindings
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
        };
      }
      // dconfSettings;
    };
}
