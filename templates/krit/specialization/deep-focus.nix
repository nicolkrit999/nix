{ delib
, lib
, config
, ...
}:
let

  termApps = [
    "nvim"
    "neovim"
    "vim"
    "nano"
    "hx"
    "helix"
    "yazi"
    "ranger"
    "lf"
    "nnn"
  ];
in
delib.host {
  name = "nixos-desktop";

  nixos = {
    nixpkgs.config.allowUnfree = true;
    specialisation.deep-focus.configuration = {
      system.nixos.tags = [ "deep-focus" ];
      # Take default chosen apps but change their workspace
      myconfig.programs.hyprland.execOnce = lib.mkForce (
        let
          c = config.myconfig.constants;
          smartLaunch =
            app: if builtins.elem app termApps then "${c.terminal} --class ${app} -e ${app}" else app;
        in
        [
          "[workspace 1 silent] ${c.browser}"
          "[workspace 2 silent] ${smartLaunch c.editor}"
          "[workspace 3 silent] ${smartLaunch c.fileManager}"
          "[workspace 4 silent] ${c.terminal}"

          "swaync-client -d -b"
          "gsettings set org.gnome.desktop.notifications show-banners false"
        ]
      );

      myconfig.programs.hyprland.windowRules = lib.mkAfter (
        let
          c = config.myconfig.constants;
        in
        [
          "workspace 1, class:^(${c.browser})$"
          "workspace 2, class:^(${c.editor})$"
          "workspace 3, class:^(${c.fileManager})$"
          "workspace 4, class:^(${c.terminal})$"
        ]
      );

    };
  };
}
