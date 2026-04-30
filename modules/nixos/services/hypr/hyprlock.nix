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
              color = "rgba(ffffff33)";
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
              color = "rgba(${c.base05}bf)";
              font_size = 75;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "165, 450";
              halign = "left";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"'';
              color = "rgba(${c.base05}bf)";
              font_size = 55;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "255, 335";
              halign = "left";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:60000] echo "$(date +'%A, %B %d')"'';
              color = "rgba(${c.base05}bf)";
              font_size = 28;
              font_family = "JetBrainsMono Nerd Font Propo";
              position = "180, 240";
              halign = "left";
              valign = "center";
            }
            {
              monitor = "";
              text = " $USER";
              color = "rgba(${c.base05}cc)";
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
              inner_color = "rgba(ffffff1a)";
              font_color = "rgba(${c.base06}ff)";
              font_family = "JetBrainsMono Nerd Font Propo";
              fade_on_empty = false;
              placeholder_text =
                if (myconfig.constants.theme.polarity or "dark") == "dark"
                then ''<i><span foreground="##ffffff99">🔒 Enter Pass</span></i>''
                else ''<i><span foreground="##${c.base03}99">🔒 Enter Pass</span></i>'';
              hide_input = false;
              check_color = "rgba(${c.base0B}f2)";
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
