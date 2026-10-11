# P02 — Hyprland + noctalia active
# Expected: noctalia binds, swaync + wallpaper supervisor suppressed.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./02-hyprland-noctalia;
  hm = H.getHm config;
  control = H.getHm (H.getConfig ./03-hyprland-no-shell);
  execLua = H.hyprExecLua hm;
  controlLua = H.hyprExecLua control;
in
nix-tests.runTests {
  "P02: hyprland + noctalia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync suppressed — noctalia active on hyprland" =
      helpers.isFalse hm.services.swaync.enable;
    "control (no shell) still starts the wallpaper supervisor" =
      helpers.isTrue (lib.hasInfix "hyprland-wallpaperd" controlLua);
    "wallpaper supervisor suppressed while the rest of the startup block remains" =
      helpers.isTrue (lib.hasInfix "pkill ibus-daemon" execLua && !(lib.hasInfix "hyprland-wallpaperd" execLua));
    "Super+Shift+A bind dispatches to noctalia launcher IPC" =
      helpers.isTrue (lib.hasInfix "noctalia-shell ipc call toggleAppLauncher" (H.hyprBind hm "SUPER+SHIFT + A"));
    "Super+Delete bind dispatches to noctalia lock IPC" =
      helpers.isTrue (lib.hasInfix "noctalia-shell ipc call lockScreen lock" (H.hyprBind hm "SUPER + Delete"));
  };
}
