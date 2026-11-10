{ delib, lib, moduleSystem, ... }:
let
  # TEMPORARY: hatchling now needs tomlkit + cargoSetupHook forces system sqlite/zstd; remove when locked nixos-unstable contains nixpkgs 00aeec53c5 (NixOS/nixpkgs#584713).
  ankiOverlay = _final: prev: {
    anki =
      if lib.elem prev.sqlite (prev.anki.buildInputs or [ ]) then prev.anki
      else
        prev.anki.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
          buildInputs = (old.buildInputs or [ ]) ++ [ prev.sqlite prev.zstd ];
          env = old.env // {
            UV_FIND_LINKS = "${prev.runCommand "uv-wheels" { } ''
              mkdir -p $out
              ln -s ${old.env.UV_FIND_LINKS}/*.whl $out
              ln -sf ${prev.python3.pkgs.tomlkit.dist}/*.whl $out
            ''}";
          };
        });
  };
in
delib.module {
  name = "anki-overlay";

  nixos.always.nixpkgs.overlays = [ ankiOverlay ];
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = [ ankiOverlay ];
  };
}
