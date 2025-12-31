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
      name = "Launch Firefox";
      command = "${pkgs.firefox}/bin/firefox"; # TODO change to be declarative
      binding = "<Super>b";
    }
    {
      name = "Launch Chromium";
      command = "chromium"; # TODO change to be declarative
      binding = "<Super>y";
    }
    {
      name = "Launch File Manager";
      command = "dolphin"; # Change to be declarative
      binding = "<Super>f";
    }
    {
      name = "Launch VS Code";
      command = "code"; # TODO Change to be declarative
      binding = "<Super>c";
    }
    {
      name = "Emoji Picker";
      command = "${pkgs.bemoji}/bin/bemoji -cn";
      binding = "<Super><Alt>space";
    }
    {
      name = "Clipboard History";
      command = "${cliphistScript}";
      binding = "<Super><Shift>v";
    }
  ];

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
      screensaver = [ "<Super>l" ];
      logout = [ "<Super><Shift>l" ];
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
