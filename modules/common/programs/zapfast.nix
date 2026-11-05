{ delib
, inputs
, lib
, pkgs
, config
, ...
}:

delib.module {
  name = "programs.zapfast";
  options = delib.moduleOptions {
    enable = delib.boolOption false;
    giphyKeySecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "zapfast_giphy_key";
      description = "Name of the sops-nix secret holding the GIPHY API key for GIF search. Optional: the key is only wired (through programs.zapfast.secretFiles, so it never enters the Nix store) when a secret of this name is declared in the NixOS sops configuration; null disables it.";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Keys merged into ZapFast's settings.json on every activation. They override the keys this module derives from the host constants (theme, interface_language, update and background behaviour). Values are copied to the Nix store, so keep secrets out.";
    };
  };

  home.always.imports = [ inputs.zapfast.homeManagerModules.default ];

  nixos.ifEnabled = { cfg, myconfig, ... }:
    let
      name = cfg.giphyKeySecret;
      declared = lib.attrByPath [ "sops" "secrets" ] { } config;
    in
    lib.mkIf (name != null && declared ? ${name}) {
      home-manager.users.${myconfig.constants.user}.programs.zapfast.secretFiles.giphy_key = declared.${name}.path;
    };

  home.ifEnabled = { cfg, myconfig, ... }:
    let
      inherit (myconfig.constants) theme;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

      stylixColors = lib.attrByPath [ "lib" "stylix" "colors" ] null config;
      c =
        if myconfig.stylix.enable && stylixColors != null && (builtins.tryEval stylixColors.base00).success
        then stylixColors.withHashtag
        else null;

      catppuccinPalette = lib.attrByPath [ "catppuccin" "sources" "palette" ] null config;
      accent =
        if theme.catppuccin && catppuccinPalette != null
        then (lib.importJSON "${catppuccinPalette}/palette.json").${theme.catppuccinFlavor}.colors.${theme.catppuccinAccent}.hex
        else c.base0D;

      themeFile = "nix-theme.json";
      themeJson = builtins.toJSON {
        base = if theme.polarity == "light" then "light" else "dark";
        colors = {
          window = c.base00;
          panel = c.base01;
          surface = c.base02;
          surface_hover = c.base03;
          surface_active = c.base03;
          outline = c.base03;
          text = c.base05;
          secondary = c.base04;
          dim = c.base03;
          inherit accent;
          accent_hover = c.base0C;
          on_accent = c.base00;
          danger = c.base08;
          warning = c.base0A;
        };
      };

      localeLanguage = lib.head (lib.splitString "." (lib.head (lib.splitString "@" (myconfig.constants.mainLocale or ""))));
      localeMap = {
        en = "en";
        de = "de";
        es = "es";
        it = "it";
        fr = "fr";
        ru = "ru";
        tr = "tr";
        id = "id";
        pt = "pt-BR";
      };
      interfaceLanguage =
        let
          lang = lib.head (lib.splitString "_" localeLanguage);
          region = lib.last ([ "" ] ++ lib.splitString "_" localeLanguage);
        in
        if lang == "zh"
        then (if builtins.elem region [ "TW" "HK" "MO" ] then "zh-Hant" else "zh-Hans")
        else localeMap.${lang} or null;

      generated = {
        check_for_updates = false;
        download_updates_automatically = false;
        keep_running_in_background = true;
      }
      // lib.optionalAttrs (interfaceLanguage != null) { interface_language = interfaceLanguage; }
      // lib.optionalAttrs (c != null) { custom_theme = themeFile; };
    in
    {
      programs.zapfast = {
        enable = true;
        settings = lib.mkMerge [
          (lib.mapAttrs (_: lib.mkDefault) generated)
          cfg.settings
        ];
      };

      home.file."Library/Application Support/me.paolino.zapfast/themes/${themeFile}" = lib.mkIf (c != null && isDarwin) {
        text = themeJson;
      };
      xdg.configFile."zapfast/themes/${themeFile}" = lib.mkIf (c != null && !isDarwin) {
        text = themeJson;
      };
    };
}
