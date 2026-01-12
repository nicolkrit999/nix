{ pkgs }:
let
  # 1. Fetch the Stable NixOS 24.11 channel
  # This is needed currently to fix it.
  # Eventually try to remove this let/in block and use the normal pkgs.* below again.
  stablePkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.11.tar.gz";
    sha256 = "1s2gr5rcyqvpr58vxdcb095mdhblij9bfzaximrva2243aal3dgx";
  }) { inherit (pkgs) system; };
in

[
  # Use the stable versions of Swift and SourceKit-LSP
  stablePkgs.swift
  stablePkgs.sourcekit-lsp

  # Up to date (currently broken)
  /*
    pkgs.swift
    pkgs.sourcekit-lsp
  */
]
