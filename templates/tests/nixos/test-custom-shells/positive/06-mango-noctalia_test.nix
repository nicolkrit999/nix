# P06 — Mango + noctalia active
# Expected: noctalia IPC dispatchers in mango binds, swaync suppressed.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./06-mango-noctalia;
  hm = H.getHm config;
  launcher = H.mangoBinds hm "SUPER+SHIFT,A,spawn,";
  lock = H.mangoBinds hm "SUPER,Delete,spawn,";
in
nix-tests.runTests {
  "P06: mango + noctalia active" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync suppressed — noctalia active on mango" =
      helpers.isFalse hm.services.swaync.enable;
    "SUPER+SHIFT,A is bound exactly once, to the noctalia launcher IPC" =
      helpers.isTrue (builtins.length launcher == 1 && lib.hasInfix "noctalia-shell ipc call launcher toggle" (builtins.head launcher));
    "SUPER,Delete is bound exactly once, to the noctalia lock IPC" =
      helpers.isTrue (builtins.length lock == 1 && lib.hasInfix "noctalia-shell ipc call lockScreen lock" (builtins.head lock));
  };
}
