# P01 — Hyprland + caelestia active
# Caelestia is the active shell on Hyprland. Expected: clean eval, caelestia
# dispatchers in binds, swaync + hyprpaper suppressed (caelestia handles both),
# waybar absent (default off, blocked by contract anyway).
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./01-hyprland-caelestia;
  hm = H.getHm config;
  binds = hm.wayland.windowManager.hyprland.settings.bind;
in
nix-tests.runTests {
  "P01: hyprland + caelestia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed — coexists with caelestia (binds dispatch to caelestiaLogout)" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync suppressed — caelestia active on hyprland" =
      helpers.isFalse hm.services.swaync.enable;
    "hyprpaper suppressed — caelestia provides wallpaper" =
      helpers.isFalse hm.services.hyprpaper.enable;
    "Super+Shift+A dispatches to caelestiaQS" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "caelestiaQS" b) binds);
    "Super+Delete dispatches to caelestiaLogout lock" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "caelestiaLogout lock" b) binds);
  };
}
