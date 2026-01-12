{ pkgs, rustToolchain }:
with pkgs;
[
  # The specific toolchain (Stable or Nightly) passed from flake.nix
  rustToolchain

  # Common Rust Tools
  openssl
  pkg-config
  cargo-deny
  cargo-edit
  cargo-watch
  rust-analyzer
]
