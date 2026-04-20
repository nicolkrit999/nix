{ delib, lib, config, ... }:
delib.module {
  name = "services.hyprlock";
  options = with delib; moduleOptions {
    enable = boolOption true;
    settings = attrsOption { };
  };

  # Skip entirely on Darwin - hyprlock is a Wayland screen locker (Linux-only)
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

      # Base16 colors (without hashtag for rgba interpolation)
      c = config.lib.stylix.colors;
      ch = config.lib.stylix.colors.withHashtag;

      # Wallpaper: use screenshot+blur if host has wallpapers, otherwise use fallback
      hasWallpapers = (myconfig.constants ? wallpapers) && (myconfig.constants.wallpapers != [ ]);
      fallbackWallpaper = ../../../templates/src/wallpapers/nix-black-4k.png;
      lockWallpaper = if hasWallpapers then "screenshot" else "${fallbackWallpaper}";
    in
    lib.mkIf (hyprlandFallback || niriFallback) {

      catppuccin.hyprlock.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.hyprlock.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprlock.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      programs.hyprlock = {
        enable = true;

        settings = {
          general = {
            hide_cursor = true;
            ignore_empty_input = true;
            grace = 10;
          };

          background = lib.mkForce [
            {
              path = lockWallpaper;
              color = ch.base00;
              blur_passes = 2;
              blur_size = 8;
            }
          ];

          # Username box shape
          shape = lib.mkForce [
            {
              size = "300, 50";
              rounding = 0;
              border_size = 2;
              color = "rgba(${c.base01}, 0.33)";
              border_color = "rgba(${c.base03}, 0.95)";
              position = "0, 270";
              halign = "center";
              valign = "bottom";
            }
          ];

          label = lib.mkForce [
            # Time display (large, centered top)
            {
              text = ''cmd[update:1000] echo "$(date +'%k:%M')"'';
              font_size = 115;
              font_family = "JetBrainsMono Nerd Font Bold";
              shadow_passes = 3;
              color = "rgba(${c.base05}, 0.9)";
              position = "0, -150";
              halign = "center";
              valign = "top";
            }
            # Date display (below time)
            {
              text = ''cmd[update:1000] echo "- $(date +'%A, %B %d') -"'';
              font_size = 18;
              font_family = "JetBrainsMono Nerd Font";
              shadow_passes = 3;
              color = "rgba(${c.base05}, 0.9)";
              position = "0, -350";
              halign = "center";
              valign = "top";
            }
            # Username label
            {
              text = "  $USER";
              font_size = 15;
              font_family = "JetBrainsMono Nerd Font Bold";
              color = ch.base05;
              position = "0, 284";
              halign = "center";
              valign = "bottom";
            }
          ];

          input-field = lib.mkForce [
            {
              size = "300, 50";
              rounding = 0;
              outline_thickness = 2;
              dots_spacing = 0.4;

              font_family = "JetBrainsMono Nerd Font Bold";
              font_color = "rgba(${c.base05}, 0.9)";

              outer_color = "rgba(${c.base03}, 0.95)";
              inner_color = "rgba(${c.base01}, 0.33)";
              check_color = "rgba(${c.base0B}, 0.95)";
              fail_color = "rgba(${c.base08}, 0.95)";
              capslock_color = "rgba(${c.base0A}, 0.95)";
              bothlock_color = "rgba(${c.base0A}, 0.95)";

              hide_input = false;
              fade_on_empty = false;
              placeholder_text = "Enter Password";

              position = "0, 200";
              halign = "center";
              valign = "bottom";
            }
          ];
        };
      };
    };
}
