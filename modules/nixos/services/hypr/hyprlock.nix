{ delib, lib, config, pkgs, ... }:
delib.module {
  name = "services.hyprlock";
  options = with delib; moduleOptions {
    enable = boolOption true;
    settings = attrsOption { };
  };

  home.always =
    { myconfig, ... }:
    let
      anyWmEnabled =
        (myconfig.programs.hyprland.enable or false)
        || (myconfig.programs.niri.enable or false)
        || (myconfig.programs.mango.enable or false);

      catppuccinEnabled = myconfig.constants.theme.catppuccin or false;

      c = config.lib.stylix.colors;

      # Perceptual luma (0..255000) of a base16 hex colour, pure Nix.
      luma = hex:
        let ch = i: lib.fromHexString (builtins.substring i 2 hex);
        in 2126 * ch 0 + 7152 * ch 2 + 722 * ch 4;
      bgLuma = luma c.base00;
      isDarkScheme = bgLuma < luma c.base05;
      dist = hex: let d = luma hex - bgLuma; in if d < 0 then -d else d;
      # Text colour with the largest luma gap to base00 (base07 is not always the brightest)
      fg = if dist c.base07 > dist c.base05 then c.base07 else c.base05;
      shadowColor = c.base00;

      wp = myconfig.constants.primaryWallpaper;
      lockWallpaper = "${pkgs.fetchurl { url = wp.wallpaperURL; sha256 = wp.wallpaperSHA256; }}";
    in
    lib.mkIf anyWmEnabled {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      catppuccin.hyprlock.enable = catppuccinEnabled;
      catppuccin.hyprlock.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprlock.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      programs.hyprlock = {
        enable = true;
      } // lib.optionalAttrs (!catppuccinEnabled) {
        settings = {
          general = {
            hide_cursor = true;
            fail_timeout = 5000;
          };

          background = lib.mkForce [
            {
              monitor = "";
              path = lockWallpaper;
              blur_passes = 2;
              blur_size = 4;
              brightness = if isDarkScheme then 0.6 else 1.25;
              contrast = 1.0;
            }
          ];

          image = lib.mkForce [
            {
              monitor = "";
              path = "~/.face";
              border_size = 1;
              border_color = "rgba(${c.base0D}bf)";
              size = 220;
              rounding = -1;
              rotate = 0;
              reload_time = -1;
              reload_cmd = "";
              position = "249, 25";
              halign = "left";
              valign = "center";
            }
          ];

          shape = lib.mkForce [
            {
              monitor = "";
              size = "400, 70";
              color = "rgba(${c.base00}b3)";
              rounding = -1;
              border_size = 0;
              rotate = 0;
              xray = false;
              position = "170, -205";
              halign = "left";
              valign = "center";
            }
          ];

          label = lib.mkForce [
            {
              monitor = "";
              text = "Welcome!";
              color = "rgba(${fg}ff)";
              shadow_passes = 3;
              shadow_size = 4;
              shadow_color = "rgba(${shadowColor}e6)";
              shadow_boost = 0.6;
              font_size = 75;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "165, 450";
              halign = "left";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"'';
              color = "rgba(${fg}ff)";
              shadow_passes = 3;
              shadow_size = 4;
              shadow_color = "rgba(${shadowColor}e6)";
              shadow_boost = 0.6;
              font_size = 55;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "255, 335";
              halign = "left";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:60000] echo "$(date +'%A, %B %d')"'';
              color = "rgba(${fg}ff)";
              shadow_passes = 3;
              shadow_size = 4;
              shadow_color = "rgba(${shadowColor}e6)";
              shadow_boost = 0.6;
              font_size = 28;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "180, 240";
              halign = "left";
              valign = "center";
            }
            {
              monitor = "";
              text = " $USER";
              color = "rgba(${fg}ff)";
              shadow_passes = 3;
              shadow_size = 4;
              shadow_color = "rgba(${shadowColor}e6)";
              shadow_boost = 0.6;
              font_size = 20;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "310, -205";
              halign = "left";
              valign = "center";
            }
          ];

          input-field = lib.mkForce [
            {
              monitor = "";
              size = "400, 70";
              outline_thickness = 0;
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;
              outer_color = "rgba(${c.base00}00)";
              inner_color = "rgba(${c.base00}b3)";
              font_color = "rgba(${fg}ff)";
              font_family = "JetBrainsMono Nerd Font Propo";
              fade_on_empty = false;
              placeholder_text = ''<i><span foreground="##${fg}cc">🔒 Enter Pass</span></i>'';
              hide_input = false;
              check_color = "rgba(${c.base09}f2)";
              fail_color = "rgba(${c.base08}f2)";
              capslock_color = "rgba(${c.base0A}f2)";
              position = "170, -315";
              halign = "left";
              valign = "center";
            }
          ];
        };
      };
    };
}
