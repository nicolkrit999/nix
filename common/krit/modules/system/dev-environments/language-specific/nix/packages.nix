{ pkgs }:
with pkgs;
[
  nixd
  cachix
  lorri
  niv
  nixfmt-classic
  statix
  vulnix
  haskellPackages.dhall-nix

]
