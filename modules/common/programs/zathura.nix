{ delib, pkgs, ... }:
delib.module {
  name = "programs.zathura";
  options = delib.moduleOptions {
    enable = delib.boolOption false;
    # "dark" opens documents recolored (inverted) by default, "light" shows them
    # as authored. Toggle at runtime with the recolor key (Ctrl+R).
    defaultMode = delib.enumOption [ "dark" "light" ] "dark";
  };

  myconfig.ifEnabled = { myconfig, ... }: {
    stylix.targets.zathura.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { cfg
    , myconfig
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

          recolor = cfg.defaultMode == "dark";
          adjust-open = "width";

          selection-clipboard = "clipboard";
          scroll-page-aware = "true";
          scroll-full-overlap = "0.01";
          scroll-step = 100;
        };
      };
    };
}
