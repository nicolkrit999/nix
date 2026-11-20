{ lib, inputs, ... }:
let
  sink = lib.mkOption { type = lib.types.bool; default = false; };
  sinks = names: lib.genAttrs names (_: { enable = sink; });
in
{
  options.myconfig = {
    programs = sinks [ "caelestia" "noctalia" ] // {
      gnome = {
        enable = sink;
        extraBinds = lib.mkOption { type = lib.types.listOf lib.types.attrs; default = [ ]; };
        wmKeybindings = lib.mkOption { type = lib.types.attrs; default = { }; };
      };
      kde.enable = sink;
      cosmic = {
        enable = sink;
        extraBinds = lib.mkOption { type = lib.types.attrsOf lib.types.attrs; default = { }; };
        disabledDefaults = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
      };
    };
    stylix.enable = sink;
  };

  options.stylix.enable = sink;

  config.home-manager.sharedModules = [
    inputs.plasma-manager.homeModules.plasma-manager
    inputs.cosmic-manager.homeManagerModules.cosmic-manager
    {
      key = "niri-stylix-off-enable-stub";
      options.stylix.enable = lib.mkOption { type = lib.types.bool; default = false; };
    }
  ];
}
