{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  cssContent = builtins.readFile ./style.css;

  palettes = {
    mocha = {
      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay2 = "#9399b2";
      overlay1 = "#7f849c";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
    macchiato = {
      rosewater = "#f4dbd6";
      flamingo = "#f0c6c6";
      pink = "#f5bde6";
      mauve = "#c6a0f6";
      red = "#ed8796";
      maroon = "#ee99a0";
      peach = "#f5a97f";
      yellow = "#eed49f";
      green = "#a6da95";
      teal = "#8bd5ca";
      sky = "#91d7e3";
      sapphire = "#74c7ec";
      blue = "#8aadf4";
      lavender = "#b7bdf8";
      text = "#cad3f5";
      subtext1 = "#b8c0e0";
      subtext0 = "#a5adcb";
      overlay2 = "#939ab7";
      overlay1 = "#8087a2";
      overlay0 = "#6e738d";
      surface2 = "#5b6078";
      surface1 = "#494d64";
      surface0 = "#363a4f";
      base = "#24273a";
      mantle = "#1e2030";
      crust = "#181926";
    };
    frappe = {
      rosewater = "#f2d5cf";
      flamingo = "#eebebe";
      pink = "#f4b8e4";
      mauve = "#ca9ee6";
      red = "#e78284";
      maroon = "#ea999c";
      peach = "#ef9f76";
      yellow = "#e5c890";
      green = "#a6d189";
      teal = "#81c8be";
      sky = "#99d1db";
      sapphire = "#85c1dc";
      blue = "#8caaee";
      lavender = "#babbf1";
      text = "#c6d0f5";
      subtext1 = "#b5bfe2";
      subtext0 = "#a5adce";
      overlay2 = "#949cbb";
      overlay1 = "#838ba7";
      overlay0 = "#737994";
      surface2 = "#626880";
      surface1 = "#51576d";
      surface0 = "#414559";
      base = "#303446";
      mantle = "#292c3c";
      crust = "#232634";
    };
    latte = {
      rosewater = "#dc8a78";
      flamingo = "#dd7878";
      pink = "#ea76cb";
      mauve = "#8839ef";
      red = "#d20f39";
      maroon = "#e64553";
      peach = "#fe640b";
      yellow = "#df8e1d";
      green = "#40a02b";
      teal = "#179299";
      sky = "#04a5e5";
      sapphire = "#209fb5";
      blue = "#1e66f5";
      lavender = "#7287fd";
      text = "#4c4f69";
      subtext1 = "#5c5f77";
      subtext0 = "#6c6f85";
      overlay2 = "#7c7f93";
      overlay1 = "#8c8fa1";
      overlay0 = "#9ca0b0";
      surface2 = "#acb0be";
      surface1 = "#bcc0cc";
      surface0 = "#ccd0da";
      base = "#eff1f5";
      mantle = "#e6e9ef";
      crust = "#dce0e8";
    };
  };

  selectedPalette = palettes.${vars.catppuccinFlavor};

  cssVariables =
    if vars.catppuccin then
      ''
        @define-color rosewater ${selectedPalette.rosewater};
        @define-color flamingo ${selectedPalette.flamingo};
        @define-color pink ${selectedPalette.pink};
        @define-color mauve ${selectedPalette.mauve};
        @define-color red ${selectedPalette.red};
        @define-color maroon ${selectedPalette.maroon};
        @define-color peach ${selectedPalette.peach};
        @define-color yellow ${selectedPalette.yellow};
        @define-color green ${selectedPalette.green};
        @define-color teal ${selectedPalette.teal};
        @define-color sky ${selectedPalette.sky};
        @define-color sapphire ${selectedPalette.sapphire};
        @define-color blue ${selectedPalette.blue};
        @define-color lavender ${selectedPalette.lavender};
        @define-color text ${selectedPalette.text};
        @define-color subtext1 ${selectedPalette.subtext1};
        @define-color subtext0 ${selectedPalette.subtext0};
        @define-color overlay2 ${selectedPalette.overlay2};
        @define-color overlay1 ${selectedPalette.overlay1};
        @define-color overlay0 ${selectedPalette.overlay0};
        @define-color surface2 ${selectedPalette.surface2};
        @define-color surface1 ${selectedPalette.surface1};
        @define-color surface0 ${selectedPalette.surface0};
        @define-color base ${selectedPalette.base};
        @define-color mantle ${selectedPalette.mantle};
        @define-color crust ${selectedPalette.crust};

        /* Semantic Mappings */
        @define-color accent      @${vars.catppuccinAccent};
        @define-color window_bg   @base;
        @define-color input_bg    @surface0;
        @define-color selected_bg @surface1;
        @define-color text_color  @text;
      ''
    else
      ''
        @define-color window_bg   ${config.lib.stylix.colors.withHashtag.base00}; /* Background */
        @define-color input_bg    ${config.lib.stylix.colors.withHashtag.base01}; /* Lighter Background */
        @define-color selected_bg ${config.lib.stylix.colors.withHashtag.base02}; /* Selection Background */
        @define-color text        ${config.lib.stylix.colors.withHashtag.base05}; 
        @define-color text_color  ${config.lib.stylix.colors.withHashtag.base05}; /* Foreground */
        @define-color accent      ${config.lib.stylix.colors.withHashtag.base0D}; /* Blue/Accent */
      '';
in
{
  config = lib.mkIf (vars.hyprland or vars.gnome or vars.kde or vars.cosmic or false) {
    programs.wofi = {
      enable = false;

      settings = {
        show = "drun";
        width = 950;
        height = 500;
        always_parse_args = true;
        show_all = false;
        term = vars.term;
        hide_scroll = true;
        print_command = true;
        insensitive = true;
        prompt = "";
        columns = 2;
        allow_markup = true;
        allow_images = true;
      };

      style = ''
        ${cssVariables}
        ${cssContent}
      '';
    };
  };
}
