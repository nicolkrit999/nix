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

  scenario = { theme, wallpaper, role, themeConfig ? { } }: {
    inherit theme wallpaper role themeConfig;
    polarity = themes.${theme};
    system = fakeHost.extendModules {
      modules = [{
        myconfig.constants.theme.base16Theme = lib.mkOverride 10 theme;
        myconfig.constants.theme.polarity = lib.mkOverride 10 themes.${theme};
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
    // {
      accent-override-white = scenario {
        theme = "gruvbox-dark";
        wallpaper = "white";
        role = "accent-override";
        themeConfig.accentColor = "#777777";
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
