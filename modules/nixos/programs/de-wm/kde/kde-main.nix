{ delib
, pkgs
, lib
, config
, inputs
, moduleSystem
, ...
}:
let
  rotationName = {
    "0" = "none";
    "90" = "left";
    "180" = "inverted";
    "270" = "right";
  };

  fmtNum = n:
    let m = builtins.match "([0-9]+)(\\.[0-9]*[1-9])?(\\.?0*)" (toString n);
    in if m == null then toString n else (builtins.elemAt m 0) + (if builtins.elemAt m 1 == null then "" else builtins.elemAt m 1);

  isFallback = m: m.output == "*";

  argsOf = m:
    let o = "output.${m.output}"; in
    if !m.enable then
      [ "${o}.disable" ]
    else
      [
        "${o}.enable"
        "${o}.mode.${toString m.width}x${toString m.height}@${fmtNum m.refresh}"
        "${o}.scale.${fmtNum m.scale}"
        "${o}.position.${toString m.x},${toString m.y}"
        "${o}.rotation.${rotationName.${toString m.transform}}"
        "${o}.mirror.${if m.mirror == "" then "none" else m.mirror}"
      ];

  planOf = monitors: map (m: lib.concatStringsSep " " (argsOf m)) (lib.filter (m: !isFallback m) monitors);

  nameCharsOk = name: builtins.match "[A-Za-z0-9_.:-]+" name != null;
