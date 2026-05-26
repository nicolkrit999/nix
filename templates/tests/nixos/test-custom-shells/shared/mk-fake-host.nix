# Builds a delib.host definition from a compact scenario spec.
#
# Usage in a scenario's default.nix:
#   import ../../shared/mk-fake-host.nix {
#     name   = "test-hyprland-caelestia";
#     wm     = { hyprland = true; };
#     shells = { caelestia = { enable = true; enableOnHyprland = true; }; };
#   }
#
# Waybars default to OFF — prevents the default boolOption-true from firing
# a waybar+shell conflict assertion in shell-active scenarios.
# Pass waybar.hyprland/niri/mango = true to opt into waybar for that WM.
spec:
{ delib, ... }:
let
  wm = spec.wm or { };
  shells = spec.shells or { };
  waybar = spec.waybar or { };
  caelestia = shells.caelestia or { };
  noctalia = shells.noctalia or { };
in
delib.host {
  name = spec.name;
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    programs = {
      hyprland.enable = wm.hyprland or false;
      niri.enable = wm.niri or false;
      mango.enable = wm.mango or false;

      caelestia = {
        enable = caelestia.enable or false;
        enableOnHyprland = caelestia.enableOnHyprland or false;
      };

      noctalia = {
        enable = noctalia.enable or false;
        enableOnHyprland = noctalia.enableOnHyprland or false;
        enableOnNiri = noctalia.enableOnNiri or false;
        enableOnMango = noctalia.enableOnMango or false;
      };

      waybar-hyprland.enable = waybar.hyprland or false;
      waybar-niri.enable = waybar.niri or false;
      waybar-mango.enable = waybar.mango or false;
    };

    services.swaync.enable = true;
  };
}
