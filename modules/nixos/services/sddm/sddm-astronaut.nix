{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "services.sddm-astronaut";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;

      embeddedTheme = lib.mkOption {
        type = lib.types.str;
        default = "astronaut";
        example = "japanese_aesthetic";
        description = ''
          Embedded theme name from sddm-astronaut-theme/Themes/.
          Available: astronaut, black_hole, cyberpunk, hyprland_kath,
          jake_the_dog, japanese_aesthetic, pixel_sakura,
          pixel_sakura_static, post-apocalyptic_hacker, purple_leaves.
        '';
      };

      use24HourClock = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Greeter clock format. false (default) = 12-hour with AM/PM
          ("hh:mm AP", same look as hyprlock's $TIME12), true = keep the
          embedded theme's own 24-hour "HH:mm".
          The theme renders HourFormat as an explicit Qt format string and
          builds its Qt locale from `Locale=""`, which is the C locale, so
          this is independent of LC_TIME.
          `themeConfig.HourFormat` wins for a fully custom format.
        '';
      };

      stylixIntegration = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = ''
          Override the embedded theme's hardcoded UI colors with values
          derived from the active stylix base16 scheme, and enable
          PartialBlur so the wallpaper flows edge-to-edge with a blurred
          + tinted region behind the form. Polarity-agnostic by base16
          convention (base00=bg, base05=fg auto-invert per scheme).

          null (default) = auto: enabled iff `background` is set, since
          that's the case where the shipped theme's curated color/art
          pairing is broken. Set to true/false to force either way.
          User `themeConfig` overrides win over stylix defaults.
          Ignored when stylix is not enabled on the host.
        '';
      };

      themeConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          HaveFormBackground = "false";
          PartialBlur = "true";
        };
        description = ''
          Attribute set of [General] options. Each key is rewritten with sed
          in the active theme .conf (Themes/<embeddedTheme>.conf); keys the
          conf does not already define as Key="..." are left untouched. Any
          upstream Themes/*.conf.user is deleted in the patched copy
          (rm -f), so the edited .conf is the only source the theme reads.
          Wins over stylixIntegration defaults.
        '';
      };

      background = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
        default = null;
        description = ''
          Custom background image: a path, or a plain filename resolved in
          users/<user>/src/sddm/ (user = constants.user). Replaces the embedded theme's
          default wallpaper by overwriting the Background key in the active
          theme .conf.
        '';
      };
    };

  nixos.ifEnabled =
    { myconfig
    , cfg
    , ...
    }:
    let
      sddmDir = ../../../../users + "/${myconfig.constants.user}/src/sddm";
      resolveImg = name:
        if name == null || builtins.isPath name || lib.hasPrefix builtins.storeDir name then name
        else if lib.hasPrefix "/" name then
          throw "${name}: absolute paths outside the store are impure; pass a path value or a filename in users/${myconfig.constants.user}/src/sddm/"
        else
          let p = sddmDir + "/${name}"; in
          if builtins.pathExists p then p
          else throw "${name} not found in users/${myconfig.constants.user}/src/sddm/";
      bgPath = resolveImg cfg.background;
      getExtension = path:
        let
          filename = builtins.baseNameOf (toString path);
          parts = lib.splitString "." filename;
        in
        if builtins.length parts > 1
        then lib.last parts
        else "jpg";

      bgExt = if bgPath != null then getExtension bgPath else "jpg";
      bgFilename = "custom_background.${bgExt}";

      hasBg = bgPath != null;
      videoExts = [ "avi" "mp4" "mov" "mkv" "m4v" "webm" ];
      isVideo = hasBg && builtins.elem (lib.toLower bgExt) videoExts;

      stylixAuto = hasBg;
      stylixRequested =
        if cfg.stylixIntegration == null then stylixAuto else cfg.stylixIntegration;
      stylixEnabled = (config.stylix.enable or false) && stylixRequested;

      # Perceptual luma of a base16 hex colour (no leading #), same as hyprlock.
      luma = hex:
        let ch = i: lib.fromHexString (builtins.substring i 2 hex);
        in 2126 * ch 0 + 7152 * ch 2 + 722 * ch 4;
      # Foreground = base05/06/07 with the largest luma gap to base00.
      pickFg = p:
        let
          bgLuma = luma p.base00;
          dist = hex: let d = luma hex - bgLuma; in if d < 0 then -d else d;
        in
        lib.foldl' (a: b: if dist b > dist a then b else a) p.base05 [ p.base06 p.base07 ];
      fg = if stylixEnabled then "#${pickFg config.lib.stylix.colors}" else "#f0f0f0";
      bk = if stylixEnabled then config.lib.stylix.colors.withHashtag.base00 else "#101010";
      fgHex = lib.removePrefix "#" fg;

      # Integer mix of two #rrggbb colours: pct percent of b into a.
      mixHex = a: b: pct:
        let
          ch = h: i: lib.fromHexString (builtins.substring i 2 (lib.removePrefix "#" h));
          hex2 = n: let x = lib.toLower (lib.toHexString n); in if builtins.stringLength x < 2 then "0${x}" else x;
          m = i: hex2 ((ch a i * (100 - pct) + ch b i * pct) / 100);
        in
        "#${m 0}${m 2}${m 4}";
      fieldBg = mixHex bk fg 22;
      fieldSelBg = mixHex bk fg 24;
      fieldBorder = mixHex bk fg 55;

      pairColors = config.lib.stylix.colors.withHashtag;
      pairBk = if hasBg then bk else pairColors.base00;
      pairFg = if hasBg then fg else pairColors.base05;
      pairField = if hasBg then fieldBg else pairColors.base01;
      pairAcc = pairColors.base0D;
      pairWarn = pairColors.base08;
      pairPh = if hasBg then pairColors.base04 else pairColors.base03;

      dimUser = cfg.themeConfig ? DimBackground;
      dimBase = cfg.themeConfig.DimBackground or "0.35";

      backgroundConfig =
        if !hasBg then { }
        else {
          HaveFormBackground = "true";
          PartialBlur = "true";
          FormBackgroundColor = bk;
          DimBackgroundColor = bk;
          DimBackground = dimBase;
          Blur = "1.0";
          BlurMax = "64";
          HeaderTextColor = fg;
          DateTextColor = fg;
          TimeTextColor = fg;
          LoginFieldTextColor = fg;
          PasswordFieldTextColor = fg;
          LoginFieldBackgroundColor = fieldBg;
          PasswordFieldBackgroundColor = fieldBg;
          DropdownBackgroundColor = fieldBg;
          DropdownSelectedBackgroundColor = fieldSelBg;
        } // lib.optionalAttrs isVideo { BackgroundPlaceholder = ""; };

      fgKeys = [
        "LoginFieldTextColor"
        "PasswordFieldTextColor"
        "HeaderTextColor"
        "DateTextColor"
        "TimeTextColor"
        "UserIconColor"
        "PasswordIconColor"
        "SystemButtonsIconsColor"
        "SessionButtonTextColor"
        "VirtualKeyboardButtonTextColor"
        "DropdownTextColor"
      ];

      stylixThemeConfig =
        if !stylixEnabled then { }
        else
          let c = config.lib.stylix.colors.withHashtag; in
          {
            HaveFormBackground = "true";
            PartialBlur = "true";

            FormBackgroundColor = c.base00;
            BackgroundColor = c.base00;
            DimBackgroundColor = c.base00;

            LoginFieldBackgroundColor = c.base01;
            PasswordFieldBackgroundColor = c.base01;
            LoginFieldTextColor = c.base05;
            PasswordFieldTextColor = c.base05;

            HeaderTextColor = c.base05;
            DateTextColor = c.base05;
            TimeTextColor = c.base05;
            UserIconColor = c.base05;
            PasswordIconColor = c.base05;
            PlaceholderTextColor = c.base03;
            WarningColor = c.base08;

            LoginButtonBackgroundColor = c.base0D;
            LoginButtonTextColor = c.base00;

            SystemButtonsIconsColor = c.base05;
            SessionButtonTextColor = c.base05;
            VirtualKeyboardButtonTextColor = c.base05;

            DropdownBackgroundColor = c.base01;
            DropdownSelectedBackgroundColor = c.base02;
            DropdownTextColor = c.base05;

            HighlightBackgroundColor = c.base0D;
            HighlightTextColor = c.base00;
            HighlightBorderColor = "transparent";

            HoverUserIconColor = c.base0D;
            HoverPasswordIconColor = c.base0D;
            HoverSystemButtonsIconsColor = c.base0D;
            HoverSessionButtonTextColor = c.base0D;
            HoverVirtualKeyboardButtonTextColor = c.base0D;
          }
          // lib.optionalAttrs hasBg (lib.genAttrs fgKeys (_: fg) // {
            PlaceholderTextColor = c.base04;
            HighlightBorderColor = c.base0D;
            LoginFieldBackgroundColor = fieldBg;
            PasswordFieldBackgroundColor = fieldBg;
            DropdownBackgroundColor = fieldBg;
            DropdownSelectedBackgroundColor = fieldSelBg;
          });

      effectiveThemeConfig =
        {
          Font = "JetBrainsMono Nerd Font";
          # Empty = the theme derives it from the screen height (patched to height / 90, the upstream 12 at 1080), so every size in the theme scales with the screen
          FontSize = "";
        }
        // lib.optionalAttrs (!cfg.use24HourClock) { HourFormat = "hh:mm AP"; }
        // backgroundConfig
        // stylixThemeConfig
        // cfg.themeConfig;

      baseTheme = pkgs.sddm-astronaut.override {
        inherit (cfg) embeddedTheme;
      };

      themePath = "$out/share/sddm/themes/sddm-astronaut-theme";
      confPath = "${themePath}/Themes/${cfg.embeddedTheme}.conf";

      escapeSedRepl = s: lib.replaceStrings [ "|" "&" "\\" ] [ "\\|" "\\&" "\\\\" ] s;
      patchLine = k: v: ''sed -i 's|^${k}="[^"]*"|${k}="${escapeSedRepl v}"|' ${confPath}'';

      # Build-time contrast measurement: picks the weakest backing opacity from
      # a ladder whose blurred, dimmed region keeps >= 4.5:1 against the text
      # colour for all but 2% of pixels. Never fails the build.
      measureScript = ''
        measure_bg() {
          ${if isVideo then ''
            ffmpeg -loglevel error -y -i ${bgPath} -frames:v 1 frame.png || return 1
            src=frame.png
          '' else ''
            src=${bgPath}
          ''}
          formpos=$(sed -n 's/^FormPosition="\([^"]*\)".*/\1/p' ${confPath})
          case "$formpos" in
            left) x=0 ;;
            right) x=1152 ;;
            *) x=576 ;;
          esac
          magick "''${src}[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 +repage \
            -alpha off -crop 768x1080+$x+0 +repage -blur 0x16 base.png || return 1
          set -- $(awk -v F=${fgHex} '
            function lin(h, v) { v = strtonum("0x" h) / 255; return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
            BEGIN {
              L = 0.2126 * lin(substr(F, 1, 2)) + 0.7152 * lin(substr(F, 3, 2)) + 0.0722 * lin(substr(F, 5, 2))
              light = (L > 0.18)
              t = light ? (L + 0.05) / 4.5 - 0.05 : 4.5 * (L + 0.05) - 0.05
              printf "%.3f %d\n", t * 100, light
            }') || return 1
          thr=$1
          light=$2
          dpct=$(awk -v d="$DIM" 'BEGIN { printf "%d%%", d * 100 }')
          for op in 0.7 0.8 0.9; do
            opct=$(awk -v o="$op" 'BEGIN { printf "%d%%", o * 100 }')
            mean=$(magick base.png -fill "${bk}" -colorize "$dpct" -fill "${bk}" -colorize "$opct" \
              -colorspace RGB -grayscale Rec709Luminance -threshold "$thr%" -format '%[fx:mean]' info:) || return 1
            fail=$(awk -v m="$mean" -v l="$light" 'BEGIN { printf "%.4f", l ? m : 1 - m }')
            echo "sddm-astronaut: form=$formpos opacity=$op dim=$DIM fail_share=$fail"
            if awk -v f="$fail" 'BEGIN { exit !(f <= 0.02) }'; then
              FORM_OPACITY=$op
              return 0
            fi
          done
          return 1
        }

        FORM_OPACITY=0.7
        DIM=${dimBase}
        if ! measure_bg; then
          echo "sddm-astronaut: measurement unavailable or no step passed, using strongest"
          FORM_OPACITY=0.9
          ${lib.optionalString (!dimUser) "DIM=0.5"}
        fi
        echo "sddm-astronaut: FORM_OPACITY=$FORM_OPACITY DIM=$DIM"
      '';

      # Accent pairs the upstream theme hardcodes as accent-on-form and text-on-accent, solved for any scheme and polarity:
      # an accent used as a mark must reach 3:1 on the form, else it becomes the text colour; the text on a filled accent,
      # the warning and the placeholder must reach 4.5:1 on what they sit on.
      pairsAwk = pkgs.writeText "sddm-astronaut-pairs.awk" ''
        function lin(x) { return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ^ 2.4 }
        function parse(h,  s) { s = h; sub(/^#/, "", s); return (strtonum("0x" substr(s, 1, 2)) / 255) " " (strtonum("0x" substr(s, 3, 2)) / 255) " " (strtonum("0x" substr(s, 5, 2)) / 255) }
        function chan(c, i,  a) { split(c, a, " "); return a[i] + 0 }
        function lum(c) { return 0.2126 * lin(chan(c, 1)) + 0.7152 * lin(chan(c, 2)) + 0.0722 * lin(chan(c, 3)) }
        function cr(c1, c2,  x, y) { x = lum(c1); y = lum(c2); return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05) }
        function mix(c1, c2, t) { return ((1 - t) * chan(c1, 1) + t * chan(c2, 1)) " " ((1 - t) * chan(c1, 2) + t * chan(c2, 2)) " " ((1 - t) * chan(c1, 3) + t * chan(c2, 3)) }
        function hex(c,  i, v, s) { s = "#"; for (i = 1; i <= 3; i++) { v = int(chan(c, i) * 255 + 0.5); if (v < 0) v = 0; if (v > 255) v = 255; s = s sprintf("%02x", v) } return s }
        # first of the scheme's own colours (form, text) that reads on c, else black or white, whichever reads better
        function on(c) {
          if (cr(bk, c) >= 4.5) return bk
          if (cr(fg, c) >= 4.5) return fg
          return cr("1 1 1", c) >= cr("0 0 0", c) ? "1 1 1" : "0 0 0"
        }
        # c pulled towards the text colour until it reaches 4.5:1 on bg
        function pull(c, bg,  t, x) {
          for (t = 0; t <= 1.0001; t += 0.05) { x = mix(c, fg, t); if (cr(x, bg) >= 4.5) return x }
          return fg
        }
        BEGIN {
          bk = parse(BK); fg = parse(FG); acc = parse(ACC); field = parse(FIELD)
          mark = cr(acc, bk) >= 3 ? acc : fg
          btn = mix(bk, acc, BTNA)
          printf "HoverUserIconColor=%s\nHoverPasswordIconColor=%s\nHoverSystemButtonsIconsColor=%s\nHoverSessionButtonTextColor=%s\nHoverVirtualKeyboardButtonTextColor=%s\n", hex(mark), hex(mark), hex(mark), hex(mark), hex(mark)
          printf "HighlightBackgroundColor=%s\nHighlightTextColor=%s\n", hex(acc), hex(on(acc))
          printf "LoginButtonBackgroundColor=%s\nLoginButtonTextColor=%s\n", hex(acc), hex(on(btn))
          printf "WarningColor=%s\nPlaceholderTextColor=%s\n", hex(pull(parse(WARN), bk)), hex(pull(parse(PH), field))
        }
      '';

      sddmTheme =
        pkgs.runCommandLocal "sddm-astronaut-patched"
          {
            nativeBuildInputs = lib.optionals hasBg
              ([ pkgs.imagemagick ] ++ lib.optional isVideo pkgs.ffmpeg-headless);
          } ''
          mkdir -p $out
          cp -r ${baseTheme}/. $out/
          chmod -R u+w $out

          # Drop any upstream .conf.user so our direct .conf edits are authoritative.
          rm -f ${themePath}/Themes/*.conf.user

          ${lib.optionalString hasBg ''
            cp ${bgPath} ${themePath}/Backgrounds/${bgFilename}
            sed -i 's|^Background="[^"]*"|Background="Backgrounds/${bgFilename}"|' ${confPath}
          ''}

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList patchLine effectiveThemeConfig)}

          ${lib.optionalString stylixEnabled ''
            # Solved accent pairs; a key the host sets in themeConfig keeps the host's value
            awk -f ${pairsAwk} -v BK='${pairBk}' -v FG='${pairFg}' -v ACC='${pairAcc}' -v FIELD='${pairField}' -v WARN='${pairWarn}' -v PH='${pairPh}' -v BTNA=${if hasBg then "0.6" else "0.2"} \
              | while IFS== read -r k v; do
                  case " ${lib.concatStringsSep " " (builtins.attrNames cfg.themeConfig)} " in *" $k "*) continue ;; esac
                  sed -i "s|^$k=\"[^\"]*\"|$k=\"$v\"|" ${confPath}
                done
          ''}

          # Sizes: the theme's layout is proportional to its font size, and the font size is a fixed 12pt unless the config is emptied;
          # the corner radius is a fixed 20 px. Tie both to the same screen-derived font size so the form keeps its proportions at any resolution.
          ${lib.optionalString (!(cfg.themeConfig ? FontSize)) ''
            if [ -f ${themePath}/Main.qml ]; then
              substituteInPlace ${themePath}/Main.qml --replace-fail 'parseInt(height / 80)' 'parseInt(height / 90)'
            fi
          ''}
          ${lib.optionalString (!(cfg.themeConfig ? RoundCorners)) ''
            if [ -f ${themePath}/Components/Input.qml ]; then
              substituteInPlace ${themePath}/Components/Input.qml ${themePath}/Components/SessionButton.qml \
                --replace-fail 'config.RoundCorners' '(root.font.pointSize * 5 / 3)'
            fi
          ''}

          # sed is a silent no-op when a key is missing; a clock that quietly stays 24h must fail the build instead.
          ${lib.optionalString (effectiveThemeConfig ? HourFormat) ''
            grep -qxF ${lib.escapeShellArg ''HourFormat="${effectiveThemeConfig.HourFormat}"''} ${confPath} \
              || { echo "sddm-astronaut: HourFormat not applied, the theme conf layout changed" >&2; exit 1; }
          ''}

          ${lib.optionalString hasBg ''
            ${measureScript}
            ${lib.optionalString (!dimUser) ''
              sed -i "s|^DimBackground=\"[^\"]*\"|DimBackground=\"$DIM\"|" ${confPath}
            ''}

            cd ${themePath}
            substituteInPlace Main.qml --replace-fail \
              'opacity: config.PartialBlur == "true" ? 0.3 : 1' \
              "opacity: config.PartialBlur == \"true\" ? $FORM_OPACITY : 1"

            substituteInPlace Components/Input.qml \
              --replace-fail $'color: config.LoginFieldBackgroundColor\n                opacity: 0.2\n                border.color: "transparent"' \
                             $'color: config.LoginFieldBackgroundColor\n                opacity: 1.0\n                border.color: "${fieldBorder}"' \
              --replace-fail $'color: config.PasswordFieldBackgroundColor\n                opacity: 0.2\n                border.color: "transparent"' \
                             $'color: config.PasswordFieldBackgroundColor\n                opacity: 1.0\n                border.color: "${fieldBorder}"' \
              --replace-fail $'color: config.LoginButtonTextColor\n                text: parent.text\n                opacity: 0.5' \
                             $'color: config.LoginButtonTextColor\n                text: parent.text\n                opacity: 1.0' \
              --replace-fail $'color: config.LoginButtonBackgroundColor\n                opacity: 0.2' \
                             $'color: config.LoginButtonBackgroundColor\n                opacity: 0.6'

            substituteInPlace Components/Clock.qml \
              --replace-fail 'import QtQuick.Controls 2.15' 'import QtQuick.Controls 2.15
            import QtQuick.Effects' \
              --replace-fail '    id: clock' '    id: clock

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "${bk}"
                    shadowOpacity: 0.9
                    shadowBlur: 0.6
                    shadowVerticalOffset: 1
                }'

            substituteInPlace Components/LoginForm.qml \
              --replace-fail 'import QtQuick.Layouts 1.15' 'import QtQuick.Layouts 1.15
            import QtQuick.Effects' \
              --replace-fail '        id: systemButtons' '        id: systemButtons

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "${bk}"
                    shadowOpacity: 0.9
                    shadowBlur: 0.6
                    shadowVerticalOffset: 1
                }'
          ''}
        '';
    in
    {
      assertions = [{
        assertion = !(myconfig.services.sddm-pixie.enable or false);
        message = "services.sddm-astronaut and services.sddm-pixie are mutually exclusive - enable only one in your host config.";
      }];

      services = {
        xserver = {
          enable = true;
          excludePackages = [ pkgs.xterm ];
        };

        displayManager = {
          sddm = {
            enable = true;
            wayland.enable = true;
            package = lib.mkForce pkgs.kdePackages.sddm;
            theme = "sddm-astronaut-theme";

            settings = {
              General = {
                InputMethod = "qtvirtualkeyboard";
              };
            };

            extraPackages = with pkgs; [
              kdePackages.qtsvg
              kdePackages.qtmultimedia
              kdePackages.qtvirtualkeyboard
              kdePackages.qtdeclarative
              gst_all_1.gstreamer
              gst_all_1.gst-plugins-base
              gst_all_1.gst-plugins-good
              gst_all_1.gst-plugins-bad
              gst_all_1.gst-libav
            ];
          };

          autoLogin = {
            enable = false;
            user = myconfig.constants.user;
          };
        };

        getty.autologinUser = null;
      };

      systemd.services.display-manager.environment = {
        QT_IM_MODULE = "qtvirtualkeyboard";
        QT_VIRTUALKEYBOARD_DESKTOP_DISABLE = "1";
      };

      fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      environment.systemPackages = [ sddmTheme ];
    };
}
