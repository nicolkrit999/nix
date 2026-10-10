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
        if name == null || builtins.isPath name || lib.hasPrefix "/" name then name
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
        // { accentColor = accentColor; }  # Base16 accent from stylix
        // { fontFamily = fontFamily; }
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

      # Build-time check of the wallpaper under the theme's dim, then QML patches. Never fails the build.
      measureAndPatch = ''
        theme=$out/share/sddm/themes/pixie
        img=$theme/assets/${bgFilename}
        work=$(mktemp -d)
        LOCK_DIM=0.7
        LOGIN_DIM=0.8

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

        if magick "$img[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 +repage -alpha off "$work/base.png" 2>/dev/null \
          && magick "$work/base.png" -blur 0x5 "$work/lock.png" \
          && magick "$work/base.png" -blur 0x10 "$work/login.png"; then
          pick LOCK_DIM "$work/lock.png" "0.4 0.5 0.6 0.7" \
            "420x50+55+45|${pal.accent}|4.5" "360x50+1520+20|${pal.accent}|4.5" \
            "300x420+810+330|${pal.accent}|3" "420x40+750+940|${pal.text}|4.5" || true
          pick LOGIN_DIM "$work/login.png" "0.7 0.8" \
            "420x50+55+45|${pal.accent}|4.5" "360x50+1520+20|${pal.accent}|4.5" || true
        else
          echo "sddm-pixie: background measurement failed, using strongest dim"
        fi
        echo "sddm-pixie: lock dim=$LOCK_DIM login dim=$LOGIN_DIM"

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
        ' '        textColor: container.extractedAccent
                z: 100
        ${shadow "        "}' \
          --replace-fail 'bottomMargin: 100
                    }
                    opacity: 0.5
        ' 'bottomMargin: 100
                    }
                    opacity: 0.85
        ${shadow "            "}' \
          --replace-fail 'color: loginState.isError ? "#442222" : baseColor
                    opacity: 0.7' 'color: loginState.isError ? Qt.rgba(0.27, 0.13, 0.13, 0.88) : Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.88)
                    opacity: 1.0' \
          --replace-fail 'text: container.isLoggingIn ? "⋯" : "→"
                                color: "white"' 'text: container.isLoggingIn ? "⋯" : "→"
                                color: container.isLoggingIn ? config.textColor : container.baseColor'

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

          ${lib.optionalString (cfg.themeConfig != { } || hasBg) ''
            # Merge into the upstream conf so keys we do not set (use24HourClock, ...) survive
            if [ -n "$(tail -c1 "$conf")" ]; then echo >> "$conf"; fi
            setKey() {
              local v
              v=$(printf '%s' "$2" | sed 's/[&|\\]/\\&/g')
              if grep -q "^$1=" "$conf"; then sed -i "s|^$1=.*|$1=$v|" "$conf"; else echo "$1=$2" >> "$conf"; fi
            }
            ${setKeys}
          ''}

          sed -i 's|^fontFamily=.*|fontFamily=${fontFamily}|' "$conf"

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
      services.xserver.enable = true;
      services.xserver.excludePackages = [ pkgs.xterm ];

      services.displayManager.sddm = {
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

      fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      environment.systemPackages = [
        sddm-pixie
      ];

      systemd.services.display-manager.environment =
        lib.optionalAttrs (myconfig.constants.lcTime != "") {
          LC_TIME = myconfig.constants.lcTime;
        };

      services.displayManager.autoLogin = {
        enable = false;
        user = myconfig.constants.user;
      };

      services.getty.autologinUser = null;
    };
}
