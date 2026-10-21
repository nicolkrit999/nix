{ delib, pkgs, ... }:
delib.module {
  name = "programs.ranger";
  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }:
    let
      terminal = myconfig.constants.terminal.name;
    in
    {
      home.packages = with pkgs; [
        ffmpegthumbnailer
        ueberzugpp
      ];

      programs.ranger = {
        enable = true;
        settings = {
          preview_images = true;
          preview_images_method =
            if
              builtins.elem terminal [
                "kitty"
                "ghostty"
                "konsole"
                "wezterm"
                "rio"
              ]
            then
              "kitty"
            else if terminal == "iterm2" then
              "iterm2"
            else if
              builtins.elem terminal [
                "foot"
                "blackbox"
              ]
            then
              "sixel"
            else
              "ueberzug"; # kitty protocol, iTerm2 inline images, sixel, or ueberzug as fallback
        };
      };
    };
}
