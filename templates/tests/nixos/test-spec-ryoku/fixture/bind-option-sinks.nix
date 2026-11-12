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
    mango = {
      extraBinds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      extraMouseBinds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      extraAxisBinds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };
}
