{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "services.sddm-pixie";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      themeConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          accentColor = "#A9C78F";
        };
        description = "Attribute set of theme.conf options to override";
      };
      background = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
        default = null;
        description = "Custom background image: a path, or a plain filename resolved in users/<user>/src/sddm/";
      };
      avatar = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
        default = null;
        description = "Custom avatar image: a path, or a plain filename resolved in users/<user>/src/sddm/";
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
      avatarPath = resolveImg cfg.avatar;
      accentColor = config.lib.stylix.colors.withHashtag.base0E;
      fontFamily = cfg.themeConfig.fontFamily or "JetBrainsMono Nerd Font";
      getExtension = path:
        let
          filename = builtins.baseNameOf (toString path);
          parts = lib.splitString "." filename;
        in
        if builtins.length parts > 1
        then lib.last parts
        else "jpg";

      bgExt = if bgPath != null then getExtension bgPath else "jpg";
      bgFilename = "background.${bgExt}";

      hasBg = bgPath != null;
      stylixOn = config.stylix.enable or false;

      # Perceptual luma (0..255000) of a base16 hex colour, pure Nix.
      ch = hex: i: lib.fromHexString (builtins.substring i 2 hex);
      luma = hex: 2126 * ch hex 0 + 7152 * ch hex 2 + 722 * ch hex 4;
      sat = hex:
        let
          mx = lib.max (ch hex 0) (lib.max (ch hex 2) (ch hex 4));
          mn = lib.min (ch hex 0) (lib.min (ch hex 2) (ch hex 4));
        in
        if mx == 0 then 0.0 else (mx - mn) * 1.0 / mx;
      lightestOf = lib.foldl' (a: b: if luma b > luma a then b else a);
      darkestOf = lib.foldl' (a: b: if luma b < luma a then b else a);

      # The theme always dims with black, so text is the lightest and backing the darkest neutral.
      pal =
        if hasBg && stylixOn then
          let
            c = config.lib.stylix.colors;
            neutrals = [ c.base00 c.base01 c.base02 c.base03 c.base04 c.base05 c.base06 c.base07 ];
            vivid = builtins.filter (h: sat h >= 0.15) [ c.base08 c.base09 c.base0A c.base0B c.base0C c.base0D c.base0E c.base0F ];
            light = lightestOf c.base00 neutrals;
          in
          {
            text = "#${light}";
            bk = "#${darkestOf c.base00 neutrals}";
            accent = "#${if vivid == [ ] then light else lightestOf (builtins.head vivid) vivid}";
          }
        else
          { text = "#f0f0f0"; bk = "#101010"; accent = "#f0f0f0"; };

      effectiveThemeConfig =
        { background = "assets/background.jpg"; }  # Default fallback (upstream asset)
        // { inherit accentColor; }  # Base16 accent from stylix
        // { inherit fontFamily; }
        // (lib.optionalAttrs hasBg {
          autoColor = "false";
          accentColor = pal.accent;
          textColor = pal.text;
          backgroundColor = pal.bk;
        })
        // cfg.themeConfig  # User overrides (can override accentColor if desired)
        // (lib.optionalAttrs hasBg { background = "assets/${bgFilename}"; });

      setKeys = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: "setKey ${k} ${lib.escapeShellArg v}") effectiveThemeConfig
      );

      textFixable = !(cfg.themeConfig ? textColor);
      accentFixable = !(cfg.themeConfig ? accentColor);

      paletteAwk = pkgs.writeText "sddm-pixie-palette.awk" ''
        function lin(x) { return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ^ 2.4 }
        function parse(h,  s) { s = h; sub(/^#/, "", s); return (strtonum("0x" substr(s, 1, 2)) / 255) " " (strtonum("0x" substr(s, 3, 2)) / 255) " " (strtonum("0x" substr(s, 5, 2)) / 255) }
        function chan(c, i,  a) { split(c, a, " "); return a[i] + 0 }
        function lum(c) { return 0.2126 * lin(chan(c, 1)) + 0.7152 * lin(chan(c, 2)) + 0.0722 * lin(chan(c, 3)) }
        function cr(c1, c2,  x, y) { x = lum(c1); y = lum(c2); return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05) }
        function mix(c1, c2, t) { return ((1 - t) * chan(c1, 1) + t * chan(c2, 1)) " " ((1 - t) * chan(c1, 2) + t * chan(c2, 2)) " " ((1 - t) * chan(c1, 3) + t * chan(c2, 3)) }
        function hex(c,  i, v, s) { s = "#"; for (i = 1; i <= 3; i++) { v = int(chan(c, i) * 255 + 0.5); if (v < 0) v = 0; if (v > 255) v = 255; s = s sprintf("%02x", v) } return s }
        function q(c) { return parse(hex(c)) }
        function grey(w) { return w " " w " " w }
        # login card: backgroundColor at 0.88 over the dimmed wallpaper (login dim 0.8 leaves at most 0.2, the header backing on the lock screen at most 0.6)
        function cardok(F, base,  i, n, W) {
          n = split("0 0.2 0.6", W, " ")
          for (i = 1; i <= n; i++) if (cr(F, mix(base, grey(W[i]), 0.12)) < MIN) return 0
          return 1
        }
        function solid(F, base, s1, s2) {
          return cr(F, base) >= MIN && cr(F, s1) >= MIN && cr(F, s2) >= MIN && cardok(F, base)
        }
        BEGIN {
          MIN = 4.6
          T = parse(TEXT); A = parse(ACC)
          white = "1 1 1"; black = "0 0 0"
          if (MODE == "lock") {
            w = grey(0.1)
            t2 = (FIXTEXT == 1 && cr(T, w) < MIN) ? "#f0f0f0" : TEXT
            a2 = (FIXACC == 1 && cr(A, w) < 3.3) ? t2 : ACC
            printf "TEXT=%c%s%c ACC=%c%s%c\n", 39, t2, 39, 39, a2, 39
            exit
          }
          B = parse(BACK)
          cand[1] = T; cand[2] = white; cand[3] = black
          best = 9
          for (i = 1; i <= 3; i++) {
            F = cand[i]; K = lum(F) >= 0.18 ? black : white
            tt[i] = 9
            for (n = 0; n <= 50; n++) {
              t = n / 50; b = q(mix(B, K, t)); s1 = q(mix(b, F, 0.10)); s2 = q(mix(b, F, 0.22))
              if (solid(F, b, s1, s2)) { tt[i] = t; fb[i] = b; fs1[i] = s1; fs2[i] = s2; break }
            }
            if (tt[i] < best) best = tt[i]
          }
          for (i = 1; i <= 3; i++) if (tt[i] <= best + 0.1) { pick = i; break }
          F = cand[pick]; base = fb[pick]; s1 = fs1[pick]; s2 = fs2[pick]
          if (cr(A, base) >= MIN && cr(A, s1) >= MIN && cr(A, s2) >= MIN) { sa = A; sname = "accent" } else { sa = F; sname = "text" }
          ona = cr(white, sa) >= cr(black, sa) ? white : black
          press = ona == white ? "darker" : "lighter"
          if (cardok(A, base)) { h = A; hname = "container.extractedAccent" } else { h = F; hname = "container.fgColor" }
          err = base
          for (k = 7; k >= 0; k--) {
            e = q(mix(base, "0.8 0.2 0.2", k * 0.05))
            if (cardok(F, e) && cardok(h, e)) { err = e; break }
          }
          pa = "1.0"
          for (a = 0.6; a < 1.0; a += 0.1) if (cr(mix(s1, F, a), s1) >= MIN) { pa = sprintf("%.1f", a); break }
          printf "BASE=%s S1=%s S2=%s FG=%s SURFACE_ACCENT=%s SURFACE_NAME=%s TEXT_ON_ACCENT=%s PRESS_FN=%s HEADER_FG=%s ERROR_CARD=%s PLACEHOLDER_ALPHA=%s\n", hex(base), hex(s1), hex(s2), hex(F), hex(sa), sname, hex(ona), press, hname, hex(err), pa
        }
      '';

      shadow = indent: ''
        ${indent}layer.enabled: true
        ${indent}layer.effect: MultiEffect {
        ${indent}    shadowEnabled: true
        ${indent}    shadowColor: "${pal.bk}"
        ${indent}    shadowOpacity: 0.9
        ${indent}    shadowBlur: 0.6
        ${indent}    shadowVerticalOffset: 1
        ${indent}}
      '';

      # What the greeter really renders (user themeConfig overrides included), so measuring matches it.
      fgAccent = effectiveThemeConfig.accentColor;
      fgText = effectiveThemeConfig.textColor;
      fgBack = effectiveThemeConfig.backgroundColor;

      # Same surface as the login card (backgroundColor at 0.88), so the header text has the card's contrast on any wallpaper.
      backing = indent: target: ''
        ${indent}Rectangle {
        ${indent}    z: 99
        ${indent}    radius: 16
        ${indent}    color: Qt.rgba(container.baseColor.r, container.baseColor.g, container.baseColor.b, 0.88)
        ${indent}    anchors { fill: ${target}; leftMargin: -18; rightMargin: -18; topMargin: -10; bottomMargin: -10 }
        ${indent}    opacity: container.uiReady ? 1 : 0
        ${indent}}
      '';

      # Build-time check of the wallpaper under the theme's dim, then QML patches. Never fails the build.
      measureAndPatch = ''
        theme=$out/share/sddm/themes/pixie
        img=$theme/assets/${bgFilename}
        work=$(mktemp -d)
        LOCK_DIM=0.9
        LOGIN_DIM=0.8  # login card and header carry their own backing, nothing on the wallpaper to measure

        lum() {
          awk -v h="''${1#\#}" '
            function lin(x) { x = x / 255; return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ^ 2.4 }
            BEGIN { print 0.2126 * lin(strtonum("0x" substr(h, 1, 2))) + 0.7152 * lin(strtonum("0x" substr(h, 3, 2))) + 0.0722 * lin(strtonum("0x" substr(h, 5, 2))) }'
        }

        # failshare <png> <geometry> <fg hex> <ratio> <dim>: share of pixels below the ratio
        failshare() {
          local t s
          t=$(awk -v l="$(lum "$3")" -v r="$4" 'BEGIN { t = (l + 0.05) / r - 0.05; if (t < 0) t = 0; printf "%.4f", t * 100 }') || t=0
          s=$(magick "$1" -crop "$2" +repage -alpha off -evaluate Multiply "$(awk -v a="$5" 'BEGIN { print 1 - a }')" \
            -colorspace RGB -grayscale Rec709Luminance -threshold "$t%" -format '%[fx:mean]' info: 2>/dev/null) || s=1
          echo "''${s:-1}"
        }

        # pick <var> <png> <steps> <region>...: weakest step where every region (geo|fg|ratio) has <= 2% failing pixels
        pick() {
          local var=$1 png=$2 steps=$3 step ok r share geo fg ratio
          shift 3
          for step in $steps; do
            ok=1
            for r in "$@"; do
              IFS='|' read -r geo fg ratio <<< "$r"
              share=$(failshare "$png" "$geo" "$fg" "$ratio" "$step")
              echo "sddm-pixie: $var=$step region=$geo fail=$share"
              if awk -v s="$share" 'BEGIN { exit !(s > 0.02) }'; then ok=0; fi
            done
            if [ "$ok" = 1 ]; then printf -v "$var" '%s' "$step"; return 0; fi
          done
          echo "sddm-pixie: $var: no step passed, using strongest"
        }

        TEXT="${fgText}"
        ACC="${fgAccent}"
        BACK="${fgBack}"

        # The lock screen dims with black (at most 0.9), so a scheme text/accent too dark for the brightest wallpaper under that dim falls back
        eval "$(awk -f ${paletteAwk} -v MODE=lock -v TEXT="$TEXT" -v ACC="$ACC" -v FIXTEXT=${if textFixable then "1" else "0"} -v FIXACC=${if accentFixable then "1" else "0"})"
        if [ "$TEXT" != "${fgText}" ]; then setKey textColor "$TEXT"; fi
        if [ "$ACC" != "${fgAccent}" ]; then setKey accentColor "$ACC"; fi

        # Card, field and row surfaces plus every foreground on them, solved so each state reaches 4.5:1 for any scheme
        eval "$(awk -f ${paletteAwk} -v MODE=card -v TEXT="$TEXT" -v ACC="$ACC" -v BACK="$BACK")"

        if magick "''${img}[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 +repage -alpha off "$work/base.png" 2>/dev/null \
          && magick "$work/base.png" -blur 0x5 "$work/lock.png"; then
          pick LOCK_DIM "$work/lock.png" "0.4 0.5 0.6 0.7 0.8 0.9" \
            "300x420+810+330|$ACC|3" "420x40+750+940|$TEXT|4.5" || true
        else
          echo "sddm-pixie: background measurement failed, using strongest dim"
        fi
        echo "sddm-pixie: lock dim=$LOCK_DIM login dim=$LOGIN_DIM header fg=$HEADER_FG surface fg=$SURFACE_NAME placeholder alpha=$PLACEHOLDER_ALPHA text=$FG base=$BASE"

        substituteInPlace $theme/Main.qml \
          --replace-fail 'loginState.visible ? 0.6 : 0.4' "loginState.visible ? $LOGIN_DIM : $LOCK_DIM" \
          --replace-fail 'blur: loginState.visible ? 1.0 : 0.0
                opacity: loginState.visible ? 1.0 : 0.0' 'blur: loginState.visible ? 1.0 : 0.5
                opacity: 1.0' \
          --replace-fail '        id: dateText
        ' '        id: dateText
        ${shadow "        "}' \
          --replace-fail '        textColor: container.extractedAccent
                z: 100
        ' '        textColor: @HEADER_FG@
                z: 100
        ${shadow "        "}' \
          --replace-fail '        color: container.extractedAccent
                font.pixelSize: 22' '        color: @HEADER_FG@
                z: 100
                font.pixelSize: 22' \
          --replace-fail '    PowerBar {' '    // Header backing: the login card surface behind the date and the power bar
        ${backing "    " "dateText"}
        ${backing "    " "headerPower"}
            PowerBar {
                id: headerPower' \
          --replace-fail '                colorExtractor.processed = false;
                        colorDelay.start();' '                colorExtractor.processed = false;
                        if (config.autoColor === "true") colorDelay.start();' \
          --replace-fail '        onPaint: {
                    var ctx = getContext("2d");
                    var res = 60;' '        onPaint: {
                    if (config.autoColor !== "true") return;
                    var ctx = getContext("2d");
                    var res = 60;' \
          --replace-fail 'bottomMargin: 100
                    }
                    opacity: 0.5
        ' 'bottomMargin: 100
                    }
                    opacity: 1.0
        ${shadow "            "}' \
          --replace-fail 'color: loginState.isError ? "#442222" : baseColor
                    opacity: 0.7' 'color: Qt.rgba(container.cardColor.r, container.cardColor.g, container.cardColor.b, 0.88)
                    opacity: 1.0' \
          --replace-fail 'text: container.isLoggingIn ? "⋯" : "→"
                                color: "white"' 'text: container.isLoggingIn ? "⋯" : "→"
                                color: container.isLoggingIn ? container.fgColor : container.textOnAccent' \
          --replace-fail 'color: container.isLoggingIn ? surfaceVariantColor : (loginButton.pressed ? Qt.darker(container.extractedAccent, 1.1) : container.extractedAccent)' "color: container.isLoggingIn ? surfaceVariantColor : (loginButton.pressed ? Qt.$PRESS_FN(container.surfaceAccent, 1.1) : container.surfaceAccent)" \
          --replace-fail 'text: "Num Lock is on"
                            color: container.extractedAccent' 'text: "Num Lock is on"
                            color: @HEADER_FG@' \
          --replace-fail 'color: container.extractedAccent
                                    font.pixelSize: 48' 'color: container.surfaceAccent
                                    font.pixelSize: 48' \
          --replace-fail 'text: "󰟀"
                                    color: container.extractedAccent' 'text: "󰟀"
                                    color: container.surfaceAccent' \
          --replace-fail 'text: "Enter Password"
                                color: "gray"' 'text: "Enter Password"
                                color: container.fgColor' \
          --replace-fail 'anchors.centerIn: parent
                                opacity: 0.5' "anchors.centerIn: parent
                                opacity: $PLACEHOLDER_ALPHA" \
          --replace-fail 'border.color: container.extractedAccent' 'border.color: container.surfaceAccent' \
          --replace-fail '? container.extractedAccent : surfaceVariantColor' '? container.surfaceAccent : surfaceVariantColor' \
          --replace-fail 'color: isCurrent ? baseColor : "white"' 'color: isCurrent ? container.textOnAccent : container.fgColor' \
          --replace-fail 'color: isCurrent ? "white" : (hovered ? "#DDDDDD" : "#AAAAAA")' 'color: container.fgColor' \
          --replace-fail 'color: isCurrent ? "white" : "#AAAAAA"' 'color: container.fgColor' \
          --replace-fail 'color: isCurrent ? container.extractedAccent : "gray"' 'color: isCurrent ? container.surfaceAccent : container.fgColor' \
          --replace-fail 'radius: 24
                    opacity: 0.95' 'radius: 24
                    opacity: 1.0' \
          --replace-fail 'property color baseColor: config.backgroundColor' "property color baseColor: \"$BASE\"" \
          --replace-fail 'property color surfaceColor: Qt.lighter(baseColor, 1.3)' "property color surfaceColor: \"$S1\"" \
          --replace-fail 'property color surfaceVariantColor: Qt.lighter(baseColor, 1.6)' "property color surfaceVariantColor: \"$S2\"
            property color fgColor: \"$FG\"
            property color surfaceAccent: \"$SURFACE_ACCENT\"
            property color textOnAccent: \"$TEXT_ON_ACCENT\"
            property color errorCardColor: \"$ERROR_CARD\"
            property color cardColor: loginState.isError ? errorCardColor : baseColor"

        sed -i -e '/width: 4$/,/radius: 2/ s/container\.extractedAccent/container.surfaceAccent/' -e 's/color: "white"/color: container.fgColor/' $theme/Main.qml
        if grep -nE '"(white|gray|#AAAAAA|#DDDDDD)"' $theme/Main.qml; then echo "sddm-pixie: hardcoded greys left in Main.qml"; exit 1; fi

        substituteInPlace $theme/Main.qml --replace-fail '@HEADER_FG@' "$HEADER_FG"

        substituteInPlace $theme/components/Clock.qml \
          --replace-fail 'import QtQuick

        Item {' 'import QtQuick
        import QtQuick.Effects

        Item {' \
          --replace-fail '        anchors.centerIn: parent
                spacing: 0
        ' '        anchors.centerIn: parent
                spacing: 0
        ${shadow "        "}'
      '';

      sddm-pixie = pkgs.stdenvNoCC.mkDerivation {
        pname = "sddm-pixie";
        version = "unstable-2025-01-01";

        src = pkgs.fetchFromGitHub {
          owner = "xCaptaiN09";
          repo = "pixie-sddm";
          rev = "1e1a863761f742e8d509d569382b17c112e29fdc";
          sha256 = "sha256-wV5XnU+4ME1HZAsGad+Lb+zTCqryn0WWo75FaoOFefc=";
        };

        nativeBuildInputs = lib.optional hasBg pkgs.imagemagick;

        dontBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/sddm/themes/pixie
          cp -r * $out/share/sddm/themes/pixie/

          conf=$out/share/sddm/themes/pixie/theme.conf
          chmod u+w "$conf"

          # Merge into the upstream conf so keys we do not set (use24HourClock, ...) survive
          if [ -n "$(tail -c1 "$conf")" ]; then echo >> "$conf"; fi
          setKey() {
            local v
            v=$(printf '%s' "$2" | sed 's/[&|\\]/\\&/g')
            if grep -q "^$1=" "$conf"; then sed -i "s|^$1=.*|$1=$v|" "$conf"; else echo "$1=$2" >> "$conf"; fi
          }
          ${setKeys}

          ${lib.optionalString hasBg ''
            cp ${bgPath} $out/share/sddm/themes/pixie/assets/${bgFilename}
            ${measureAndPatch}
          ''}

          # Layout bug independent of the background: long session names overflow the fixed 180px pill
          substituteInPlace $out/share/sddm/themes/pixie/Main.qml \
            --replace-fail 'Layout.preferredWidth: 180' 'Layout.preferredWidth: Math.min(340, Math.max(180, sessionRow.implicitWidth + 32))' \
            --replace-fail 'spacing: 8' 'id: sessionRow
                        spacing: 8' \
            --replace-fail 'font.pixelSize: 13' 'font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.maximumWidth: 284'

          ${lib.optionalString (avatarPath != null) ''
            cp ${avatarPath} $out/share/sddm/themes/pixie/assets/avatar.jpg
          ''}

          runHook postInstall
        '';
      };
    in
    {
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
            theme = "pixie";

            extraPackages = with pkgs.kdePackages; [
              qtdeclarative
              qtsvg
              qt5compat
              qtmultimedia # QtQuick.Effects itself ships in qtdeclarative
            ];
          };

          autoLogin = {
            enable = false;
            user = myconfig.constants.user;
          };
        };

        getty.autologinUser = null;
      };

      fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      environment.systemPackages = [
        sddm-pixie
      ];

      systemd.services.display-manager.environment =
        lib.optionalAttrs (myconfig.constants.lcTime != "") {
          LC_TIME = myconfig.constants.lcTime;
        };
    };
}
