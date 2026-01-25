{
  pkgs,
  lib,
  vars,
  ...
}:
let
  isEnabled = builtins.elem "gaming" (vars.useCases or [ ]);
in
{
  config = lib.mkIf isEnabled {
    # User Level Gaming Setup
    home.packages = with pkgs; [
      lutris
      mangohud
      protonup-qt
    ];
  };
}
