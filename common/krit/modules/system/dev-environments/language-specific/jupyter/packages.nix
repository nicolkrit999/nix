{ pkgs }:
with pkgs;
[
  poetry
  python311
]
++ (with python311Packages; [
  ipykernel
  pip
  venvShellHook
])
