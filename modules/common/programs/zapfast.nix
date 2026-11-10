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

      zapfastBuilt =
        let upstream = inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in
        if upstream.dontCargoUseSystemLibs or false then upstream
        else upstream.overrideAttrs { dontCargoUseSystemLibs = true; };

      # rfd dlopens libdbus-1.so for the xdg-portal file picker; upstream's wrapper omits it (picker silently fails).
      zapfastPackage =
        let upstream = zapfastBuilt;
        in pkgs.symlinkJoin {
          inherit (upstream) name pname version meta;
          paths = [ upstream ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/zapfast --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.dbus ]}";
        };

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

      # Linear mix of two "#rrggbb" colours (t = share of b). The selected chat row (surface_active)
      # and the preview text (dim) must stay apart: both on the same base16 slot made the preview invisible.
      mixHex = a: b: t:
        let
          chan = s: i: lib.fromHexString (builtins.substring i 2 (lib.removePrefix "#" s));
          pad = n: let h = lib.toLower (lib.toHexString n); in if builtins.stringLength h == 1 then "0${h}" else h;
          one = i: pad (builtins.floor ((chan a i) * (1.0 - t) + (chan b i) * t + 0.5));
        in
        "#${one 0}${one 2}${one 4}";

      themeFile = "nix-theme.json";
      themeJson = builtins.toJSON {
        base = if theme.polarity == "light" then "light" else "dark";
        colors = {
          window = c.base00;
          panel = mixHex c.base00 c.base01 0.3;
          surface = mixHex c.base00 c.base01 0.8;
          surface_hover = c.base01;
          surface_active = mixHex c.base01 c.base02 0.6;
          outline = mixHex c.base01 c.base02 0.7;
          text = c.base05;
          secondary = c.base04;
          dim = mixHex c.base03 c.base04 0.4;
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
        # Chat wallpaper: the palette's `chat` colour (follows the generated theme) with the doodle pattern.
        # The wallpaper image is per linked number, kept in the account's own state file, so it cannot be declared here.
        show_wallpaper = true;
        wallpaper_color = "theme";
        dark_wallpaper_color = "theme";
        enter_sends = false;
        # Always null: with a folder set, every automatically downloaded attachment (voice messages, stickers, files in view)
        # is written there as <number>/<chat>/<file>. Null keeps them in the cache; "Save as…" exports a single file.
        # Declared (not just left out) so an earlier value in settings.json is reset on activation.
        download_folder = null;
      }
      // lib.optionalAttrs (interfaceLanguage != null) { interface_language = interfaceLanguage; }
      // lib.optionalAttrs (c != null) { custom_theme = themeFile; };
    in
    {
      programs.zapfast = {
        enable = true;
        package = if isDarwin then zapfastBuilt else zapfastPackage;
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
