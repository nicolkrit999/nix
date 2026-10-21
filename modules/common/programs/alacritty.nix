{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.alacritty";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled = { myconfig, ... }: {
    stylix.targets.alacritty.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      terminal = myconfig.constants.terminal;
    in
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      catppuccin.alacritty.enable = myconfig.constants.theme.catppuccin;
      catppuccin.alacritty.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.alacritty = {
        enable = true;
        settings = {
          font.normal.family = lib.mkDefault "JetBrainsMono Nerd Font";

          cursor = {
            style = {
              shape =
                if terminal.cursorStyle == "block" then "Block"
                else if terminal.cursorStyle == "beam" then "Beam"
                else "Underline";
              blinking = if terminal.cursorBlink then "On" else "Off";
            };
            thickness = terminal.cursorBeamWidth / 12.0; # Convert pixels to cell fraction (~0.25 for 3px)
          };
        };
      };
    };
}
