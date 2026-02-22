{ delib, ... }:
delib.module {
  name = "programs.bat";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    {
      catppuccin.bat.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.bat.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";

      programs.bat = {
        enable = true;

        config = {
          colors = "always";
          style = "numbers";
        };
      };
    };
}
