{
  pkgs,
  lib,
  vars,
  ...
}:
let
  cliphistScript = pkgs.writeShellScript "launch-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
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
      command = "${pkgs.bemoji}/bin/bemoji -cn";
      binding = "<Super>Period";
    }
    {
      name = "Clipboard History";
      command = "${cliphistScript}";
      binding = "<Super>v";
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
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = dconfList;
      screensaver = [ "<Super>Delete" ];
      logout = [ "<Super><Shift>Delete" ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super><Shift>c" ];
    };

    "org/gnome/shell/keybindings" = {
      toggle-overview = [ "<Super>w" ];
    };
  }
  // dconfSettings;
}
