{ pkgs }:
with pkgs;
[
  node2nix
  nodejs
  nodePackages.pnpm
  yarn
]
