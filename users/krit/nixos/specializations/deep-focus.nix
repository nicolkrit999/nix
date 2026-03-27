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
delib.module {
  name = "krit.specializations.deep-focus";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;
    specialisation.deep-focus.configuration = {
      system.nixos.tags = [ "deep-focus" ];
      # Take default chosen apps but change their workspace
      myconfig.programs.hyprland.execOnce = lib.mkForce (
        let
          c = config.myconfig.constants;
          term = c.terminal.name or "alacritty";
          smartLaunch =
            app: if builtins.elem app termApps then "${term} --class ${app} -e ${app}" else app;
        in
        [
          "[workspace 1 silent] ${c.browser}"
          "[workspace 2 silent] ${smartLaunch c.editor}"
          "[workspace 3 silent] ${smartLaunch c.fileManager}"
          "[workspace 4 silent] ${term}"

          "swaync-client -d -b"
          "gsettings set org.gnome.desktop.notifications show-banners false"
        ]
      );

      myconfig.programs.hyprland.windowRules = lib.mkAfter (
        let
          c = config.myconfig.constants;
          term = c.terminal.name or "alacritty";
        in
        [
          "workspace 1, class:^(${c.browser})$"
          "workspace 2, class:^(${c.editor})$"
          "workspace 3, class:^(${c.fileManager})$"
          "workspace 4, class:^(${term})$"
        ]
      );
    };
  };
}
