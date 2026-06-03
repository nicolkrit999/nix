# P02 — Hyprland + noctalia active
# Noctalia is the active shell on Hyprland (rarer combo; Hyprland is the one
# WM that supports both shells). Expected: noctalia dispatchers, swaync +
# awww wallpaper suppressed.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./02-hyprland-noctalia;
  hm = H.getHm config;
  binds = hm.wayland.windowManager.hyprland.settings.bind;
  execLua = (builtins.elemAt hm.wayland.windowManager.hyprland.settings.on._args 1).expr;
in
nix-tests.runTests {
  "P02: hyprland + noctalia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed — coexists with noctalia (binds dispatch to noctalia IPC)" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync suppressed — noctalia active on hyprland" =
      helpers.isFalse hm.services.swaync.enable;
    "awww wallpaper suppressed — noctalia active on hyprland" =
      helpers.isFalse (lib.hasInfix "awww-daemon" execLua);
    "Super+Shift+A dispatches to noctalia launcher IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "noctalia-shell ipc call toggleAppLauncher" (H.bindStr b)) binds);
    "Super+Delete dispatches to noctalia lock IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "noctalia-shell ipc call lockScreen lock" (H.bindStr b)) binds);
  };
}
