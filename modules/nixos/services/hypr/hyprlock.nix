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
      hyprlandEnabled = myconfig.programs.hyprland.enable or false;
      niriEnabled = myconfig.programs.niri.enable or false;

      caelestiaActiveOnHyprland =
        (myconfig.programs.caelestia.enable or false)
        && (myconfig.programs.caelestia.enableOnHyprland or false)
        && hyprlandEnabled;
      noctaliaActiveOnHyprland =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnHyprland or false)
        && hyprlandEnabled;
      noctaliaActiveOnNiri =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnNiri or false)
        && niriEnabled;

      hyprlandFallback = hyprlandEnabled && !caelestiaActiveOnHyprland && !noctaliaActiveOnHyprland;
      niriFallback = niriEnabled && !noctaliaActiveOnNiri;

      catppuccinEnabled = myconfig.constants.theme.catppuccin or false;

      c = config.lib.stylix.colors;

      hasWallpapers = (myconfig.constants ? wallpapers) && (myconfig.constants.wallpapers != [ ]);
      fallbackWallpaper = ../../../templates/src/wallpapers/nix-black-4k.png;
      lockWallpaper =
        if hasWallpapers then
          let
            wp = lib.findFirst
              (w: w.targetMonitor == "*")
              (builtins.head myconfig.constants.wallpapers)
              myconfig.constants.wallpapers;
          in
          "${pkgs.fetchurl { url = wp.wallpaperURL; sha256 = wp.wallpaperSHA256; }}"
        else
          "${fallbackWallpaper}";
    in
    lib.mkIf (hyprlandFallback || niriFallback) {

      catppuccin.hyprlock.enable = catppuccinEnabled;
      catppuccin.hyprlock.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprlock.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      programs.hyprlock = {
        enable = true;
      } // lib.optionalAttrs (!catppuccinEnabled) {
        settings = {
          general = {
            no_fade_in = false;
            grace = 0;
            disable_loading_bar = false;
            hide_cursor = true;
          };

          background = lib.mkForce [
            {
              monitor = "";
              path = lockWallpaper;
              blur_passes = 0;
            }
          ];

          shape = lib.mkForce [
            {
              monitor = "";
              size = "320, 55";
              # base05 at 20% — adapts to polarity: light tint on dark themes, dark tint on light themes
              color = "rgba(${c.base05}33)";
              rounding = -1;
              border_size = 0;
              rotate = 0;
              xray = false;
              position = "170, -140";
              halign = "left";
              valign = "center";
            }
          ];

          label = lib.mkForce [
            # Greeting
            {
              monitor = "";
              text = "Hello ${myconfig.constants.user}";
              color = "rgba(${c.base05}bf)";
              font_size = 40;
              font_family = "JetBrainsMono Nerd Font";
              position = "165, 330";
              halign = "left";
              valign = "center";
            }
            # Time (12h, updates every second)
            {
              monitor = "";
              text = ''cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"'';
              color = "rgba(${c.base05}bf)";
              font_size = 40;
              font_family = "JetBrainsMono Nerd Font";
              position = "255, 210";
              halign = "left";
              valign = "center";
            }
            # Date (updates every minute)
            {
              monitor = "";
              text = ''cmd[update:60000] echo "$(date +'%A, %B %d')"'';
              color = "rgba(${c.base05}bf)";
              font_size = 20;
              font_family = "JetBrainsMono Nerd Font";
              position = "180, 155";
              halign = "left";
              valign = "center";
            }
            # Username inside pill
            {
              monitor = "";
              text = " $USER";
              color = "rgba(${c.base05}e6)";
              font_size = 16;
              font_family = "JetBrainsMono Nerd Font";
              position = "281, -140";
              halign = "left";
              valign = "center";
            }
          ];

          input-field = lib.mkForce [
            {
              monitor = "";
              size = "320, 55";
              outline_thickness = 1;
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;
              # base03 border + base00 fill: adapts to polarity — dark bg on dark themes, light bg on light themes
              outer_color = "rgba(${c.base03}99)";
              inner_color = "rgba(${c.base00}d9)";
              # base05 is the main foreground — dark on light themes, light on dark themes
              font_color = "rgba(${c.base05}e6)";
              font_family = "JetBrainsMono Nerd Font";
              fade_on_empty = false;
              placeholder_text =
                if (myconfig.constants.theme.polarity or "dark") == "dark"
                then ''<i><span foreground="##${c.base04}99">🔒 Enter Pass</span></i>''
                else ''<i><span foreground="##${c.base03}99">🔒 Enter Pass</span></i>'';
              hide_input = false;
              check_color = "rgba(${c.base0B}f2)";
              fail_color = "rgba(${c.base08}f2)";
              capslock_color = "rgba(${c.base0A}f2)";
              position = "170, -220";
              halign = "left";
              valign = "center";
            }
          ];
        };
      };
    };
}
