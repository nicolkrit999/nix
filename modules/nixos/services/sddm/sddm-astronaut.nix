{ delib
, pkgs
, lib
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

      themeConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          HourFormat = "hh:mm AP";
        };
        description = ''
          Attribute set of [General] options to override via the upstream
          `<theme>.conf.user` mechanism. Not all keys take effect — upstream
          bug (see HourFormat FIXME). Background is handled separately.
        '';
      };

      background = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to custom background image. Replaces the embedded theme's
          default wallpaper by overwriting the Background key in the active
          theme .conf (direct edit, does not rely on the .conf.user path).
        '';
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
      bgFilename = "custom_background.${bgExt}";

      baseTheme = pkgs.sddm-astronaut.override {
        embeddedTheme = cfg.embeddedTheme;
        themeConfig = if cfg.themeConfig == { } then null else cfg.themeConfig;
      };

      sddmTheme =
        if cfg.background == null then
          baseTheme
        else
          pkgs.runCommandLocal "sddm-astronaut-with-bg" { } ''
            mkdir -p $out
            cp -r ${baseTheme}/. $out/
            chmod -R u+w $out
            cp ${cfg.background} $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/${bgFilename}
            sed -i 's|^Background=".*"|Background="Backgrounds/${bgFilename}"|' \
              $out/share/sddm/themes/sddm-astronaut-theme/Themes/${cfg.embeddedTheme}.conf
          '';
    in
    {
      services.xserver.enable = true;
      services.xserver.excludePackages = [ pkgs.xterm ];

      services.displayManager.sddm = {
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

      systemd.services.display-manager.environment = {
        QT_IM_MODULE = "qtvirtualkeyboard";
        QT_VIRTUALKEYBOARD_DESKTOP_DISABLE = "1";
      };

      environment.systemPackages = [
        sddmTheme
        pkgs.bibata-cursors
      ];

      services.displayManager.autoLogin = {
        enable = false;
        user = myconfig.constants.user;
      };

      services.getty.autologinUser = null;
    };
}
