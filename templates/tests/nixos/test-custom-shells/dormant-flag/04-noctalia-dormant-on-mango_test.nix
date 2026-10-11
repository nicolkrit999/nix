# D04 — Noctalia on Mango dormant (enable=false, enableOnX=true)
# Expected: config identical to the matching no-shell positive scenario.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./04-noctalia-dormant-on-mango;
  hm = H.getHm config;
  control = H.getHm (H.getConfig ../positive/07-mango-no-shell);
  snap = h: {
    swaync = h.services.swaync.enable;
    binds = h.wayland.windowManager.mango.settings.bind;
  };
in
nix-tests.runTests {
  "D04: noctalia dormant on mango — must behave as no-shell" = helpers: {
    "no failing assertions — dormant shell must not trigger cross-shell assert" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync enabled — dormant flag must not suppress it" =
      helpers.isTrue (snap hm).swaync;
    "binds and startup identical to the no-shell scenario" =
      helpers.isEq (snap hm) (snap control);
    "SUPER+SHIFT,A is the no-op, not the shell IPC" =
      helpers.isEq (H.mangoBinds hm "SUPER+SHIFT,A,spawn,") [ "SUPER+SHIFT,A,spawn,true" ];
    "SUPER,Delete is loginctl lock-session" =
      helpers.isEq (H.mangoBinds hm "SUPER,Delete,spawn,") [ "SUPER,Delete,spawn,loginctl lock-session" ];
  };
}
