{ delib, lib, moduleSystem, ... }:
let
  # TEMPORARY: cargo-setup-hook forces LIBSQLITE3_SYS_USE_PKG_CONFIG=1; remove when nixpkgs evebox has sqlite in buildInputs.
  eveboxOverlay = _final: prev: {
    evebox =
      if lib.elem prev.sqlite (prev.evebox.buildInputs or [ ]) then prev.evebox
      else
        prev.evebox.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
          buildInputs = (old.buildInputs or [ ]) ++ [ prev.sqlite ];
        });
  };
in
delib.module {
  name = "evebox-overlay";

  nixos.always.nixpkgs.overlays = [ eveboxOverlay ];
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = [ eveboxOverlay ];
  };
}
