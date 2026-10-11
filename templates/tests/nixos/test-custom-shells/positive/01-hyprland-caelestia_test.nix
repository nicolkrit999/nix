# P01 — Hyprland + caelestia active
# Expected: caelestia binds, swaync + wallpaper supervisor suppressed.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./01-hyprland-caelestia;
  hm = H.getHm config;
  control = H.getHm (H.getConfig ./03-hyprland-no-shell);
  execLua = H.hyprExecLua hm;
  controlLua = H.hyprExecLua control;
in
nix-tests.runTests {
  "P01: hyprland + caelestia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync suppressed — caelestia active on hyprland" =
      helpers.isFalse hm.services.swaync.enable;
    "control (no shell) still starts the wallpaper supervisor" =
      helpers.isTrue (lib.hasInfix "hyprland-wallpaperd" controlLua);
    "wallpaper supervisor suppressed while the rest of the startup block remains" =
      helpers.isTrue (lib.hasInfix "pkill ibus-daemon" execLua && !(lib.hasInfix "hyprland-wallpaperd" execLua));
    "Super+Shift+A bind dispatches to caelestiaQS" =
      helpers.isTrue (lib.hasInfix "caelestiaQS" (H.hyprBind hm "SUPER+SHIFT + A"));
    "Super+Delete bind dispatches to caelestiaLogout lock" =
      helpers.isTrue (lib.hasInfix "caelestiaLogout lock" (H.hyprBind hm "SUPER + Delete"));
  };
}
