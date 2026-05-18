{ delib, inputs, pkgs, ... }:
# TODO: drop this whole let-block + re-add `inputs.nixpkgs.follows = "nixpkgs"`
# on `tgt` in flake.nix once nixpkgs 25.11 ships tdlib >= 1.8.61 AND the
# upstream `tgt` flake refreshes its cargoHash. Today (2026-05-18) all three
# of the issues below still bite — see memory `project_tgt_build_workarounds`
# for the full story and diagnosis recipe.
#
# Three independent upstream issues are worked around here:
#   1. tdlib version floor — tdlib-rs 1.4.0 (vendored by tgt) hard-requires
#      `tdjson >= 1.8.61` via pkg-config. nixpkgs 25.11 only ships 1.8.55, so
#      we override to 1.8.63 with a rev pinned from nixos-unstable.
#   2. stale cargoHash — tgt's upstream flake pins a `cargoHash` from when the
#      Cargo.lock had different deps; the current lock vendors differently.
#      We rebuild tgt with `rustPlatform.buildRustPackage` and the hash Nix
#      actually wants (update if Nix reports a mismatch after a flake update).
#   3. unwritable HOME in sandbox — tgt's `build.rs` calls `create_dir_all`
#      against `dirs::config_dir()` (resolves to `$HOME/.config/tgt`) at build
#      time. The nix sandbox HOME isn't writable, so `preBuild` redirects HOME
#      to a tmpdir. This must stay even if upstream merges a writability
#      check, since the check would still skip (silently) under sandbox.
#
# Re-check by `nix flake update` + `nh os test --dry --ask` without this block.
let
  system = pkgs.stdenv.hostPlatform.system;
  tgtPkgs = inputs.tgt.inputs.nixpkgs.legacyPackages.${system};

  tdlib = tgtPkgs.tdlib.overrideAttrs {
    version = "1.8.63";
    src = tgtPkgs.fetchFromGitHub {
      owner = "tdlib";
      repo = "td";
      rev = "f06b0bac65278b03d26414c096080e7bfecfef52";
      hash = "sha256-SzUDAZqdEIrIj1qUUD0MvzbCYxKLJwoX2+T0chud/rQ=";
    };
  };

  rlinkLibs = [ tgtPkgs.pkg-config tgtPkgs.openssl tdlib ];

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

    cargoHash = "sha256-lCPS7f/yGU0Fn0nAFA7kW8fNa9kiEGzcvSsn9ak0+d8=";
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
