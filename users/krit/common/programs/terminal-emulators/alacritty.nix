{ delib
, lib
, pkgs
, config
, ...
}:
delib.module {
  name = "krit.programs.alacritty";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.programs.alacritty.enable = true;

  home.ifEnabled =
    _:
    let
      hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success;
      colors =
        if hasStylixPalette then config.lib.stylix.colors
        else {
          base00 = "1e1e2e";
          base0D = "89b4fa";
        };
    in
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      programs.alacritty.settings = {
        window.opacity = lib.mkForce 1.0;
        font = {
          builtin_box_drawing = true;
          normal.family = lib.mkDefault "JetBrainsMono Nerd Font";
          normal.style = lib.mkForce "Bold";
        };

        cursor.vi_mode_style = {
          shape = "Block";
          blinking = "Off";
        };
        colors.cursor = {
          cursor = lib.mkForce "#${colors.base0D}"; # Accent (base0D), distinct from text (base05) and background (base00)
          text = lib.mkForce "#${colors.base00}"; # Background color under cursor for contrast
        };
      };
    };
}
