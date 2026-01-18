{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    fenix = {
      url = "https://flakehub.com/f/nix-community/fenix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      fenix,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ fenix.overlays.default ];
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          # 1. Define Stable Toolchain
          stableToolchain = pkgs.fenix.stable.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ];

          # 2. Define Nightly (Unstable) Toolchain
          nightlyToolchain = pkgs.fenix.complete.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ];

          # Helper to create shell
          mkRustShell =
            toolchain:
            pkgs.mkShell {
              packages = import ./packages.nix {
                inherit pkgs;
                rustToolchain = toolchain;
              };

              env = {
                RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
              };
            };
        in
        {
          # Default is Stable
          default = mkRustShell stableToolchain;

          # Access via: use flake .#nightly
          nightly = mkRustShell nightlyToolchain;
        }
      );
    };
}
