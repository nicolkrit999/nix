# P01 — Hyprland + caelestia active
# Caelestia is the active shell on Hyprland. Expected: clean eval, caelestia
# dispatchers in binds, swaync + awww wallpaper suppressed (caelestia handles both),
# waybar absent (default off, blocked by contract anyway).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./01-hyprland-caelestia;
  hm = H.getHm config;
  binds = hm.wayland.windowManager.hyprland.settings.bind;
  execLua = (builtins.elemAt hm.wayland.windowManager.hyprland.settings.on._args 1).expr;
in
nix-tests.runTests {
  "P01: hyprland + caelestia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed — coexists with caelestia (binds dispatch to caelestiaLogout)" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync suppressed — caelestia active on hyprland" =
      helpers.isFalse hm.services.swaync.enable;
    "awww wallpaper suppressed — caelestia provides wallpaper" =
      helpers.isFalse (lib.hasInfix "awww-daemon" execLua);
    "Super+Shift+A dispatches to caelestiaQS" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "caelestiaQS" (H.bindStr b)) binds);
    "Super+Delete dispatches to caelestiaLogout lock" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "caelestiaLogout lock" (H.bindStr b)) binds);
  };
}
