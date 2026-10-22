let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  here = src + "/templates/tests/nixos/test-sddm-pixie-readability";

  fakeHosts = denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (here + "/host")
      (here + "/nixos-extra")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/nixos/toplevel/stylix-nixos.nix")
      (src + "/modules/nixos/services/sddm/sddm-pixie.nix")
    ];
    exclude = [ ];
  };
  fakeHost = fakeHosts.${builtins.head (builtins.attrNames fakeHosts)};

  wallpaper = name: color: {
    hex = color;
    drv = pkgs.runCommand "wallpaper-${name}.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 64x64 xc:'${color}' png:$out
      test "$(magick $out -format '%[hex:p{0,0}]' info:)" = "${lib.toUpper (lib.removePrefix "#" color)}"
    '';
  };
  wallpapers = {
    white = wallpaper "white" "#ffffff";
    black = wallpaper "black" "#000000";
    grey = wallpaper "grey" "#808080";
  };

  themes = {
    gruvbox-dark = "dark";
    catppuccin-mocha = "dark";
    gruvbox-light-medium = "light";
    catppuccin-latte = "light";
  };

  neutrals = ramp: lib.listToAttrs (lib.imap0 (i: v: lib.nameValuePair "base0${toString i}" v) ramp);
  accents = [ "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F" ];
  uniform = c: lib.genAttrs accents (_: c);
  spread = [ "b05050" "b08050" "b0b050" "50b050" "50b0b0" "5080b0" "9060b0" "906040" ];
  withAccents = list: lib.listToAttrs (lib.zipListsWith lib.nameValuePair accents list);

  customThemes = {
    mid-grey = {
      polarity = "dark";
      scheme = neutrals [ "808080" "757575" "6b6b6b" "606060" "959595" "a0a0a0" "b0b0b0" "c0c0c0" ] // withAccents spread;
    };
    mid-half-luminance = {
      polarity = "light";
      scheme = neutrals [ "bcbcbc" "b4b4b4" "aaaaaa" "a0a0a0" "909090" "828282" "767676" "6a6a6a" ] // withAccents spread;
    };
    pure-white = {
      polarity = "light";
      scheme = neutrals (lib.replicate 8 "ffffff") // uniform "ffffff";
    };
    pure-black = {
      polarity = "dark";
      scheme = neutrals (lib.replicate 8 "000000") // uniform "000000";
    };
    saturated-blue-dark = {
      polarity = "dark";
      scheme = neutrals [ "1d2021" "3c3836" "504945" "665c54" "bdae93" "d5c4a1" "ebdbb2" "fbf1c7" ] // uniform "0000ff";
    };
    saturated-yellow-light = {
      polarity = "light";
      scheme = neutrals [ "fbf1c7" "ebdbb2" "d5c4a1" "bdae93" "665c54" "504945" "3c3836" "282828" ] // uniform "ffff00";
    };
  };

  scenario = { theme, wallpaper, role, themeConfig ? { } }:
    let custom = customThemes.${theme} or null; in {
      inherit theme wallpaper role themeConfig;
      polarity = if custom != null then custom.polarity else themes.${theme};
      system = fakeHost.extendModules {
        modules = [{
          myconfig.constants.theme.base16Theme = lib.mkOverride 10 (if custom != null then "gruvbox-dark-medium" else theme);
          myconfig.constants.theme.polarity = lib.mkOverride 10 (if custom != null then custom.polarity else themes.${theme});
          stylix.base16Scheme = lib.mkIf (custom != null) (lib.mkOverride 10 custom.scheme);
          myconfig.services.sddm-pixie.background = lib.mkOverride 10 "${wallpapers.${wallpaper}.drv}";
          myconfig.services.sddm-pixie.themeConfig = themeConfig;
        }];
      };
    };

  scenarios =
    lib.listToAttrs
      (lib.concatMap
        (theme: map
          (wallpaper: lib.nameValuePair "${theme}-${wallpaper}" (scenario { inherit theme wallpaper; role = "matrix"; }))
          (builtins.attrNames wallpapers))
        (builtins.attrNames themes))
    // lib.listToAttrs
      (lib.concatMap
        (theme: map
          (wallpaper: lib.nameValuePair "${theme}-${wallpaper}" (scenario { inherit theme wallpaper; role = "extreme"; }))
          (builtins.attrNames wallpapers))
        (builtins.attrNames customThemes))
    // {
      accent-override-white = scenario {
        theme = "gruvbox-dark";
        wallpaper = "white";
        role = "accent-override";
        themeConfig.accentColor = "#777777";
      };
      accent-override-latte-mid = scenario {
        theme = "catppuccin-latte";
        wallpaper = "grey";
        role = "accent-override";
        themeConfig.accentColor = "#8a8a8a";
      };
      accent-override-latte-yellow = scenario {
        theme = "catppuccin-latte";
        wallpaper = "white";
        role = "accent-override";
        themeConfig.accentColor = "#ffff00";
      };
    };

  pixieOf = s: lib.findFirst (p: (p.pname or "") == "sddm-pixie") null s.system.config.environment.systemPackages;
  noContext = builtins.unsafeDiscardStringContext;
  paletteSlots = map (d: "base0${d}") (lib.stringToCharacters "0123456789ABCDEF");
in
{
  matrix = lib.mapAttrs
    (_: s: {
      inherit (s) theme wallpaper role polarity themeConfig;
      wallpaperHex = wallpapers.${s.wallpaper}.hex;
      wallpaperPath = noContext "${wallpapers.${s.wallpaper}.drv}";
      palette = lib.genAttrs paletteSlots (n: s.system.config.lib.stylix.colors.${n});
      drvPath = noContext (pixieOf s).drvPath;
    })
    scenarios;
  tools.qmllint = noContext "${pkgs.kdePackages.qtdeclarative}/bin/qmllint";
  pkg = lib.mapAttrs (_: pixieOf) scenarios;
}
