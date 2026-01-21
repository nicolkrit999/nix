{ pkgs }:
with pkgs;
[
  rPackages.renv
  pandoc
  texlive.combined.scheme-full
]
