{ delib
, pkgs
, lib
, inputs
, ...
}:
delib.module {
  name = "services.sddm-qylock";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;

      theme = lib.mkOption {
        type = lib.types.str;
        default = "pixel-hollowknight";
        example = "nier-automata";
        description = ''
          Theme directory name under qylock's themes/ (same as the official
          `programs.qylock.theme`). Only this theme is put in the store, not
          the whole 570 MB collection.
        '';
      };

      themeOptions = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        example = lib.literalExpression ''
          {
            terraria.backgroundMode = "time";
            osu.gameMode = "menu";
          }
        '';
        description = ''
          Per-theme tweaks applied to theme.conf at build time, identical to
          the official `programs.qylock.themeOptions` (terraria, Genshin,
          clockwork.orbital / clockwork.tape, osu, osumania).
        '';
      };

      use24HourClock = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Greeter clock format. false (default) = 12-hour with AM/PM, true =
          the theme's own 24-hour "HH:mm". The themes draw the clock from a
          hardcoded Qt format string, so this is independent of LC_TIME. Only
          themes with an "HH:mm" clock are rewritten; the other 12 themes
          (terraria, nier-automata, Genshin, ...) keep their own clock.
        '';
      };

      assetsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Directory that a plain filename in `background` is resolved in.
          null means users/<user>/src/sddm/ (user = constants.user).
        '';
      };

      background = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
        default = null;
        description = ''
          Custom background: a path, or a plain filename resolved in
          users/<user>/src/sddm/. It replaces the theme's own background file
          (bg.mp4, bg.png or background.png), so it must be the same kind as
          the theme's: a video for a video theme (e.g. pixel-hollowknight), an
          image for an image theme. Themes without a single background file
          (Genshin, clockwork, osu, osumania, skyrim, terraria, nothing,
          R1999_2) are rejected at evaluation.
        '';
      };

      backgroundDim = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "0.4";
        description = ''
          Black scrim over a custom background, 0 to 1. null (default) = the
          weakest step of 0 / 0.2 / 0.35 / 0.5 / 0.65 / 0.8 for which at most
          2% of the first frame's pixels stay below 4.5:1 against the theme's
          text colour (`color` in theme.conf, else #f0f0f0); strongest step if
          none passes. Only used with `background`. Image themes get it baked
          into the picture; video themes need the shared BackgroundVideo.qml
          (the pixel-*, enfield and sword themes), others get no scrim.
        '';
      };
    };

  nixos.ifEnabled =
    { myconfig
    , cfg
    , ...
    }:
    let
      src = inputs.qylock;
      themeSrc = src + "/themes/${cfg.theme}";
      themeFiles =
        if builtins.pathExists themeSrc then builtins.readDir themeSrc
        else throw "services.sddm-qylock: theme '${cfg.theme}' not found in qylock's themes/";

      sddmDir =
        if cfg.assetsDir != null then cfg.assetsDir
        else ../../../../users + "/${myconfig.constants.user}/src/sddm";
      resolveImg = name:
        if name == null || builtins.isPath name || lib.hasPrefix builtins.storeDir name then name
        else if lib.hasPrefix "/" name then
          throw "${name}: absolute paths outside the store are impure; pass a path value or a filename in users/${myconfig.constants.user}/src/sddm/"
        else
          let p = sddmDir + "/${name}"; in
          if builtins.pathExists p then p
          else throw "${name} not found in users/${myconfig.constants.user}/src/sddm/";
      bgPath = resolveImg cfg.background;
      hasBg = bgPath != null;

      extOf = path:
        let parts = lib.splitString "." (builtins.baseNameOf (toString path));
        in if builtins.length parts > 1 then lib.toLower (lib.last parts) else "";
      videoExts = [ "avi" "mp4" "mov" "mkv" "m4v" "webm" "gif" ];
      isVideoFile = path: builtins.elem (extOf path) videoExts;

      # The one file the theme loads as its background, if it has exactly that shape.
      bgCandidates = builtins.filter (f: themeFiles ? ${f}) [ "bg.mp4" "bg.png" "background.png" ];
      themeBgFile =
        if bgCandidates == [ ] then null else builtins.head bgCandidates;
      themeBgIsVideo = themeBgFile != null && lib.hasSuffix ".mp4" themeBgFile;
      isVideo = hasBg && themeBgIsVideo;
      hasOverlayQml = themeFiles ? "BackgroundVideo.qml";

      bgChecked =
        if !hasBg then null
        else if themeBgFile == null then
          throw "services.sddm-qylock: theme '${cfg.theme}' has no single bg.mp4/bg.png/background.png, so `background` is not supported for it"
        else if isVideoFile bgPath != themeBgIsVideo then
          throw "services.sddm-qylock: theme '${cfg.theme}' uses a ${if themeBgIsVideo then "video" else "image"} background (${themeBgFile}); `background` must be a ${if themeBgIsVideo then "video" else "picture"}"
        else bgPath;

      # Same per-theme tweaks as the official flake (mkConfEdits), applied to the installed copy.
      confEdits =
        let
          o = name: cfg.themeOptions.${name} or { };
          sed = file: pat: ''
            if [ -f "${file}" ]; then sed -i "${pat}" "${file}"; fi
          '';
          t = "$out/share/sddm/themes";
          terraria = o "terraria";
          genshin = o "Genshin";
          orbital = (o "clockwork").orbital or { };
          tape = (o "clockwork").tape or { };
          osu = o "osu";
          osumania = o "osumania";
          opt = set: key: file: pat: lib.optionalString (set ? ${key}) (sed "${t}/${file}" pat);
        in
        lib.concatStrings [
          (opt terraria "backgroundMode" "terraria/theme.conf" "s/^background_mode=.*/background_mode=${terraria.backgroundMode or ""}/")
          (opt terraria "backgroundIndex" "terraria/theme.conf" "s/^background_index=.*/background_index=${toString (terraria.backgroundIndex or "")}/")
          (opt genshin "backgroundMode" "Genshin/theme.conf" "s/^background_mode=.*/background_mode=${genshin.backgroundMode or ""}/")
          (opt genshin "backgroundIndex" "Genshin/theme.conf" "s/^background_index=.*/background_index=${toString (genshin.backgroundIndex or "")}/")
          (opt orbital "themeMode" "clockwork/orbital/theme.conf" "s/^themeMode=.*/themeMode=${orbital.themeMode or ""}/")
          (opt orbital "enableWindup" "clockwork/orbital/theme.conf" "s/^enableWindup=.*/enableWindup=${lib.boolToString (orbital.enableWindup or false)}/")
          (opt tape "themeMode" "clockwork/tape/theme.conf" "s/^themeMode=.*/themeMode=${tape.themeMode or ""}/")
          (opt osu "gameMode" "osu/theme.conf" "s/^gameMode=.*/gameMode=${osu.gameMode or ""}/")
          (opt osumania "gameMode" "osumania/theme.conf" "s/^gameMode=.*/gameMode=${osumania.gameMode or ""}/")
        ];

      themeDir = "$out/share/sddm/themes/${cfg.theme}";

      # Build-time contrast measurement: weakest scrim step keeping the theme's text >= 4.5:1 on all but 2% of
      # the (first frame of the) background. Light text is assumed (every qylock theme draws light text).
      steps = [ "0" "0.2" "0.35" "0.5" "0.65" "0.8" ];
      measureScript = ''
        DIM=0.8
        fg=$(sed -n 's/^color=#\([0-9a-fA-F]\{6\}\).*/\1/p' ${themeDir}/theme.conf 2>/dev/null | head -n1)
        fg=''${fg:-f0f0f0}
        ${if isVideo then ''
          ffmpeg -loglevel error -y -i ${bgChecked} -frames:v 1 frame.png && src=frame.png || src=
        '' else ''
          src=${if hasBg then bgChecked else ""}
        ''}
        if [ -n "$src" ] && magick "''${src}[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 +repage -alpha off base.png; then
          thr=$(awk -v F="$fg" '
            function lin(h, v) { v = strtonum("0x" h) / 255; return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
            BEGIN { L = 0.2126 * lin(substr(F, 1, 2)) + 0.7152 * lin(substr(F, 3, 2)) + 0.0722 * lin(substr(F, 5, 2)); printf "%.3f", ((L + 0.05) / 4.5 - 0.05) * 100 }')
          for d in ${lib.concatStringsSep " " steps}; do
            dpct=$(awk -v d="$d" 'BEGIN { printf "%d%%", d * 100 }')
            mean=$(magick base.png -fill black -colorize "$dpct" -colorspace RGB -grayscale Rec709Luminance -threshold "$thr%" -format '%[fx:mean]' info: || echo 1)
            echo "sddm-qylock: dim=$d fail_share=$mean"
            if awk -v m="$mean" 'BEGIN { exit !(m <= 0.02) }'; then DIM=$d; break; fi
          done
        else
          echo "sddm-qylock: measurement unavailable, using strongest dim"
        fi
      '';

      sddmTheme =
        pkgs.runCommandLocal "sddm-qylock-${cfg.theme}"
          {
            nativeBuildInputs = lib.optionals hasBg
              ([ pkgs.imagemagick ] ++ lib.optional isVideo pkgs.ffmpeg-headless);
          } ''
          mkdir -p $out/share/sddm/themes
          cp -r ${themeSrc} ${themeDir}
          chmod -R u+w $out

          ${confEdits}

          ${lib.optionalString (!cfg.use24HourClock) ''
            # Only themes that draw their clock with the "HH:mm" format string can be switched; the others (no clock, or their own format) stay as shipped.
            if grep -q '"HH:mm"' ${themeDir}/Main.qml; then
              sed -i 's/"HH:mm"/"hh:mm AP"/g' ${themeDir}/Main.qml
            else
              echo "sddm-qylock: no \"HH:mm\" clock in ${cfg.theme}/Main.qml, clock left as the theme ships it"
            fi
          ''}

          ${lib.optionalString hasBg ''
            ${if cfg.backgroundDim != null then "DIM=${cfg.backgroundDim}" else measureScript}
            echo "sddm-qylock: DIM=$DIM"
            ${if isVideo then ''
              cp ${bgChecked} ${themeDir}/${themeBgFile}
              ${if hasOverlayQml then ''
                awk -v d="$DIM" '{ l[NR] = $0 } END { for (i = NR; i > 0; i--) if (l[i] == "}") { k = i; break } for (i = 1; i <= NR; i++) { if (i == k) print "    Rectangle { anchors.fill: parent; color: \"black\"; opacity: " d " }"; print l[i] } }' \
                  ${themeDir}/BackgroundVideo.qml > BackgroundVideo.qml.new
                mv BackgroundVideo.qml.new ${themeDir}/BackgroundVideo.qml
                grep -q "opacity: $DIM" ${themeDir}/BackgroundVideo.qml \
                  || { echo "sddm-qylock: BackgroundVideo.qml scrim not applied" >&2; exit 1; }
              '' else ''
                echo "sddm-qylock: ${cfg.theme} has no BackgroundVideo.qml, no scrim applied"
              ''}
            '' else ''
              magick ${bgChecked} -fill black -colorize "$(awk -v d="$DIM" 'BEGIN { printf "%d%%", d * 100 }')" ${themeDir}/${themeBgFile}
            ''}
          ''}
        '';
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
            theme = cfg.theme;

            # The QML modules the themes import (Qt5Compat.GraphicalEffects, QtMultimedia), as the official qylock module wires them
            extraPackages = with pkgs; [
              sddmTheme
              kdePackages.qt5compat
              kdePackages.qtmultimedia
              kdePackages.qtsvg
              kdePackages.qtdeclarative
              # background videos
              gst_all_1.gstreamer
              gst_all_1.gst-plugins-base
              gst_all_1.gst-plugins-good
              gst_all_1.gst-plugins-bad
              gst_all_1.gst-plugins-ugly
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

      environment.systemPackages = [ sddmTheme ];
    };
}
