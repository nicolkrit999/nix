{ delib
, lib
, config
, pkgs
, ...
}:
let
  anyWmEnabled =
    myconfig:
    (myconfig.programs.hyprland.enable or false)
    || (myconfig.programs.niri.enable or false)
    || (myconfig.programs.mango.enable or false);
in
delib.module {
  name = "services.hyprlock";

  options = with delib; moduleOptions {
    # false = 12-hour clock with AM/PM, true = 24-hour; both lock variants, independent of LC_TIME
    use24HourClock = boolOption false;
    # Sizes apply only when catppuccin = true (defaults = the catppuccin theme's own values)
    avatarSize = intOption 100; # Profile picture edge in px; its position shifts to keep the gap to the input field
    clockFontSize = intOption 90; # Time label font size; the date label moves to keep the gap below it
    dateFontSize = intOption 25;
    inputWidth = intOption 300;
    inputHeight = intOption 60;
  };

  nixos.always =
    { myconfig, ... }:
    lib.mkIf (anyWmEnabled myconfig) {
      security.pam.services.hyprlock = { };
    };

  home.always =
    { myconfig, ... }:
    let
      catppuccinEnabled = myconfig.constants.theme.catppuccin or false;

      c = config.lib.stylix.colors;

      # Perceptual luma (0..255000) of a base16 hex colour, pure Nix.
      luma =
        hex:
        let
          ch = i: lib.fromHexString (builtins.substring i 2 hex);
        in
        2126 * ch 0 + 7152 * ch 2 + 722 * ch 4;
      bgLuma = luma c.base00;
      isDarkScheme = bgLuma < luma c.base05;
      dist =
        hex:
        let
          d = luma hex - bgLuma;
        in
        if d < 0 then -d else d;
      # Light text on a dark scheme wants the wallpaper pulled down, dark text on a light scheme wants it lifted
      scrimBrightness = if isDarkScheme then 0.6 else 1.25;
      # Text colour with the largest luma gap to base00 (base07 is not always the brightest)
      fg = if dist c.base07 > dist c.base05 then c.base07 else c.base05;
      shadowColor = c.base00;

      statics = lib.filter (w: w.wallpaperURL != "") myconfig.constants.wallpapers;
      perMonitor = lib.filter (w: w.targetMonitor != "*") statics;
      catchAll = lib.findFirst (w: w.targetMonitor == "*")
        {
          wallpaperURL = myconfig.constants.fallbackWallpaperURL;
          wallpaperSHA256 = myconfig.constants.fallbackWallpaperSHA256;
        }
        statics;
      fetchWp =
        w:
        "${pkgs.fetchurl {
          url = w.wallpaperURL;
          sha256 = w.wallpaperSHA256;
        }}";
      labelBase = {
        monitor = "";
        color = "rgba(${fg}ff)";
        shadow_passes = 3;
        shadow_size = 4;
        shadow_color = "rgba(${shadowColor}e6)";
        shadow_boost = 0.6;
        font_family = "JetBrainsMono Nerd Font Propo";
        halign = "left";
        valign = "center";
      };
      # monitor = "" covers every monitor without its own block, whatever the monitor count
      mkBackgrounds =
        look:
        map
          (
            w:
            look
            // {
              monitor = w.targetMonitor;
              path = fetchWp w;
              zindex = -1;
            }
          )
          perMonitor
        ++ [
          (
            look
            // {
              monitor = "";
              path = fetchWp catchAll;
              zindex = -2;
            }
          )
        ];
      lock = myconfig.services.hyprlock;
      # Theme geometry the sizes below are relative to: the input field centred 47 px below the middle, a 42 px gap between its top
      # edge and the avatar's bottom edge (so avatar y = 75 at size 100 / input height 60), the date 60 px under a 90 px clock
      avatarY = (lock.avatarSize + lock.inputHeight) / 2 - 5;
      dateY = -(60 + lock.clockFontSize);
      # One clock and one date for both lock variants. $TIME and $TIME12 are fixed hyprlock formats ("09:05" / "09:05 PM"), not LC_TIME.
      clockVar = if lock.use24HourClock then "$TIME" else "$TIME12";
      dateFmt = "%A, %d %B %Y";
      # The theme's own background block points at one image; ours are per monitor.
      # The size/position lines of the clock, date, avatar and input field are rewritten from the services.hyprlock sizes.
      # The clock text is rewritten to clockVar, the same value the plain variant uses.
      catppuccinLockConf = pkgs.runCommand "catppuccin-hyprlock-no-background.conf" { } ''
        src=${config.catppuccin.sources.hyprlock}/hyprlock.conf
        awk \
          -v clockVar='${clockVar}' \
          -v avatar=${toString lock.avatarSize} -v avatarY=${toString avatarY} \
          -v clock=${toString lock.clockFontSize} -v date=${toString lock.dateFontSize} \
          -v dateY=${toString dateY} -v inW=${toString lock.inputWidth} -v inH=${toString lock.inputHeight} '
          /^# BACKGROUND$/ { skip = 1; found = 1; next }
          skip && /^}/ { skip = 0; next }
          skip { next }
          /^# / { sec = $0 }
          sec == "# TIME" && /^  text = / { print "  text = " clockVar; hit++; next }
          sec == "# TIME" && /^  font_size = / { print "  font_size = " clock; hit++; next }
          sec == "# DATE" && /^  font_size = / { print "  font_size = " date; hit++; next }
          sec == "# DATE" && /^  position = / { print "  position = -30, " dateY; hit++; next }
          sec == "# USER AVATAR" && /^  size = / { print "  size = " avatar; hit++; next }
          sec == "# USER AVATAR" && /^  position = / { print "  position = 0, " avatarY; hit++; next }
          sec == "# INPUT FIELD" && /^  size = / { print "  size = " inW ", " inH; hit++; next }
          { print }
          END { if (!found || skip) exit 1; if (hit != 7) exit 2 }
        ' "$src" > "$out" || { echo "catppuccin hyprlock.conf: BACKGROUND block or a size/position line not found, theme layout changed" >&2; exit 1; }
        if grep -q '^background' "$out"; then echo "background block still present" >&2; exit 1; fi
      '';
      bgLook = {
        blur_passes = 2;
        blur_size = 4;
        inherit scrimBrightness;
        contrast = 1.0;
      };
    in
    lib.mkIf (anyWmEnabled myconfig) {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      catppuccin.hyprlock = {
        enable = catppuccinEnabled;
        flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
        accent = myconfig.constants.theme.catppuccinAccent or "mauve";
        useDefaultConfig = false;
      };

      programs.hyprlock = {
        enable = true;
      }
      // lib.optionalAttrs catppuccinEnabled {
        settings = {
          source = lib.mkAfter [ "${catppuccinLockConf}" ];
          background = lib.mkForce (mkBackgrounds {
            blur_passes = 0;
            color = "$base";
          });
        };
      }
      // lib.optionalAttrs (!catppuccinEnabled) {
        settings = {
          general = {
            hide_cursor = true;
            fail_timeout = 5000;
          };

          background = lib.mkForce (mkBackgrounds bgLook);

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
            (
              labelBase
                // {
                text = "Welcome!";
                font_size = 75;
                position = "165, 450";
              }
            )
            (
              labelBase
                // {
                text = clockVar;
                font_size = 55;
                position = "255, 335";
              }
            )
            (
              labelBase
                // {
                text = ''cmd[update:60000] echo "$(date +'${dateFmt}')"'';
                font_size = 28;
                position = "180, 240";
              }
            )
            (
              labelBase
                // {
                text = " $USER";
                font_size = 20;
                position = "310, -205";
              }
            )
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
