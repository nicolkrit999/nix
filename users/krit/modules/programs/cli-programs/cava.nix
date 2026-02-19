{ delib, config, ... }:
delib.module {
  name = "krit-cava"; # Isolated name
  options.krit.programs.cava.enable = delib.boolOption true; # Default to true [cite: 407]

  home.ifEnabled =
    { cfg, ... }:
    {
      # Only applies if enabled
      programs.cava = {
        enable = true;
        settings = {
          general.framerate = 60;
          color = {
            gradient = 1;
            gradient_count = 8;
            gradient_color_1 = "'#${config.lib.stylix.colors.base0D}'"; # Blue-ish
            gradient_color_2 = "'#${config.lib.stylix.colors.base0C}'"; # Cyan-ish
            gradient_color_3 = "'#${config.lib.stylix.colors.base0B}'"; # Green-ish
            gradient_color_4 = "'#${config.lib.stylix.colors.base0A}'"; # Yellow-ish
            gradient_color_5 = "'#${config.lib.stylix.colors.base09}'"; # Orange-ish
            gradient_color_6 = "'#${config.lib.stylix.colors.base08}'"; # Red-ish
            gradient_color_7 = "'#${config.lib.stylix.colors.base0E}'"; # Magenta-ish
            gradient_color_8 = "'#${config.lib.stylix.colors.base0F}'"; # Brown/Dark Red
          };
        };
      };
    };
}
