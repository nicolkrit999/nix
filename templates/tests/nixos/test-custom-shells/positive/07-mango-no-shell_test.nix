# P07 — Mango, no shell
# Expected: swaync present, SUPER+SHIFT,A no-op, SUPER,Delete loginctl.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./07-mango-no-shell;
  hm = H.getHm config;
in
nix-tests.runTests {
  "P07: mango, no active shell" = helpers: {
    "no failing assertions" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync enabled — no shell to suppress it" =
      helpers.isTrue hm.services.swaync.enable;
    "SUPER+SHIFT,A is bound exactly once, to the no-op" =
      helpers.isEq (H.mangoBinds hm "SUPER+SHIFT,A,spawn,") [ "SUPER+SHIFT,A,spawn,true" ];
    "SUPER,Delete is bound exactly once, to loginctl lock-session" =
      helpers.isEq (H.mangoBinds hm "SUPER,Delete,spawn,") [ "SUPER,Delete,spawn,loginctl lock-session" ];
  };
}
