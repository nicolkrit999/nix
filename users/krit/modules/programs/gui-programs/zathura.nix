{ delib, ... }:
delib.module {
  name = "krit-zathura";
  options.krit.programs.zathura.enable = delib.boolOption true;

  home.ifEnabled =
    { cfg, nixos, ... }:
    {

      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME
      # -----------------------------------------------------------------------
      catppuccin.zathura.enable = nixos.constants.catppuccin or false;
      catppuccin.zathura.flavor = nixos.constants.catppuccinFlavor or "mocha";

      programs.zathura = {
        enable = true;

        # -----------------------------------------------------
        # ⌨️ KEY MAPPINGS
        # -----------------------------------------------------
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

        # -----------------------------------------------------
        # ⚙️ OPTIONS
        # -----------------------------------------------------
        options = {
          font = "JetBrains Mono Bold 16";

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
