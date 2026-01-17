{
  pkgs,
  lib,
  vars,
  ...
}:
{
  config = lib.mkIf (vars.niri or false) {
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };
  };
}