in
delib.module {
  name = "programs.kde";

  options =
    with delib;
    moduleOptions {
      extraBinds = attrsOption { };
      mice = listOfOption attrs [ ];
      touchpads = listOfOption attrs [ ];
      pinnedApps = listOfOption str [ ];
      monitors = listOfOption
        (submodule {
          options = {
            output = strOption "*";
            width = intOption 0;
            height = intOption 0;
            refresh = numberOption 0;
            scale = numberOption 1.0;
            x = intOption 0;
            y = intOption 0;
            transform = enumOption [ 0 90 180 270 ] 0;
            enable = boolOption true;
            mirror = strOption "";
          };
        })
        [ ];
    };

  nixos.always = _: {
    home-manager.sharedModules = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
  };

  nixos.ifEnabled =
    { cfg, ... }:
    let
      named = lib.filter (m: !isFallback m) cfg.monitors;
      names = map (m: m.output) cfg.monitors;
      mirrored = lib.filter (m: m.enable && m.mirror != "") named;
    in
    {
      assertions = [
        {
          assertion = lib.length names == lib.length (lib.unique names);
          message = "programs.kde.monitors: output names must be unique";
        }
        {
          assertion = lib.length (lib.filter isFallback cfg.monitors) <= 1;
          message = "programs.kde.monitors: at most one \"*\" fallback entry is allowed";
        }
        {
          assertion = lib.all (m: isFallback m || nameCharsOk m.output) cfg.monitors;
          message = "programs.kde.monitors: output names may only contain letters, digits and _ . : -";
        }
        {
          assertion = lib.all (m: !m.enable || (m.width > 0 && m.height > 0 && m.refresh > 0)) named;
          message = "programs.kde.monitors: every enabled output needs width, height and refresh greater than 0";
        }
        {
          assertion = lib.all (m: m.scale > 0) cfg.monitors;
          message = "programs.kde.monitors: scale must be greater than 0";
        }
        {
          assertion = lib.all (m: m.mirror == "" || nameCharsOk m.mirror) cfg.monitors;
          message = "programs.kde.monitors: mirror names may only contain letters, digits and _ . : -";
        }
        {
          assertion = lib.all (m: m.mirror != m.output) mirrored;
          message = "programs.kde.monitors: an output cannot mirror itself";
        }
        {
          assertion = lib.all (m: lib.any (s: s.output == m.mirror && s.enable && s.mirror == "") named) mirrored;
          message = "programs.kde.monitors: a mirror source must be another declared, enabled output that does not itself mirror";
        }
      ];
    };

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
  };

  home.ifEnabled =
    { myconfig
    , parent
    , cfg
    , ...
    }:
    let
      plan = planOf cfg.monitors;

      inKdeSession = pkgs.writeShellScript "is-kde-session" ''
        case ":$XDG_CURRENT_DESKTOP:" in
          *:KDE:*) exit 0 ;;
        esac
        exit 1
      '';

      apply = pkgs.writeShellScript "kde-monitors-apply" ''
        set +e
        plan="''${XDG_CONFIG_HOME:-$HOME/.config}/kde-monitors/plan"
        doctor=${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor
        n=0
        until "$doctor" -o >/dev/null 2>&1; do
          n=$((n + 1))
          if [ "$n" -ge 30 ]; then
            echo "kde-monitors: KWin output management never became available; leaving the layout to KWin" >&2
            exit 0
          fi
          sleep 1
        done
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          # shellcheck disable=SC2086
          "$doctor" $line || echo "kde-monitors: failed: kscreen-doctor $line" >&2
        done < "$plan"
        exit 0
      '';
      skwdWallActive = parent.skwdWall.enable or false;

      # skwd-wall only publishes x86_64-linux outputs; guard the attr access so
      # aarch64-linux hosts don't hit a missing-attribute eval error.
      skwdWallPlasmaAvailable = skwdWallActive && pkgs.stdenv.hostPlatform.isx86_64;

      wallpaperPaths = builtins.map
        (
          w:
          let
            useFallback = w.wallpaperURL == "";
          in
          "${pkgs.fetchurl {
          url = if useFallback then myconfig.constants.fallbackWallpaperURL else w.wallpaperURL;
          sha256 = if useFallback then myconfig.constants.fallbackWallpaperSHA256 else w.wallpaperSHA256;
        }}"
        )
        myconfig.constants.wallpapers;

      isCatppuccin = myconfig.constants.theme.catppuccin;
      flavor = myconfig.constants.theme.catppuccinFlavor;
      accent = myconfig.constants.theme.catppuccinAccent;
      # mirrors the stylix KDE target default in stylix-nixos.nix (on unless catppuccin)
      stylixKde = myconfig.stylix.enable && (myconfig.stylix.targets.kde.enable or (!isCatppuccin));

      colorScheme =
        if stylixKde then
          null
        else if isCatppuccin then
          "Catppuccin${lib.toSentenceCase flavor}${lib.toSentenceCase accent}"
        else if myconfig.constants.theme.polarity == "dark" then
          "BreezeDark"
        else
          "BreezeLight";

      lookAndFeel =
        if stylixKde then
          null
        else if myconfig.constants.theme.polarity == "dark" then
          "org.kde.breezedark.desktop"
        else
          "org.kde.breeze.desktop";

      cursorTheme = lib.mkIf (config.stylix.cursor != null) config.stylix.cursor.name;
    in
    lib.mkMerge [
      (lib.mkIf (plan != [ ]) {
        xdg.configFile."kde-monitors/plan".text = lib.concatMapStrings (l: l + "\n") plan;

        systemd.user.services.kde-monitors = {
          Unit = {
            Description = "Apply the declared KDE Plasma monitor layout";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" "plasma-kwin_wayland.service" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecCondition = "${inKdeSession}";
            ExecStart = "${apply}";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      })
      {
        # plasma-manager's workspace.wallpaper can't select a non-org.kde.image plugin, so
        # wallpaperCustomPlugin is used instead when skwd-wall owns the wallpaper.
        home.packages =
          lib.optional skwdWallPlasmaAvailable inputs.skwd-wall.packages.${pkgs.stdenv.hostPlatform.system}.skwd-paper-plasma
          ++ lib.optional isCatppuccin (pkgs.catppuccin-kde.override {
            flavour = [ flavor ];
            accents = [ accent ];
          });

        programs.plasma = {
          enable = true;
          overrideConfig = true;

          workspace = {
            clickItemTo = "select";

            inherit colorScheme lookAndFeel;
            cursor.theme = cursorTheme;
            wallpaper = lib.mkIf (!skwdWallPlasmaAvailable) wallpaperPaths;
            wallpaperCustomPlugin = lib.mkIf skwdWallPlasmaAvailable {
              plugin = "org.skwd.wall.plasma";
            };
          };
        };

      }
    ];
}
