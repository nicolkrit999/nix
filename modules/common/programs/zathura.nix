{ delib, pkgs, ... }:
delib.module {
  name = "programs.zathura";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled = { myconfig, ... }: {
    stylix.targets.zathura.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      catppuccin.zathura = {
        enable = myconfig.constants.theme.catppuccin;
        flavor = myconfig.constants.theme.catppuccinFlavor;
      };

      programs.zathura = {
        enable = true;

        mappings = {
          j = "scroll down";
          k = "scroll up";
          h = "scroll left";
          l = "scroll right";

          d = "scroll half_down";
          u = "scroll half_up";

          J = "navigate next";
          K = "navigate previous";

          "+" = "zoom in";
          "-" = "zoom out";
          "=" = "zoom in";

          D = "toggle_page_mode";
        };

        options = {
          font = "JetBrainsMono Nerd Font Bold 16";

          selection-clipboard = "clipboard";
          scroll-page-aware = "true";
          scroll-full-overlap = "0.01";
          scroll-step = 100;
        };
      };
    };
}
