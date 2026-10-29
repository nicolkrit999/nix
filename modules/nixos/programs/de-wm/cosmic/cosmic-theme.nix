{ delib
, lib
, config
, ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      theme = myconfig.constants.theme;
      isDark = theme.polarity != "light";

      stylixColors = lib.attrByPath [ "lib" "stylix" "colors" ] null config;
      colors =
        if stylixColors != null && (builtins.tryEval stylixColors.base00).success then stylixColors else null;

      greys = [ "base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07" ];

      # Mapping table, one place to tune. A spec is a base16 slot name, { mix = [ slotA slotB t ]; }
      # (t = 0 gives slotA) or { grey = p; } (position 0..7 on the base00..base07 ramp, interpolated).
      # Greys run background-most to foreground-most for both polarities, so no inversion for light.
      # Lossy: 8 greys are stretched over 11 neutral steps (neutral_0 is base00, not pure black);
      # COSMIC has no cyan slot (base0C feeds ext_blue only) and no named brown/pink/indigo (mixed or reused).
      paletteMap = {
        gray_1 = { grey = 0.0; };
        gray_2 = { grey = 1.0; };
        neutral_0 = { grey = 0.0; };
        neutral_1 = { grey = 0.0; };
        neutral_2 = { grey = 1.0; };
        neutral_3 = { grey = 2.0; };
        neutral_4 = { grey = 2.8; };
        neutral_5 = { grey = 3.6; };
        neutral_6 = { grey = 4.4; };
        neutral_7 = { grey = 5.2; };
        neutral_8 = { grey = 6.0; };
        neutral_9 = { grey = 6.5; };
        neutral_10 = { grey = 7.0; };
        accent_red = "base08";
        accent_orange = "base09";
        accent_yellow = "base0A";
        accent_green = "base0B";
        accent_blue = "base0D";
        accent_purple = "base0E";
        accent_indigo = { mix = [ "base0D" "base0E" 0.5 ]; };
        accent_pink = { mix = [ "base08" "base0E" 0.5 ]; };
        accent_warm_grey = "base0F";
        bright_red = "base08";
        bright_orange = "base09";
        bright_green = "base0B";
        ext_orange = "base09";
        ext_yellow = "base0A";
        ext_blue = "base0C";
        ext_purple = "base0E";
        ext_indigo = { mix = [ "base0D" "base0E" 0.5 ]; };
        ext_pink = { mix = [ "base08" "base0E" 0.5 ]; };
        ext_warm_grey = "base0F";
      };

      hexToRgb = hex:
        let
          s = lib.removePrefix "#" hex;
          channel = i: (lib.fromHexString (builtins.substring i 2 s)) / 255.0;
        in
        { r = channel 0; g = channel 2; b = channel 4; };
      mixRgb = a: b: t: {
        r = a.r + (b.r - a.r) * t;
        g = a.g + (b.g - a.g) * t;
        b = a.b + (b.b - a.b) * t;
      };
      rgbOf = slot: hexToRgb colors.${slot};
      greyAt = p:
        let
          i = builtins.floor p;
          f = p - i;
          a = rgbOf (builtins.elemAt greys i);
        in
        if f <= 0.0 then a else mixRgb a (rgbOf (builtins.elemAt greys (i + 1))) f;
      resolve = spec:
        if builtins.isString spec then rgbOf spec
        else if spec ? mix then mixRgb (rgbOf (builtins.elemAt spec.mix 0)) (rgbOf (builtins.elemAt spec.mix 1)) (builtins.elemAt spec.mix 2)
        else greyAt spec.grey;

      # lib.strings.floatToString (used by cosmic-manager) warns unless float == fromJSON (toString float),
      # i.e. unless the float is exactly the double parsed from its own 6-decimal text. Every colour
      # channel goes through here so it is built from that text.
      to6 = x:
        let
          n = builtins.floor (x * 1000000.0 + 0.5);
          whole = n / 1000000;
        in
        builtins.fromJSON "${toString whole}.${lib.fixedWidthNumber 6 (n - whole * 1000000)}";
      srgb = c: { red = to6 c.r; green = to6 c.g; blue = to6 c.b; };
      srgba = c: srgb c // { alpha = 1.0; };
      optional = value: { __type = "optional"; inherit value; };

      catppuccinPalette = lib.attrByPath [ "catppuccin" "sources" "palette" ] null config;
      accentRgb =
        if cfg.themeAccent != null then rgbOf cfg.themeAccent
        else if theme.catppuccin && catppuccinPalette != null then
          hexToRgb (lib.importJSON "${catppuccinPalette}/palette.json").${theme.catppuccinFlavor}.colors.${theme.catppuccinAccent}.hex
        else rgbOf "base0D";

      builder = variant: {
        accent = optional (srgb accentRgb);
        destructive = optional (srgb (rgbOf "base08"));
        success = optional (srgb (rgbOf "base0B"));
        warning = optional (srgb (rgbOf "base0A"));
        palette = {
          __type = "enum";
          inherit variant;
          value = [ (lib.mapAttrs (_: spec: srgba (resolve spec)) paletteMap // { name = "nix-${lib.toLower variant}"; }) ];
        };
      };
    in
    {
      wayland.desktopManager.cosmic.appearance.theme = lib.mkIf (cfg.followTheme && colors != null) (
        { mode = if isDark then "dark" else "light"; }
        // (if isDark then { dark = builder "Dark"; } else { light = builder "Light"; })
      );
    };
}
