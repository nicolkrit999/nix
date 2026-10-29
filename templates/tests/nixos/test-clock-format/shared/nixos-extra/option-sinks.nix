{ lib, ... }:
{
  options.myconfig.programs.hyprland.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
}
