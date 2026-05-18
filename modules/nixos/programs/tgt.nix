{ delib, inputs, pkgs, ... }:
# TODO: drop this whole let-block + re-add `inputs.nixpkgs.follows = "nixpkgs"`
# on `tgt` in flake.nix once nixpkgs ships a tdlib that builds on CMake >= 4.
# Two upstream bugs are worked around here:
#   1. tdlib 1.8.x's CMakeLists declares `cmake_minimum_required(VERSION 3.0.2)`;
#      CMake 4 dropped <3.5 compat. We inject the documented escape
#      `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`.
#   2. tgt's upstream flake pins a stale `cargoHash`. We rebuild tgt locally
#      with `rustPlatform.buildRustPackage` and the hash Nix actually wants.
# Re-check by `nix flake update` + `nh os test --dry --ask` without this block.
let
  system = pkgs.stdenv.hostPlatform.system;
  tgtPkgs = inputs.tgt.inputs.nixpkgs.legacyPackages.${system};

  tdlib = (tgtPkgs.tdlib.overrideAttrs {
    version = "1.8.29";
    src = tgtPkgs.fetchFromGitHub {
      owner = "tdlib";
      repo = "td";
      rev = "af69dd4397b6dc1bf23ba0fd0bf429fcba6454f6";
      hash = "sha256-2RhKSxy0AvuA74LHI86pqUxv9oJZ+ZxxDe4TPI5UYxE=";
    };
  }).overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });

  rlinkLibs = [ tgtPkgs.pkg-config tgtPkgs.openssl tdlib ];

  tgt = tgtPkgs.rustPlatform.buildRustPackage {
    pname = "tgt";
    version = "unstable-2024-11-04";
    src = inputs.tgt;

    nativeBuildInputs = rlinkLibs;
    buildInputs = rlinkLibs;

    patches = [ "${inputs.tgt}/patches/0001-check-filesystem-writability-before-operations.patch" ];

    doCheck = false;

    cargoHash = "sha256-lWaRWXQ5V2LQTqJ+ymfNGeCZz+QyZLgLkOh5BqDWDZQ=";
    buildNoDefaultFeatures = true;
    buildFeatures = [ "pkg-config" ];

    env = {
      RUSTFLAGS = "-C link-arg=-Wl,-rpath,${tdlib}/lib -L ${tgtPkgs.openssl}/lib";
      LOCAL_TDLIB_PATH = "${tdlib}/lib";
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
