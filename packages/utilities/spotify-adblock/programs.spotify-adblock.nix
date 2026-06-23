{ delib, inputs, pkgs, ... }:

let
  spotifyAdblockLib = pkgs.rustPlatform.buildRustPackage {
    pname = "spotify-adblock";
    version = "unstable";
    src = inputs.spotify-adblock-src;
    cargoLock.lockFile = "${inputs.spotify-adblock-src}/Cargo.lock";
    patchPhase = ''
      substituteInPlace src/lib.rs \
        --replace 'config.toml' $out/etc/spotify-adblock/config.toml
    '';
    buildPhase = "make";
    installPhase = ''
      mkdir -p $out/etc/spotify-adblock
      install -D --mode=644 config.toml $out/etc/spotify-adblock
      mkdir -p $out/lib
      install -D --mode=644 --strip target/release/libspotifyadblock.so $out/lib
    '';
  };

  spotifyWithAdblock = pkgs.symlinkJoin {
    name = "spotify-with-adblock-${pkgs.spotify.version}";
    paths = [ pkgs.spotify ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/spotify \
        --set LD_PRELOAD "${spotifyAdblockLib}/lib/libspotifyadblock.so"
    '';
  };
in

delib.module {
  name = "programs.spotifyAdblock";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { ... }: {
    environment.systemPackages = [ spotifyWithAdblock ];
  };
}
