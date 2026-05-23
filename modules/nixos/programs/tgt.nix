{ delib, inputs, pkgs, ... }:
# nixpkgs-unstable is used here because 25.11 ships tdlib 1.8.55 but tdlib-rs requires >= 1.8.61.
# The tgt flake's own bundled tdlib is 1.8.29 (fails CMake <3.5 compat error too).
# TODO: drop tgtPkgs once 25.11 backports tdlib >= 1.8.61 or tgt upstream fixes their bundled tdlib.
#
# Issue 3 (unwritable HOME in sandbox) is still present upstream — preBuild stays.
# cargoHash: update the `got:` value here after each `nix flake update`.
let
  system = pkgs.stdenv.hostPlatform.system;
  tgtPkgs = import inputs.nixpkgs-unstable { inherit system; };

  rlinkLibs = [ tgtPkgs.pkg-config tgtPkgs.openssl tgtPkgs.tdlib ];

  tgt = tgtPkgs.rustPlatform.buildRustPackage {
    pname = "tgt";
    version = "unstable-2024-11-04";
    src = inputs.tgt;

    nativeBuildInputs = rlinkLibs;
    buildInputs = rlinkLibs;

    # build.rs writes default configs to `$HOME/.config/tgt`; the nix sandbox
    # HOME is not writable. Redirect to a build-scoped tmpdir.
    preBuild = ''
      export HOME=$(mktemp -d)
    '';

    doCheck = false;

    cargoHash = "sha256-CSKeVVx2J51NIvA71FMLYgcvLSrkG8OpmZSZ0WK4f8w=";
    buildNoDefaultFeatures = true;
    buildFeatures = [ "pkg-config" ];

    env = {
      RUSTFLAGS = "-C link-arg=-Wl,-rpath,${tgtPkgs.tdlib}/lib -L ${tgtPkgs.openssl}/lib";
      LOCAL_TDLIB_PATH = "${tgtPkgs.tdlib}/lib";
    };
  };
in
delib.module {
  # Telegram tui
  name = "programs.tgt";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ tgt ];
  };
}
