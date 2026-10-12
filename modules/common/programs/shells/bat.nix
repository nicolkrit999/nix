{ delib, ... }:
delib.module {
  name = "programs.bat";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    {
      catppuccin.bat.enable = myconfig.constants.theme.catppuccin;
      catppuccin.bat.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.bat = {
        enable = true;

        config = {
          color = "always";
          style = "numbers";
        };
      };
    };
}
