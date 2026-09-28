{ delib, lib, inputs, pkgs, config, ... }:
delib.module {
  name = "programs.sidra";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    customTheme = delib.boolOption true;
  };

  home.ifEnabled = { myconfig, cfg, ... }:
    let
      c = config.lib.stylix.colors.withHashtag;
      polarity = myconfig.constants.theme.polarity or "dark";

      sidraColors = {
        crust = c.base00;
        mantle = c.base01;
        base = c.base02;
        surface0 = c.base02;
        surface1 = c.base03;
        surface2 = c.base04;
        overlay = c.base03;
        subtext0 = c.base04;
        subtext1 = c.base05;
        text = c.base06;
        accent = c.base0D;
        accentHover = c.base0C;
      };

      customThemePath =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "Library/Application Support/Sidra/custom-theme.json"
        else ".config/Sidra/custom-theme.json";
    in
    {
      home.packages = [ inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      home.file.${customThemePath} = lib.mkIf cfg.customTheme {
        text = builtins.toJSON {
          ${polarity} = sidraColors;
        };
      };
    };
}
