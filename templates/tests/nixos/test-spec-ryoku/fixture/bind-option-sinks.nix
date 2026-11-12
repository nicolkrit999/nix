{ lib, ... }:
{
  options.myconfig.programs = {
    hyprland.extraBinds = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
    };
    niri.extraBinds = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
    };
  };
}
