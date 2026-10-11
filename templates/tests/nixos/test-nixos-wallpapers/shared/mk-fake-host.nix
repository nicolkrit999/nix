# Builds a delib.host definition for wallpaper test scenarios.
#
# spec fields:
#   name            string     - host name
#   system          string     - "x86_64-linux" (default) or "aarch64-linux"
#   constants       attrset    - result of importing a base-constants-*.nix
#   skwdWall        bool       - whether programs.skwdWall is enabled (default false)
#   gnome, kde      bool       - enable GNOME / KDE (default true)
#   shells          attrset    - caelestia/noctalia enable flags (default all off)
#   minimal         bool       - enable ONLY hyprland/niri/mango (per `wms`), gnome, kde as
#                                flagged; no shell/waybar/swaync lines (default false)
#   wms             [string]   - WMs enabled when minimal (default all three)
#
# Non-minimal: all three WMs, gnome, and kde are enabled so that each test can
# assert across all WM/DE outputs in a single host eval; waybars default OFF.
spec:
{ delib, lib, ... }:
let
  shells = spec.shells or { };
  caelestia = shells.caelestia or { };
  noctalia = shells.noctalia or { };
  system = spec.system or "x86_64-linux";
  minimal = spec.minimal or false;
  wms = spec.wms or [ "hyprland" "niri" "mango" ];
  has = wm: !minimal || builtins.elem wm wms;
  full = {
    programs.skwdWall.enable = spec.skwdWall or false;

    programs.caelestia = {
      enable = caelestia.enable or false;
      enableOnHyprland = caelestia.enableOnHyprland or false;
    };

    programs.noctalia = {
      enable = noctalia.enable or false;
      enableOnHyprland = noctalia.enableOnHyprland or false;
      enableOnNiri = noctalia.enableOnNiri or false;
      enableOnMango = noctalia.enableOnMango or false;
    };

    programs.waybar-hyprland.enable = false;
    programs.waybar-niri.enable = false;
    programs.waybar-mango.enable = false;

    services.swaync.enable = false;
  };
in
delib.host {
  name = spec.name;
  type = "desktop";
  homeManagerSystem = system;

  myconfig = _: lib.recursiveUpdate
    {
      constants = spec.constants;

      programs.hyprland.enable = has "hyprland";
      programs.niri.enable = has "niri";
      programs.mango.enable = has "mango";
      programs.gnome.enable = spec.gnome or true;
      programs.kde.enable = spec.kde or true;
    }
    (if minimal then { } else full);
}
