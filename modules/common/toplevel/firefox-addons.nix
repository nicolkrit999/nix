{ delib, inputs, lib, moduleSystem, ... }:
let
  overlays = [ inputs.firefox-addons.overlays.default ];
in
delib.module {
  name = "firefox-addons";

  nixos.always.nixpkgs.overlays = overlays;
  darwin.always.nixpkgs.overlays = overlays;
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = overlays;
  };
}
