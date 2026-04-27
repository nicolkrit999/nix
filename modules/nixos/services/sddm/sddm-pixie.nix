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
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to custom background image";
      };
      avatar = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to custom avatar image";
      };
    };

  nixos.ifEnabled =
    { myconfig
    , cfg
    , ...
    }:
    let
      # Base16 accent color from stylix
      accentColor = config.lib.stylix.colors.withHashtag.base0E;
      getExtension = path:
        let
          filename = builtins.baseNameOf (toString path);
          parts = lib.splitString "." filename;
        in
        if builtins.length parts > 1
        then lib.last parts
        else "jpg";

      bgExt = if cfg.background != null then getExtension cfg.background else "jpg";
      bgFilename = "background.${bgExt}";

      # Simple inline JS for 12h conversion - no IIFE (QML may not handle it)
      # Creates two Date objects but avoids function wrapper complexity
      js12HourExpr = ''String(new Date().getHours()%12||12).padStart(2,"0")+String(new Date().getMinutes()).padStart(2,"0")'';

      # Merge order: default → base16 accent → user themeConfig → custom background file path
      # This ensures the background key always exists when theme.conf is written
      effectiveThemeConfig =
        { background = "assets/background.jpg"; }  # Default fallback (upstream asset)
        // { accentColor = accentColor; }  # Base16 accent from stylix
        // cfg.themeConfig  # User overrides (can override accentColor if desired)
        // (lib.optionalAttrs (cfg.background != null) { background = "assets/${bgFilename}"; });

      themeConfContent = lib.concatStringsSep "\n" (
        [ "[General]" ] ++
        (lib.mapAttrsToList (k: v: "${k}=${v}") effectiveThemeConfig)
      );

      sddm-pixie = pkgs.stdenvNoCC.mkDerivation {
        pname = "sddm-pixie";
        version = "unstable-2025-01-01";

        src = pkgs.fetchFromGitHub {
          owner = "xCaptaiN09";
          repo = "pixie-sddm";
          rev = "main";
          sha256 = "sha256-lmE/49ySuAZDh5xLochWqfSw9qWrIV+fYaK5T2Ckck8=";
        };

        dontBuild = true;

        nativeBuildInputs = [ pkgs.gnused ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/sddm/themes/pixie
          cp -r * $out/share/sddm/themes/pixie/

          # Patch Clock.qml for 12h format (upstream hardcodes "HHmm" in TWO places)
          # Uses JavaScript IIFE to convert 24h→12h (Qt format strings unreliable)
          # HARDCODED 12h for debugging - remove conditional later
          sed -i 's@Qt\.formatTime(new Date(), "HHmm")@${js12HourExpr}@g' \
            $out/share/sddm/themes/pixie/components/Clock.qml

          ${lib.optionalString (cfg.themeConfig != { } || cfg.background != null) ''
            cat > $out/share/sddm/themes/pixie/theme.conf << 'EOF'
          ${themeConfContent}
          EOF
          ''}

          ${lib.optionalString (cfg.background != null) ''
            cp ${cfg.background} $out/share/sddm/themes/pixie/assets/${bgFilename}
          ''}

          ${lib.optionalString (cfg.avatar != null) ''
            cp ${cfg.avatar} $out/share/sddm/themes/pixie/assets/avatar.jpg
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
          qtmultimedia # For QtQuick.Effects blur support
        ];
      };

      environment.systemPackages = [
        sddm-pixie
      ];

      services.displayManager.autoLogin = {
        enable = false;
        user = myconfig.constants.user;
      };

      services.getty.autologinUser = null;
    };
}
