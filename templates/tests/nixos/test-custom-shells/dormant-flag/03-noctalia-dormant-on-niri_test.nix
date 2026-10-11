# D03 — Noctalia on Niri dormant (enable=false, enableOnX=true)
# Expected: config identical to the matching no-shell positive scenario.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./03-noctalia-dormant-on-niri;
  hm = H.getHm config;
  control = H.getHm (H.getConfig ../positive/05-niri-no-shell);
  snap = h: {
    swaync = h.services.swaync.enable;
    binds = builtins.mapAttrs (_: v: v.action) h.programs.niri.settings.binds;
  };
in
nix-tests.runTests {
  "D03: noctalia dormant on niri — must behave as no-shell" = helpers: {
    "no failing assertions — dormant shell must not trigger cross-shell assert" =
      helpers.isTrue (H.allAssertionsPass config);
    "swaync enabled — dormant flag must not suppress it" =
      helpers.isTrue (snap hm).swaync;
    "binds and startup identical to the no-shell scenario" =
      helpers.isEq (snap hm) (snap control);
    "Mod+Shift+A is the no-op, not the shell IPC" =
      helpers.isEq (snap hm).binds."Mod+Shift+A".spawn [ "true" ];
    "Mod+Delete is loginctl lock-session" =
      helpers.isEq (snap hm).binds."Mod+Delete".spawn [ "loginctl" "lock-session" ];
  };
}
