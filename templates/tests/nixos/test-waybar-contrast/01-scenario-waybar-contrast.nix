let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  desktop = flake.nixosConfigurations.nixos-desktop;
  libDir = ../../lib;

  flat = {
    scheme = "Synthetic flat";
    author = "test";
    variant = "dark";
    palette = lib.genAttrs [ "base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07" "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F" ] (_: "777777");
  };

  schemes = {
    catppuccin-mocha = { role = "control"; polarity = "dark"; palette = import (libDir + "/scheme-catppuccin-mocha.nix"); };
    windows-nt-light = { role = "scenario"; polarity = "light"; palette = import (libDir + "/scheme-windows-nt-light.nix"); };
    unikitty = { role = "scenario"; polarity = "light"; palette = import (libDir + "/scheme-unikitty.nix"); };
    ocean = { role = "scenario"; polarity = "dark"; palette = import (libDir + "/scheme-ocean.nix"); };
    darkviolet = { role = "scenario"; polarity = "dark"; palette = import (libDir + "/scheme-darkviolet.nix"); };
    synthetic-flat = { role = "negative"; polarity = "dark"; palette = flat; };
  };

  variantOf = s:
    desktop.extendModules {
      modules = [{
        stylix.base16Scheme = lib.mkForce s.palette;
        stylix.polarity = lib.mkForce s.polarity;
        home-manager.users.krit.stylix.base16Scheme = lib.mkForce s.palette;
        home-manager.users.krit.stylix.polarity = lib.mkForce s.polarity;
      }];
    };

  wms = [ "hyprland" "niri" "mango" ];
  textOf = c: key:
    let f = c.home-manager.users.krit.xdg.configFile;
    in if f ? ${key} then builtins.unsafeDiscardStringContext f.${key}.text else null;

  perScheme = _: s:
    let c = (variantOf s).config; in
    {
      inherit (s) role polarity;
      palette = s.palette.palette;
      polarityApplied = c.stylix.polarity == s.polarity && c.home-manager.users.krit.stylix.polarity == s.polarity;
      bars = lib.genAttrs wms (wm: {
        css = textOf c "waybar-${wm}/style.css";
        config = textOf c "waybar-${wm}/config";
      });
    };
in
lib.mapAttrs perScheme schemes
