{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  herdrPkgs = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system} or { };
  # TEMPORARY: cargo-setup-hook forces ZSTD_SYS_USE_PKG_CONFIG=1 (herdr-app zstd-sys); remove when herdr-nix herdr-app.nix lists zstd.
  withZstd = drv:
    if lib.any (p: (p.pname or "") == "zstd") (drv.buildInputs or [ ]) then drv
    else
      drv.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zstd ];
      });
  fixed = herdrPkgs // lib.optionalAttrs (herdrPkgs ? herdr) { herdr = withZstd herdrPkgs.herdr; };
  herdrPackages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform)
    (lib.attrVals (lib.filter (n: fixed ? ${n}) [ "herdr" "herdr-core" "herdr-tui" ]) fixed);
  shared = {
    environment.systemPackages = herdrPackages;
  };
in
delib.module {
  name = "programs.herdr";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = shared;
  darwin.ifEnabled = shared;

  home.ifEnabled = {
    home.packages = lib.optionals (moduleSystem == "home") herdrPackages;
  };
}
