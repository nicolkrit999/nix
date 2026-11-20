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
      dist =
        hex:
        let
          d = luma hex - bgLuma;
        in
        if d < 0 then -d else d;
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
      # monitor = "" covers every monitor without its own block, whatever the monitor count; the wallpaper is untouched (no blur, dimming or colour)
      mkBackgrounds =
        map
          (w: {
            monitor = w.targetMonitor;
            path = fetchWp w;
            zindex = -2;
          })
          perMonitor
        ++ [
          {
            monitor = "";
            path = fetchWp catchAll;
            zindex = -3;
          }
        ];
      lock = myconfig.services.hyprlock;
      # One clock and one date for both lock variants. $TIME and $TIME12 are fixed hyprlock formats ("09:05" / "09:05 PM"), not LC_TIME.
      clockVar = if lock.use24HourClock then "$TIME" else "$TIME12";
      dateFmt = "%A, %d %B %Y";

      # Both variants keep every UI element in a full-height panel on the left edge of each monitor; the wallpaper (always drawn full-monitor
      # by hyprlock) is only covered there. The panel is anchored left, so each element sits at a left-anchored px offset that centres it on the
      # panel axis (panelW / 2). That needs a known width per element: monospace fonts (advance 0.6 em), hyprlock font_size in pt at 96 dpi
      # (x4/3) -> one glyph is 0.8 * font_size px, a one-line label box is ~1.75 * font_size px high, and variable text (date, username,
      # fingerprint prompt) goes through hyprlock-center, which pads it with no-break spaces (the one blank text_trim keeps) to a fixed length.
      textW = chars: fontSize: chars * fontSize * 4 / 5;
      labelH = fontSize: fontSize * 7 / 4;
      dateChars = 28; # longest "%A, %d %B %Y" in English ("Wednesday, 30 September 2026")
      clockChars = if lock.use24HourClock then 5 else 8;
      panelPad = 40;
      stackGap = 24;
      hyprlockCenter = pkgs.writeShellScript "hyprlock-center" ''
        s=$2
        n=$(( $1 - ''${#s} ))
        [ "$n" -gt 0 ] || n=0
        l=$(( n / 2 ))
        r=$(( n - l ))
        lp=""; rp=""
        while [ "$l" -gt 0 ]; do lp="$lp"$'\xc2\xa0'; l=$((l - 1)); done
        while [ "$r" -gt 0 ]; do rp="$rp"$'\xc2\xa0'; r=$((r - 1)); done
        printf '%s%s%s' "$lp" "$s" "$rp"
      '';
      centered = chars: text: "${hyprlockCenter} ${toString chars} \"${text}\"";
      dateText = centered dateChars "$(date +'${dateFmt}')";
      # Elements top to bottom: { w, h } -> adds the left-anchored x and the y of the element centre (offset from the monitor centre, up
      # positive), the stack being centred vertically as a group; panelW = widest element + 2 * panelPad.
      fold = f: xs: builtins.foldl' f (builtins.head xs) (builtins.tail xs);
      mkPanel =
        items:
        let
          n = builtins.length items;
          panelW = fold lib.max (map (i: i.w) items) + 2 * panelPad;
          total = builtins.foldl' (a: i: a + i.h) 0 items + stackGap * (n - 1);
          above = k: builtins.foldl' (a: i: a + i.h) 0 (lib.take k items) + stackGap * k;
        in
        {
          inherit panelW;
          items = lib.imap0
            (k: i: i // {
              x = panelW / 2 - i.w / 2;
              y = (total - 2 * above k - i.h) / 2;
            })
            items;
        };
      pos = i: "${toString i.x}, ${toString i.y}";

      # Catppuccin: the theme's own clock, date, fingerprint prompt, avatar and input field are re-placed into the panel stack (the keyboard
      # layout label keeps its theme position, top left, inside the panel). Panel colour is the theme's $base.
      fpChars = 36;
      cp = mkPanel [
        { name = "clock"; w = textW clockChars lock.clockFontSize; h = labelH lock.clockFontSize; }
        { name = "date"; w = textW dateChars lock.dateFontSize; h = labelH lock.dateFontSize; }
        { name = "avatar"; w = lock.avatarSize; h = lock.avatarSize; }
        { name = "input"; w = lock.inputWidth; h = lock.inputHeight; }
        { name = "fp"; w = textW fpChars 14; h = labelH 14; }
      ];
      cpAt = name: builtins.head (lib.filter (i: i.name == name) cp.items);
      cpRules = [
        { sec = "TIME"; key = "halign"; val = "left"; }
        { sec = "TIME"; key = "valign"; val = "center"; }
        { sec = "TIME"; key = "position"; val = pos (cpAt "clock"); }
        { sec = "DATE"; key = "halign"; val = "left"; }
        { sec = "DATE"; key = "valign"; val = "center"; }
        { sec = "DATE"; key = "position"; val = pos (cpAt "date"); }
        { sec = "FINGERPRINT"; key = "halign"; val = "left"; }
        { sec = "FINGERPRINT"; key = "position"; val = pos (cpAt "fp"); }
        { sec = "USER AVATAR"; key = "halign"; val = "left"; }
        { sec = "USER AVATAR"; key = "position"; val = pos (cpAt "avatar"); }
        { sec = "INPUT FIELD"; key = "halign"; val = "left"; }
        { sec = "INPUT FIELD"; key = "position"; val = pos (cpAt "input"); }
      ];
      cpRuleAwk = lib.concatMapStringsSep "\n"
        (r: ''sec == "# ${r.sec}" && /^  ${r.key} = / { print "  ${r.key} = ${r.val}"; hit++; next }'')
        cpRules;
      # Rules above plus the panel shape and the text/size rewrites below (TIME text+font_size, DATE text+font_size, FINGERPRINT text, avatar and input size)
      cpHits = builtins.length cpRules + 8;
      # The theme's own background block points at one image; ours are per monitor.
      # The clock text is rewritten to clockVar, the same value the plain variant uses.
      catppuccinLockConf = pkgs.runCommand "catppuccin-hyprlock-no-background.conf" { } ''
        src=${config.catppuccin.sources.hyprlock}/hyprlock.conf
        dateCmd=${lib.escapeShellArg "cmd[update:43200000] ${dateText}"}
        fpCmd=${lib.escapeShellArg "cmd[update:1000] ${centered fpChars "$FPRINTPROMPT"}"}
        awk \
          -v clockVar='${clockVar}' -v dateCmd="$dateCmd" -v fpCmd="$fpCmd" \
          -v avatar=${toString lock.avatarSize} -v clock=${toString lock.clockFontSize} -v date=${toString lock.dateFontSize} \
          -v panelW=${toString cp.panelW} -v inW=${toString lock.inputWidth} -v inH=${toString lock.inputHeight} '
          /^# BACKGROUND$/ { skip = 1; found = 1; next }
          skip && /^}/ { skip = 0; next }
          skip { next }
          /^# TIME$/ {
            print "# PANEL\nshape {\n  monitor =\n  size = " panelW ", 100%\n  color = $base\n  rounding = 0\n  border_size = 0\n  position = 0, 0\n  halign = left\n  valign = center\n  zindex = -1\n}\n"
            hit++
          }
          /^# / { sec = $0 }
          sec == "# TIME" && /^  text = / { print "  text = " clockVar; hit++; next }
          sec == "# TIME" && /^  font_size = / { print "  font_size = " clock; hit++; next }
          sec == "# DATE" && /^  text = / { print "  text = " dateCmd; hit++; next }
          sec == "# DATE" && /^  font_size = / { print "  font_size = " date; hit++; next }
          sec == "# FINGERPRINT" && /^  text = / { print "  text = " fpCmd; hit++; next }
          sec == "# USER AVATAR" && /^  size = / { print "  size = " avatar; hit++; next }
          sec == "# INPUT FIELD" && /^  size = / { print "  size = " inW ", " inH; hit++; next }
          ${cpRuleAwk}
          { print }
          END { if (!found || skip) exit 1; if (hit != ${toString cpHits}) exit 2 }
        ' "$src" > "$out" || { echo "catppuccin hyprlock.conf: BACKGROUND block or a size/position line not found, theme layout changed" >&2; exit 1; }
        if grep -q '^background' "$out"; then echo "background block still present" >&2; exit 1; fi
      '';

      # Plain variant: Welcome, clock, date, avatar, username, input field. Panel colour is the stylix base00 (the text colour fg is picked for
      # contrast against it); the input field sits one step lighter (base01).
      plainImageSize = 220;
      plainFieldW = 400;
      plainFieldH = 70;
      userChars = 16;
      pl = mkPanel [
        { name = "welcome"; w = textW 8 75; h = labelH 75; }
        { name = "clock"; w = textW clockChars 55; h = labelH 55; }
        { name = "date"; w = textW dateChars 28; h = labelH 28; }
        { name = "avatar"; w = plainImageSize; h = plainImageSize; }
        { name = "user"; w = textW userChars 20; h = labelH 20; }
        { name = "input"; w = plainFieldW; h = plainFieldH; }
      ];
      plAt = name: builtins.head (lib.filter (i: i.name == name) pl.items);
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
          background = lib.mkForce mkBackgrounds;
        };
      }
      // lib.optionalAttrs (!catppuccinEnabled) {
        settings = {
          general = {
            hide_cursor = true;
            fail_timeout = 5000;
          };

          background = lib.mkForce mkBackgrounds;

          image = lib.mkForce [
            {
              monitor = "";
              path = "~/.face";
              border_size = 1;
              border_color = "rgba(${c.base0D}bf)";
              size = plainImageSize;
              rounding = -1;
              rotate = 0;
              reload_time = -1;
              reload_cmd = "";
              position = pos (plAt "avatar");
              halign = "left";
              valign = "center";
            }
          ];

          shape = lib.mkForce [
            {
              monitor = "";
              size = "${toString pl.panelW}, 100%";
              color = "rgba(${c.base00}ff)";
              rounding = 0;
              border_size = 0;
              rotate = 0;
              xray = false;
              position = "0, 0";
              halign = "left";
              valign = "center";
              zindex = -1;
            }
          ];

          label = lib.mkForce [
            (labelBase // { text = "Welcome!"; font_size = 75; position = pos (plAt "welcome"); })
            (labelBase // { text = clockVar; font_size = 55; position = pos (plAt "clock"); })
            (labelBase // { text = "cmd[update:60000] ${dateText}"; font_size = 28; position = pos (plAt "date"); })
            (labelBase // { text = "cmd[update:3600000] ${centered userChars "$USER"}"; font_size = 20; position = pos (plAt "user"); })
          ];

          input-field = lib.mkForce [
            {
              monitor = "";
              size = "${toString plainFieldW}, ${toString plainFieldH}";
              outline_thickness = 0;
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;
              outer_color = "rgba(${c.base00}00)";
              inner_color = "rgba(${c.base01}ff)";
              font_color = "rgba(${fg}ff)";
              font_family = "JetBrainsMono Nerd Font Propo";
              fade_on_empty = false;
              placeholder_text = ''<i><span foreground="##${fg}cc">🔒 Enter Pass</span></i>'';
              hide_input = false;
              check_color = "rgba(${c.base09}f2)";
              fail_color = "rgba(${c.base08}f2)";
              capslock_color = "rgba(${c.base0A}f2)";
              position = pos (plAt "input");
              halign = "left";
              valign = "center";
            }
          ];
        };
      };
    };
}
