{ delib, lib, moduleSystem, ... }:
let
  # TEMPORARY: libarchive 3.8.10 aborts 6 dwarfsextract_format_test cases (NixOS/nixpkgs#585413); remove when that issue is closed and locked unstable builds dwarfs.
  failingTests = map (i: "dwarfs/dwarfsextract_format_test.basic/${toString i}") [ 32 33 34 35 50 51 ];
  dwarfsOverlay = _final: prev: {
    dwarfs =
      if prev.dwarfs.version != "0.15.8" then prev.dwarfs
      else
        prev.dwarfs.overrideAttrs (old:
          let
            filter = old.env.GTEST_FILTER or "-";
          in
          lib.optionalAttrs (!lib.hasInfix (lib.head failingTests) filter) {
            env = (old.env or { }) // {
              GTEST_FILTER = lib.concatStringsSep ":" ([ filter ] ++ failingTests);
            };
          });
  };
in
delib.module {
  name = "dwarfs-overlay";

  nixos.always.nixpkgs.overlays = [ dwarfsOverlay ];
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = [ dwarfsOverlay ];
  };
}
