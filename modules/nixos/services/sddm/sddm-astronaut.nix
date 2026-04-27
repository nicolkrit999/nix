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
          Attribute set of [General] options. Applied via direct sed on
          the active theme .conf (not the upstream .conf.user path, which
          has upstream bugs — see HourFormat FIXME). Wins over
          stylixIntegration defaults.
        '';
      };

      background = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to custom background image. Replaces the embedded theme's
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

      stylixAuto = cfg.background != null;
      stylixRequested =
        if cfg.stylixIntegration == null then stylixAuto else cfg.stylixIntegration;
      stylixEnabled = (config.stylix.enable or false) && stylixRequested;

      stylixThemeConfig =
        if !stylixEnabled then { }
        else
          let c = config.lib.stylix.colors.withHashtag; in {
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
          };

      effectiveThemeConfig = stylixThemeConfig // cfg.themeConfig;

      baseTheme = pkgs.sddm-astronaut.override {
        embeddedTheme = cfg.embeddedTheme;
      };

      needsPatch = cfg.background != null || effectiveThemeConfig != { };

      themePath = "$out/share/sddm/themes/sddm-astronaut-theme";
      confPath = "${themePath}/Themes/${cfg.embeddedTheme}.conf";

      escapeSedRepl = s: lib.replaceStrings [ "|" "&" "\\" ] [ "\\|" "\\&" "\\\\" ] s;
      patchLine = k: v: ''sed -i 's|^${k}="[^"]*"|${k}="${escapeSedRepl v}"|' ${confPath}'';

      sddmTheme =
        if !needsPatch then baseTheme
        else
          pkgs.runCommandLocal "sddm-astronaut-patched" { } ''
            mkdir -p $out
            cp -r ${baseTheme}/. $out/
            chmod -R u+w $out

            # Drop any upstream .conf.user so our direct .conf edits are authoritative.
            rm -f ${themePath}/Themes/*.conf.user

            ${lib.optionalString (cfg.background != null) ''
              cp ${cfg.background} ${themePath}/Backgrounds/${bgFilename}
              sed -i 's|^Background="[^"]*"|Background="Backgrounds/${bgFilename}"|' ${confPath}
            ''}

            ${lib.concatStringsSep "\n" (lib.mapAttrsToList patchLine effectiveThemeConfig)}
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
