# P06 — Mango + noctalia active
# Expected: noctalia IPC dispatchers in mango binds, swaync suppressed.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./06-mango-noctalia;
  hm = H.getHm config;
  mangoBinds = hm.wayland.windowManager.mango.settings.bind;
in
nix-tests.runTests {
  "P06: mango + noctalia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "hyprlock installed — coexists with noctalia (binds dispatch to noctalia IPC)" =
      helpers.isTrue hm.programs.hyprlock.enable;
    "swaync suppressed — noctalia active on mango" =
      helpers.isFalse hm.services.swaync.enable;
    "SUPER+SHIFT,A spawns noctalia launcher IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "noctalia-shell ipc call launcher toggle" b) mangoBinds);
    "SUPER,Delete spawns noctalia lock IPC" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "noctalia-shell ipc call lockScreen lock" b) mangoBinds);
  };
}
