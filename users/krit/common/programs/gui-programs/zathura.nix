{ delib, pkgs, ... }:
delib.module {
  name = "krit.programs.zathura";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    myconfig.stylix.targets.zathura.enable = !(myconfig.constants.theme.catppuccin or false);
  };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME
      # -----------------------------------------------------------------------
      catppuccin.zathura.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.zathura.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";

      programs.zathura = {
        enable = true;

        mappings = {
          # Standard Vim Scrolling
          j = "scroll down";
          k = "scroll up";
          h = "scroll left";
          l = "scroll right";

          # Fast Scrolling (Half-page)
          d = "scroll half_down";
          u = "scroll half_up";

          # Page Navigation
          J = "navigate next";
          K = "navigate previous";

          # Zooming
          "+" = "zoom in";
          "-" = "zoom out";
          "=" = "zoom in";

          # View Modes
          D = "toggle_page_mode";
        };

        options = {
          font = "JetBrainsMono Nerd Font Bold 16";

          # UX Improvements
          selection-clipboard = "clipboard";
          adjust-open = "best-fit";
          pages-per-row = 1;
          scroll-page-aware = "true";
          scroll-full-overlap = "0.01";
          scroll-step = 100;
        };
      };
    };
}
