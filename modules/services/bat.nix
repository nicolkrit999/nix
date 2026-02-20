{ delib, ... }:
delib.module {
  name = "programs.bat";
  options.programs.bat = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { pkgs, nixos, ... }:
    {
      catppuccin.bat.enable = nixos.constants.catppuccin or false;
      catppuccin.bat.flavor = nixos.constants.catppuccinFlavor or "mocha";
      # -----------------------------------------------------------------------

      programs.bat = {
        enable = true;

        config = {
          # Optional: any other bat config options (like --style)
        };
      };
    };
}
