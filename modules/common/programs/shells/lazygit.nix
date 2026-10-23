{ delib, ... }:
delib.module {
  name = "programs.lazygit";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig, ... }:
    {
      catppuccin = {
        lazygit = {
          enable = myconfig.constants.theme.catppuccin;
          flavor = myconfig.constants.theme.catppuccinFlavor;
          accent = myconfig.constants.theme.catppuccinAccent;
        };
      };

      programs.lazygit = {
        enable = true;

        settings = {
          gui = {
            nerdFontsVersion = "2";
            quitOnTopLevelReturn = false;
          };
          confirmOnQuit = false;
          git.overrideGpg = true;
        };
      };
    };
}
