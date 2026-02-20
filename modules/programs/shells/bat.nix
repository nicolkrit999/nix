{ delib, pkgs, ... }:
delib.module {
  name = "programs.bat";
  options.programs.bat = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    {
      constants,
      ...
    }:
    {
      catppuccin.bat.enable = constants.catppuccin or false;
      catppuccin.bat.flavor = constants.catppuccinFlavor or "mocha";
      # -----------------------------------------------------------------------

      programs.bat = {
        enable = true;

        config = {
          # Optional: any other bat config options (like --style)
        };
      };
    };
}
