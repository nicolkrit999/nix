{ delib, lib, moduleSystem, ... }:
let
  # TEMPORARY: cargo-setup-hook forces AWS_LC_SYS_USE_SYSTEM=1; remove when locked nixos-unstable contains nixpkgs 743696b736 (aws-lc in tectonic-unwrapped buildInputs).
  tectonicOverlay = _final: prev: {
    tectonic-unwrapped =
      if lib.elem prev.aws-lc (prev.tectonic-unwrapped.buildInputs or [ ]) then prev.tectonic-unwrapped
      else
        prev.tectonic-unwrapped.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [ prev.aws-lc ];
        });
  };
in
delib.module {
  name = "tectonic-overlay";

  nixos.always.nixpkgs.overlays = [ tectonicOverlay ];
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = [ tectonicOverlay ];
  };
}
