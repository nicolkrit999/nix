{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "services.sddm-pixie";
  options = delib.moduleOptions {
    enable = delib.boolOption false;
    themeConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        HourFormat = "HH:mm";
        DateFormat = "dddd, MMMM d";
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

      effectiveThemeConfig = cfg.themeConfig // (
        if cfg.background != null
        then { Background = "assets/${bgFilename}"; }
        else { }
      );

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

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/sddm/themes/pixie
          cp -r * $out/share/sddm/themes/pixie/

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
