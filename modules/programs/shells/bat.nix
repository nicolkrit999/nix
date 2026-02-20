{ delib, pkgs, ... }:
delib.module {
  name = "programs.bat";
  options.programs.bat = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    {
      catppuccin.bat.enable = myconfig.constants.catppuccin or false;
      catppuccin.bat.flavor = myconfig.constants.catppuccinFlavor or "mocha";
      # -----------------------------------------------------------------------

      programs.bat = {
        enable = true;

        config = {
          # Optional: any other bat config options (like --style)
        };
      };
    };
}
