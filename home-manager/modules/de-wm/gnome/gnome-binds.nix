{
  pkgs,
  lib,
  vars,
  ...
}:
let

  screenshotScript = pkgs.writeShellScript "launch-screenshot" ''
    # Create the filename with timestamp
    # Note: vars.screenshots contains "$HOME", so the shell will expand it correctly
    FILENAME="${vars.screenshots}/Screenshot_$(date +%F_%H-%M-%S).png"

    mkdir -p "${vars.screenshots}"

    ${pkgs.gnome-screenshot}/bin/gnome-screenshot --file="$FILENAME"

    ${pkgs.libnotify}/bin/notify-send "Screenshot Saved" "Saved to $FILENAME" -i camera-photo
  '';

  customKeyPath =
    i: "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}";

  customBindings = [
    {
      name = "Launch Terminal";
      command = vars.term;
      binding = "<Super>Return";
    }
    {
      name = "Launch ${vars.browser}";
      command = "${pkgs.${vars.browser}}/bin/${vars.browser}";
      binding = "<Super>b";
    }
    {
      name = "Launch File Manager";
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
      binding = "<Super>f";
    }
    {
      name = "Launch editor";
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
  ++ (vars.gnomeExtraBinds or [ ]);

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

  config = lib.mkIf (vars.gnome or false) {
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
