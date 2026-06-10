# Builds a delib.host definition for wallpaper test scenarios.
#
# spec fields:
#   name            string     — host name
#   system          string     — "x86_64-linux" (default) or "aarch64-linux"
#   constants       attrset    — result of importing a base-constants-*.nix
#   waypaper        bool       — whether programs.waypaper is enabled (default false)
#   shells          attrset    — caelestia/noctalia enable flags (default all off)
#
# All three WMs (hyprland, mango, niri), gnome, and kde are always enabled so
# that each test can assert across all WM/DE outputs in a single host eval.
# Waybars default to OFF (prevents shell-conflict assertions from firing).
spec:
{ delib, ... }:
let
  shells = spec.shells or { };
  caelestia = shells.caelestia or { };
  noctalia = shells.noctalia or { };
  system = spec.system or "x86_64-linux";
in
delib.host {
  name = spec.name;
  type = "desktop";
  homeManagerSystem = system;

  myconfig = _: {
    constants = spec.constants;

    # All WMs and DEs enabled so every output path is exercised in one eval.
    programs.hyprland.enable = true;
    programs.niri.enable = true;
    programs.mango.enable = true;
    programs.gnome.enable = true;
    programs.kde.enable = true;

    programs.waypaper.enable = spec.waypaper or false;

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

    # Waybars off — avoids shell+waybar conflict assertions in shell scenarios.
    programs.waybar-hyprland.enable = false;
    programs.waybar-niri.enable = false;
    programs.waybar-mango.enable = false;

    services.swaync.enable = false;
  };
}
